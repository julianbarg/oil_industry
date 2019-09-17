---
jupyter:
  jupytext:
    formats: ipynb,md
    text_representation:
      extension: .md
      format_name: markdown
      format_version: '1.1'
      jupytext_version: 1.2.3
  kernelspec:
    display_name: oil_industry
    language: python
    name: oil_industry
---

# 7. (Functions to) identify all data issue

```python
pipeline_2010_selected_file = '../preprocessed_data/pipelines_2010_selected_2019-08-22.feather'
incidents_selected_file = '../preprocessed_data/incidents_selected_2019-08-22.feather'
largest_observations_file = '../preprocessed_data/largest_companies_2019-09-01.feather'
sample_file = '../preprocessed_data/sample_2019-09-02.feather'

pipelines_2010_raw_file = '../data/pipelines_2010_2019-08-11.feather'
incidents_raw = '../data/incidents_2019-08-11.feather'
regular_impressions_file = '../input/company_names_res_2019-09-01.csv'
```

```python
sample_len = 150
```

## Setup

```python
import pandas as pd
import numpy as np
from datetime import date
from functools import partial

today = date.today().isoformat()
```

```python
import wrds

db = wrds.Connection(wrds_username='juujian')
```

# Load data

```python
pipelines_2010 = pd.read_feather(pipeline_2010_selected_file)
pipelines_2010.sample(2)
```

```python
incidents = pd.read_feather(incidents_selected_file)
incidents.sample(2)
```

```python
sample = pd.read_feather(sample_file)
sample.sample(2)
```

```python
largest_observations_ordered = pd.read_feather(largest_observations_file)
largest_observations_ordered.head(5)
```

```python
pipelines_2010_raw = pd.read_feather(pipelines_2010_raw_file)
```

## 7.1 Define functions for analysis


### 7.1.1 Functions to compare with raw data

```python
def find_info(OPERATOR_ID, info_col: str, title: str, df = pipelines_2010_raw, id_col = 'OPERATOR_ID', 
              year_col = 'REPORT_YEAR', fuzzy=False):
    from fuzzywuzzy import fuzz
    
    values = np.unique(df[df[id_col] == int(OPERATOR_ID)][info_col]).tolist()
    result = []
    for value in values:
        start_year = df[df[info_col] == value][year_col].min()
        end_year = df[df[info_col] == value][year_col].max()
        result = result + [{title: value, 'start_year': start_year, 'end_year': end_year}]
        
    if fuzzy and len(result) == 2 and fuzz.ratio(result[0][title].lower(), result[1][title].lower()) >= 95:
            result = [result[0]]
            
    return(result)

find_address = partial(find_info, info_col='PARTA4STREET', title='address')
find_names = partial(find_info, info_col='PARTA2NAMEOFCOMP', title='name', fuzzy=True)
find_names('4906')
```

```python
import operator

def find_latest_info(OPERATOR_ID, info_col: str, df = pipelines_2010_raw, 
                     id_col = 'OPERATOR_ID', year_col = 'REPORT_YEAR'):
    data_points = find_info(OPERATOR_ID=OPERATOR_ID, info_col=info_col, title='value', 
                            id_col=id_col, year_col=year_col, fuzzy=False)
    latest_info = max(data_points.__iter__(), key=operator.itemgetter('end_year'))['value']
    return latest_info

find_latest_name = partial(find_latest_info, info_col='PARTA2NAMEOFCOMP')
find_latest_name('12470')
```

### 7.1.2 Compare parents

```python
def extract_value(OPERATOR_ID, col, df = sample, id_col = 'OPERATOR_ID'):
    candidates = df.loc[df[id_col] == OPERATOR_ID][col].unique()
    if len(candidates) == 1:
        return(candidates[0])
    elif len(candidates) == 0:
        raise LookupError (f'OPERATOR_ID or {col} not found.')
    elif len(candidates) > 1:
        raise LookupError (f'More than one value found for {col}.')
        
extract_parent = partial(extract_value, col='PARENT')
extract_parent('300')
```

```python
def compare_values(OPERATOR_ID, col, df = sample, id_col = 'OPERATOR_ID'):
    value = extract_value(OPERATOR_ID, col=col, df=df, id_col=id_col)
    rows = df.loc[df[col] == value]
    ids_with_same_values = rows[id_col].unique().tolist()
    ids_with_same_values.remove(OPERATOR_ID)
    name_with_same_values = [find_latest_name(id_) for id_ in ids_with_same_values]
    return(list(zip(ids_with_same_values, name_with_same_values)))
    
compare_parents = partial(compare_values, col='PARENT')
compare_parents('22830')
```

## 7.2 Create regular expressions

```python
ids = sample['OPERATOR_ID'].unique()
```

```python
entry = []
for id_ in ids:
    entry = entry + [[id_, entry['name']] for entry in find_names(id_)]

pd.DataFrame(entry, columns = ['OPERATOR_ID', 'NAME']).to_csv(f'../input/company_names_{today}.csv', index=False)
```

For this step, we modify the exported company names file before importing the resulting .csv back into python.

```python
company_res = pd.read_csv(regular_impressions_file)
company_res.sample(5)
```

```python
company_res.dtypes
```

```python
company_res['OPERATOR_ID'] = company_res['OPERATOR_ID'].astype('str')
company_res.dtypes
```

```python
def extract_values(OPERATOR_ID, col, df = company_res, id_col = 'OPERATOR_ID'):
    return df.loc[df[id_col] == str(OPERATOR_ID)][col].unique().tolist()

extract_res = partial(extract_values, col='RES')
extract_res('31684')
```

```python
company_res.to_feather(f'../preprocessed_data/company_res_{today}.feather')
```

### 7.2.1 Check regular expression validity

```python
for _, expression in company_res['RES'].items():
    matches = sample[sample['NAME'].str.match(pat=expression, case=False)]
    if len(matches) == 0:
        print(f'Regular expression {expression} does not match anything!')
```

### 7.2.2 Function to find namesakes

```python
def find_namesakes(re_, df = sample, col = 'NAME', id_col = 'OPERATOR_ID'):
    if isinstance(re_, str):
        re_ = [re_]
    
    if len(re_) == 1:
        results = df.loc[df[col].str.match(re_[0], case=False)][['OPERATOR_ID', 'NAME']].drop_duplicates()
        return results
        
    if len(re_) > 1:
        results = pd.DataFrame()
        for expression in re_:
            results = results.append(find_namesakes(expression))
        return(results)
    
find_namesakes(r'.*exxonmobil.*')
```

## 7.3 Create main loop

```python
from IPython.core.debugger import set_trace

def analyze_sample():    
    parents_handled = []
    namesakes_handled = []
    messages = []
    
    for _, id_ in largest_observations_ordered['OPERATOR_ID'][:sample_len].iteritems():
        current_name = find_latest_name(id_)
        message = ''

        names = find_names(id_)
        if len(names) > 1:
            message += f"\n{current_name} (OPERATOR_ID {id_}) has changed its name:\n"
            for name in names:
                message += f"\n\tWas named {name['name']} from {name['start_year']} to {name['end_year']}.\n"
        
        same_parent = compare_parents(id_)
        same_parent_names = [sibling[1] for sibling in same_parent]
        same_parent_ids = [sibling[0] for sibling in same_parent]      

        if (id_) not in parents_handled:
            if same_parent:
                message += f"\n{current_name} (OPERATOR_ID {id_}) has the same parent company as:\n"
                for sibling in same_parent:
                    message += f"\n\t{sibling[1]} (OPERATOR_ID {sibling[0]})\n"
                parents_handled = parents_handled + [sibling[0] for sibling in same_parent]
        
        re_ = extract_res(id_)
        namesakes = find_namesakes(re_)
        namesakes = namesakes.loc[~namesakes['NAME'].isin(same_parent_names)]
        namesakes = namesakes.loc[~namesakes['OPERATOR_ID'].isin(same_parent_names)]
        namesakes = namesakes[~(namesakes['OPERATOR_ID'] == id_)]
        if len(namesakes) > 0 and set(namesakes['OPERATOR_ID']) not in namesakes_handled:
            namesakes_handled = namesakes_handled + [set(namesakes['OPERATOR_ID'])]
            
            message += f"\n{current_name} (OPERATOR_ID {id_}) may have a namesake or namesakes:\n"
            for _, row in namesakes.iterrows():
                message += f"\n\t{row['NAME']} (OPERATOR_ID {row['OPERATOR_ID']})\n"

        if message:
            messages.append(message)
            
    return messages
```

```python
import pickle

issues_to_address = analyze_sample()
with open(f'../preprocessed_data/issues_to_address_{today}.pickle', 'wb') as file:
    pickle.dump(issues_to_address, file)
```
