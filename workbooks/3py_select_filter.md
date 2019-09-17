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

# 3 - Select columns, filter onshore

```python
import pandas as pd
import numpy as np
from datetime import date

today = date.today().isoformat()
```

```python
import rpy2.rinterface
```

```python
%load_ext rpy2.ipython
```

```R
suppressMessages(library(tidyverse))
```

## 3.1 Extract relevant columns of the pipeline incidents dataset

```python
incidents = pd.read_excel('../data/incidents_2019-08-01/hl2010toPresent.xlsx', 
                          sheet_name=1)
incidents_selected = incidents[['OPERATOR_ID', 'LOCAL_DATETIME', 'NAME', 'COMMODITY_RELEASED_TYPE', 
                                'SERIOUS', 'SIGNIFICANT', 'LOCATION_LATITUDE', 'LOCATION_LONGITUDE', 
                                'ON_OFF_SHORE']].copy()

incidents_selected.sample(5)
```

```python
import numpy as np

np.unique(incidents_selected['COMMODITY_RELEASED_TYPE'])
```

```python
incidents_selected['ON_OFF_SHORE'].value_counts()
```

### 3.1.1 Fix data types

```python
incidents_selected.dtypes
```

```python
incidents_selected['OPERATOR_ID'] = incidents_selected['OPERATOR_ID'].astype(str)
incidents_selected.dtypes
```

Make sure SERIOUS and SIGNIFICANT are booleans.

```python
(incidents_selected[['SERIOUS']] == 'YES')['SERIOUS'].value_counts()
```

```python
incidents_selected['SERIOUS'] = incidents_selected[['SERIOUS']] == 'YES'
```

```python
(incidents_selected[['SIGNIFICANT']] == 'YES')['SIGNIFICANT'].value_counts()
```

```python
incidents_selected['SIGNIFICANT'] = incidents_selected[['SIGNIFICANT']] == 'YES'
```

```python
incidents_selected.dtypes
```

### 3.1.2 Recode on/offshore to boolean, fix column names

```python
incidents_selected['ONSHORE'] = incidents_selected[['ON_OFF_SHORE']] == 'ONSHORE'
incidents_selected = incidents_selected.drop(columns=['ON_OFF_SHORE'])
incidents_selected = incidents_selected.rename(columns={'COMMODITY_RELEASED_TYPE': 'COMMODITY'})

incidents_selected.sample(5)
```

```python
incidents_selected.to_feather(f'../preprocessed_data/incidents_selected_{today}.feather')
```

## 3.2 Extract relevant columns of the pipeline system dataset (2010-)


### 3.2.1 Select relevant columns

```python
from os import listdir

pipelines_2010_present = [file for file in listdir('../data/pipelines_2010_present_2019-08-02/') if 'annual_hazardous_liquid' in file]
pipelines_2010_present = pd.concat([pd.read_excel(f'../data/pipelines_2010_present_2019-08-02/{file}', skiprows=2) 
                                    for file in pipelines_2010_present])
pipelines_2010_present = pipelines_2010_present.reset_index(drop = True)

pipelines_2010_present.sample(5)
```

```python
pipelines_2010_selected = pipelines_2010_present[[
    'OPERATOR_ID', 'REPORT_YEAR', 'PARTA2NAMEOFCOMP', 'PARTA5COMMODITY', 'PARTBHCAONSHORE', 
    'PARTEUNKNTOTAL', 'PARTEPRE40TOTAL', 'PARTE1940TOTAL', 'PARTE1950TOTAL', 'PARTE1960TOTAL', 
    'PARTE1970TOTAL', 'PARTE1980TOTAL', 'PARTE1990TOTAL', 'PARTE2000TOTAL', 'PARTE2010TOTAL',
    'PARTBHCAOFFSHORE', 'PARTBHCATOTAL']].copy()

pipelines_2010_selected.sample(5)
```

```python
pipelines_2010_selected.dtypes
```

```python
pipelines_2010_selected['OPERATOR_ID'] = pipelines_2010_selected['OPERATOR_ID'].astype(str)
pipelines_2010_selected['OPERATOR_ID'].dtype
```

```python
pipelines_2010_selected = pipelines_2010_selected.rename(
    columns={'REPORT_YEAR': 'YEAR', 'PARTA2NAMEOFCOMP': 'NAME', 'PARTA5COMMODITY': 'COMMODITY', 'PARTBHCAONSHORE': "MILES", 
             'PARTBHCAOFFSHORE': 'OFFSHORE_MILES', 'PARTBHCATOTAL': 'TOTAL_MILES', 'PARTEUNKNTOTAL': 'AGE_UNKNOWN_MILES', 
             'PARTEPRE40TOTAL': 'MILES_PRE_1940', 'PARTE1940TOTAL': 'MILES_1940', 'PARTE1950TOTAL': 'MILES_1950', 
             'PARTE1960TOTAL': 'MILES_1960', 'PARTE1970TOTAL': 'MILES_1970', 'PARTE1980TOTAL': 'MILES_1980', 
             'PARTE1990TOTAL': 'MILES_1990', 'PARTE2000TOTAL': 'MILES_2000', 'PARTE2010TOTAL': 'MILES_2010'})
pipelines_2010_selected.sample(5)
```

## 3.3 Extract relevant columns of the pipeline system dataset (2004)

```python
pipelines_2004_2009 = [file for file in listdir('../data/pipelines_2004_2009_2019-08-02/') if 'annual_hazardous_liquid' in file]
pipelines_2004_2009 = pd.concat([pd.read_excel(f'../data/pipelines_2004_2009_2019-08-02/{file}') 
                                 for file in pipelines_2004_2009])
pipelines_2004_2009 = pipelines_2004_2009.reset_index(drop = True)

pipelines_2004_2009.sample(5)
```

### 3.3.1 Clean name column

```python
pipelines_2004_2009['NAME_FIXED'] = np.where(pd.isnull(pipelines_2004_2009['PARENT']), 
                                             pipelines_2004_2009['NAME'], 
                                             pipelines_2004_2009['PARENT'])
pd.isnull(pipelines_2004_2009['NAME_FIXED']).value_counts()
```

```python
pipelines_2004_2009[['NAME_FIXED', 'NAME', 'PARENT']].sample(5)
```

### 3.3.2 Select columns

```python
pipelines_2004_selected = pipelines_2004_2009[['OPERATOR_ID', 'YR', 'NAME_FIXED', 'SYSTEM_TYPE', 'HCAONM', 'ERWTM_1',
                                               'ERWTM_2', 'ERWTM_3', 'ERWTM_4', 'ERWTM_5', 'ERWTM_6', 'ERWTM_7',
                                               'ERWTM_8', 'HCAOFFM', 'HCAMT']].copy()
pipelines_2004_selected.dtypes
```

```python
pipelines_2004_selected['OPERATOR_ID'] = pipelines_2004_selected['OPERATOR_ID'].astype(str)
pipelines_2004_selected.dtypes
```

```python
pipelines_2004_selected = pipelines_2004_selected.rename(
    columns={'YR': 'YEAR', 'NAME_FIXED': 'NAME', 'HCAONM': 'MILES', 'HCAOFFM': 'OFFSHORE_MILES', 
             'HCAMT': 'TOTAL_MILES', 'SYSTEM_TYPE': 'COMMODITY', 
             'ERWTM_1': 'MILES_PRE_1940', 
             'ERWTM_2': 'MILES_1940',
             'ERWTM_3': 'MILES_1950',
             'ERWTM_4': 'MILES_1960',
             'ERWTM_5': 'MILES_1970',
             'ERWTM_6': 'MILES_1980',
             'ERWTM_7': 'MILES_1990',
             'ERWTM_8': 'MILES_2000'})
pipelines_2004_selected['MILES_2010'] = 0.0
pipelines_2004_selected.sample(5)
```

### 3.3.3 Handle "duplicate" observations


How are the instances of diverging names treated by Pandas?

```R magic_args="-i pipelines_2004_selected"
glimpse(pipelines_2004_selected)
```

```R magic_args="-i pipelines_2004_selected"

pipelines_2004_selected <- pipelines_2004_selected %>%
    group_by(OPERATOR_ID, YEAR, COMMODITY) %>%
# We lose some information by how we create the name column, but since we mostly use the OPERATOR_ID, it's alright.
    summarize(NAME = first(NAME), 
              MILES = sum(MILES), 
              MILES_PRE_1940 = sum(MILES_PRE_1940), 
              MILES_1940 = sum(MILES_1940), 
              MILES_1950 = sum(MILES_1950), 
              MILES_1960 = sum(MILES_1960), 
              MILES_1970 = sum(MILES_1970), 
              MILES_1980 = sum(MILES_1980), 
              MILES_1990 = sum(MILES_1990), 
              MILES_2000 = sum(MILES_2000), 
              MILES_2010 = 0,
              OFFSHORE_MILES = sum(OFFSHORE_MILES), 
              TOTAL_MILES = sum(TOTAL_MILES), 
              AGE_UNKNOWN_MILES = 0)
pipelines_2004_selected <- as.data.frame(pipelines_2004_selected)
    
glimpse(pipelines_2004_selected)
```

```python
pipelines_2004_selected = %Rget pipelines_2004_selected
pipelines_2004_selected.sample(5)
```

## 3.4 Merge 2010- and 2004- data


### 3.4.1 Unify commodity names

```python
new_names_2010 = {'Crude Oil': 'crude', 
                  'CO2': 'co2',
                  'Fuel Grade Ethanol (dedicated system)': 'fge', 
                  'HVL': 'hvl',
                  'Refined and/or Petroleum Product (non-HVL)': 'non-hvl'}

pipelines_2010_selected = pipelines_2010_selected.replace({'COMMODITY': new_names_2010})
pipelines_2010_selected.sample(3)
```

```python
new_names_2004 = {'CRUDE OIL': 'crude', 
                  'HVLS': 'hvl', 
                  'PETROLEUM & REFINED PRODUCTS': 'non-hvl'}

pipelines_2004_selected = pipelines_2010_selected.replace({'COMMODITY': new_names_2004})
pipelines_2004_selected.sample(3)
```

### 3.4.2 Merge

```python
pipelines_2004_selected['YEAR'] = pipelines_2004_selected['YEAR'].astype('int64')
pipelines_2004_selected.dtypes
```

```python
pipelines_2010_selected.dtypes
```

Making some adjustments to make the merging seamless.

```python
pipelines_2004_selected = pipelines_2004_selected[['OPERATOR_ID', 'YEAR', 'NAME', 'COMMODITY', 'MILES', 
                                                   'AGE_UNKNOWN_MILES', 'MILES_PRE_1940', 'MILES_1940', 
                                                   'MILES_1950', 'MILES_1960', 'MILES_1970', 'MILES_1980', 
                                                   'MILES_1990', 'MILES_2000', 'MILES_2010', 'OFFSHORE_MILES', 
                                                   'TOTAL_MILES']]
```

```python
pre_sample = pd.concat([pipelines_2010_selected, pipelines_2004_selected])
pre_sample.sample(5)
```

```R magic_args="-i pre_sample"
nrow(pre_sample %>%
    filter(OPERATOR_ID == '31618') %>%
    filter(YEAR == '2017') %>%
    filter(COMMODITY == 'hvl'))
```

## 3.5 Calculate percentage offshore and average age

```python
def calc_avg_age(df):
    avg_age = ((df['MILES_PRE_1940'] * 90 + 
                df['MILES_1940'] * 75 + 
                df['MILES_1950'] * 65 + 
                df['MILES_1960'] * 55 + 
                df['MILES_1970'] * 45 + 
                df['MILES_1980'] * 35 + 
                df['MILES_1990'] * 25 + 
                df['MILES_2000'] * 15 + 
                df['MILES_2010'] * 5) /
               (df['MILES_PRE_1940'] + df['MILES_1940'] + df['MILES_1950'] + df['MILES_1960'] + 
                df['MILES_1970'] + df['MILES_1980'] + df['MILES_1990'] + df['MILES_2000'] + df['MILES_2010']))
    return avg_age
```

```python
pre_sample['AVG_AGE'] = calc_avg_age(pre_sample)
pre_sample['PERC_OFFSHORE'] = pre_sample['OFFSHORE_MILES'].fillna(0.0) / (pre_sample['TOTAL_MILES'].fillna(0.0) + 0.1)


pre_sample.sample(3)
```

## 3.6 Filter commodities and remove offshore operators


### 3.6.1 Commodities

```python
pre_sample = pre_sample[pre_sample['COMMODITY'].isin(['crude', 'hvl', 'non-hvl'])]
pre_sample.sample(3)
```

### 3.6.2 Offshore operators


### Double check that we are filtering the correct observations.

```python
# For the operators, we remove only those segments (commodities) that have a share of offshore. 
pre_sample['OFFSHORE_MAX'] = (pre_sample['PERC_OFFSHORE'].
                              groupby([pre_sample['OPERATOR_ID'], 
                              pre_sample['COMMODITY']]).transform('max'))
pre_sample.sample(3)
```

```R magic_args="-i pre_sample"
pre_sample %>%
    group_by(OPERATOR_ID, COMMODITY) %>%
    summarize(max_offshore = max(PERC_OFFSHORE)) %>%
    mutate(max_offshore = sprintf('%0.2f', max_offshore)) %>%
    {table(.$max_offshore)}
```

```R magic_args="-i pre_sample "
pre_sample %>%
    group_by(OPERATOR_ID, COMMODITY) %>%
    summarize(max_offshore = first(OFFSHORE_MAX)) %>%
    mutate(max_offshore = sprintf('%0.2f', max_offshore)) %>%
    {table(.$max_offshore)}
```

The results are the same, so we defined this variable correctly. Seems like we don't loose too many operators when we drop all that have any share in offshore.

```R magic_args="-i pre_sample"
pre_sample %>%
    group_by(OPERATOR_ID, COMMODITY) %>%
    summarize(max_offshore = max(PERC_OFFSHORE)) %>%
    filter(max_offshore < 0.1) %>%
    mutate(max_offshore = sprintf('%0.2f', max_offshore)) %>%
    {table(.$max_offshore)}
```

### Filter

```python
len(pre_sample)
```

```python
pre_sample = pre_sample.loc[pre_sample['OFFSHORE_MAX'] == 0.0].reset_index(drop=True)
pre_sample = pre_sample.drop(columns=['OFFSHORE_MILES', 'TOTAL_MILES', 'OFFSHORE_MAX'])
pre_sample.sample(3)
```

```python
len(pre_sample)
```

## 3.7 Save results

```python
pre_sample.to_feather(f'../preprocessed_data/pre_sample_{today}.feather')
```

## 3.7.1 Write original data to .feather for reference


Some columns get erroneously read to data type 'O'. We convert those manually to str type.

```python
pipelines_2010_present.loc[:, pipelines_2010_present.dtypes == 'O'] = pipelines_2010_present.loc[
    :, pipelines_2010_present.dtypes == 'O'].astype(str)

pipelines_2004_2009.loc[:, pipelines_2004_2009.dtypes == 'O'] = pipelines_2004_2009.loc[
    :, pipelines_2004_2009.dtypes == 'O'].astype(str)

incidents.loc[:, incidents.dtypes == 'O'] = incidents.loc[
    :, incidents.dtypes == 'O'].astype(str)
```

```python
pipelines_2010_present.to_feather(f'../data/pipelines_2010_{today}.feather')
pipelines_2004_2009.to_feather(f'../data/pipelines_2004_{today}.feather')
incidents.to_feather(f'../data/incidents_{today}.feather')
```

```R magic_args="-i pre_sample"
nrow(pre_sample %>%
    filter(OPERATOR_ID == 31618) %>%
    filter(YEAR == 2017) %>%
    filter(COMMODITY == 'hvl'))
```
