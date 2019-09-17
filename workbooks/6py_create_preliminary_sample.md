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

# 6. Create preliminary sample


We grab the 50 operators with the largest network of pipelines (in any year) and obtain the most recent company name.


Most recent file versions used in this workbook:

```python
pre_sample_file = "../preprocessed_data/pre_sample_2019-09-08.feather"
incidents_selected_file = '../preprocessed_data/incidents_selected_2019-08-22.feather'
largest_observations_file = '../preprocessed_data/largest_companies_2019-09-08.feather'

pipelines_2010_raw = '../data/pipelines_2010_2019-08-11.feather'
pipelines_2004_raw = '../data/pipelines_2004_2019-08-11.feather'
incidents_raw = '../data/incidents_2019-08-11.feather'

parent_companies_file = '../input/largest_companies_w_parents_2019-09-09.csv'

names_table = '../preprocessed_data/names_table_2019-09-09.feather'
```

```python
sample_len = 200
```

## Setup

```python
import pandas as pd
import numpy as np
from datetime import date

today = date.today().isoformat()
```

```python
# pd.options.display.max_rows = 200
```

# Load data

```python
pipelines = pd.read_feather(pre_sample_file)
pipelines.sample(3)
```

```python
incidents = pd.read_feather(incidents_selected_file)
incidents.sample(3)
```

```python
parents = pd.read_csv(parent_companies_file)
parents[:150].sample(3)
```

```python
print(parents.dtypes)
parents['OPERATOR_ID'] = parents['OPERATOR_ID'].astype(str)
print(parents.dtypes)
```

## 6.1 Reference table for company names

```python
names_1 = pd.read_feather(pipelines_2010_raw)[['OPERATOR_ID', 'REPORT_YEAR', 'PARTA2NAMEOFCOMP', 'PARTA4STREET']]
names_2 = pd.read_feather(pipelines_2004_raw)[['OPERATOR_ID', 'YR', 'NAME', 'OFSTREET']]

names_1 = names_1.rename(columns={'REPORT_YEAR': 'YEAR', 'PARTA2NAMEOFCOMP': 'NAME', 'PARTA4STREET': 'STREET'})
names_2 = names_2.rename(columns={'YR': 'YEAR', 'OFSTREET': 'STREET'})

names = pd.concat([names_1, names_2]).reset_index(drop=True)
names.to_feather(f'../preprocessed_data/names_table_{today}.feather')
```

```python
from functools import partial

def find_info(OPERATOR_ID, info_col:str, file = names_table, id_col = 'OPERATOR_ID', year_col = 'YEAR'):
    df = pd.read_feather(file)
    values = np.unique(df[df[id_col] == int(OPERATOR_ID)][info_col]).tolist()
    result = {}
    for value in values:
        start_year = df[df[info_col] == value][year_col].min()
        end_year = df[df[info_col] == value][year_col].max()
        result[value] = {'start_year': start_year, 'end_year': end_year}
    return(result)

find_address = partial(find_info, info_col = 'STREET')
find_address('300')
```

```python
find_names = partial(find_info, info_col = 'NAME')
find_names('300')
```

## 6.2 Largest operators - add parents


We use the list of the largest operators that we have generated in workbook 5.


All parent companies are retrieved from LexisNexis. Where the search yielded unclear results, we consult the address column in the original .xls file by FERC. In some rare cases, we did additional research (mostly company documents) to resolve conflicts.

```python
largest_pipeline_operators = pd.read_feather(largest_observations_file)
sample = largest_pipeline_operators[:sample_len]

sample.head()
```

```python
parents.head()
```

```python
assert len(parents.loc[parents['OPERATOR_ID'].isin(sample[:sample_len]['OPERATOR_ID'])]) == sample_len
assert parents.loc[parents['OPERATOR_ID'].isin(sample[:sample_len]['OPERATOR_ID'])]['PARENT'].isna().sum() == 0
```

## 6.3 Finalize sample

```python
sample = pipelines.loc[pipelines['OPERATOR_ID'].isin(sample['OPERATOR_ID'])].copy()
assert len(sample['OPERATOR_ID'].unique()) == sample_len
sample.head(3)
```

### Drop offshore incidents

```python
incidents = incidents.loc[incidents['ONSHORE'] == True].reset_index(drop = True)
incidents = incidents.drop(columns = ['ONSHORE'])
```

### 6.3.1 Merge in parents


Ensure all parents are there.

```python
sample = sample.merge(parents[['OPERATOR_ID', 'PARENT']], on='OPERATOR_ID')
assert len(sample['OPERATOR_ID'].unique()) == sample_len
sample.sample(3)
```

### 6.3.2 Merge in incidents (by type) 


#### See if there are any conflicts between observations in the same year

```python
assert len(sample[['OPERATOR_ID', 'YEAR', 'COMMODITY', 'NAME']].drop_duplicates()) == len(sample[['OPERATOR_ID', 'COMMODITY', 'YEAR']].drop_duplicates())
```

### 6.3.3 Clean commodity names - incidents

```python
incidents['COMMODITY'].unique()
```

```python
new_names_incidents = {'REFINED AND/OR PETROLEUM PRODUCT (NON-HVL) WHICH IS A LIQUID AT AMBIENT CONDITIONS': 'non-hvl', 
                       'CO2 (CARBON DIOXIDE)': 'co2', 
                       'HVL OR OTHER FLAMMABLE OR TOXIC FLUID WHICH IS A GAS AT AMBIENT CONDITIONS': 'hvl', 
                       'CRUDE OIL': 'crude', 
                       'BIOFUEL / ALTERNATIVE FUEL(INCLUDING ETHANOL BLENDS)': 'hvl'}

incidents = incidents.replace({'COMMODITY': new_names_incidents})
incidents.sample(3)
```

The index column has a funny name, but that name gets dropped when writing the sample to .feather.


### Merge and safe

```python
incidents['YEAR'] = incidents['LOCAL_DATETIME'].dt.year
```

All incidents

```python
incident_counts = incidents.groupby(['OPERATOR_ID', 'YEAR', 'COMMODITY']).size().reset_index(name='INCIDENTS')
incident_counts.sample(3)

assert len(incident_counts.loc[incident_counts.duplicated(subset=['OPERATOR_ID', 'YEAR', 'COMMODITY'])]) == 0
assert len(sample.loc[sample.duplicated(subset=['OPERATOR_ID', 'YEAR', 'COMMODITY'])]) == 0
```

```python
print(len(sample))
sample = sample.merge(incident_counts, on=['OPERATOR_ID', 'YEAR', 'COMMODITY'], how='left')
sample['INCIDENTS'] = sample['INCIDENTS'].fillna(value=0)
assert len(sample.loc[sample.duplicated(subset=['OPERATOR_ID', 'YEAR', 'COMMODITY'])]) == 0
print(len(sample))
```

All significant incidents

```python
significant_incident_counts = incidents[incidents['SIGNIFICANT'] == True].groupby(
    ['OPERATOR_ID', 'YEAR', 'COMMODITY']).size().reset_index(name='SIGNIFICANT_INCIDENTS')
significant_incident_counts.sample(3)
```

```python
print(len(sample))
sample = sample.merge(significant_incident_counts, on=['OPERATOR_ID', 'YEAR', 'COMMODITY'], how='left')
sample['SIGNIFICANT_INCIDENTS'] = sample['SIGNIFICANT_INCIDENTS'].fillna(value=0)
print(len(sample))
```

```python
sample.to_feather(f'../preprocessed_data/sample_{today}.feather')
incidents.to_feather(f'../preprocessed_data/incidents_renamed_{today}.feather')
```

```python

```
