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

<!-- #region {"pycharm": {"name": "#%% md\n"}} -->

# 2 - Data exploration

<!-- #endregion -->

```python jupyter={"outputs_hidden": false} pycharm={"is_executing": false, "name": "#%% \n"}
# import parameters
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams["figure.figsize"] = (20,10)
```

## 2.1 Incidents data overview

```python jupyter={"outputs_hidden": false} pycharm={"is_executing": false, "name": "#%%\n"}
incidents = pd.read_excel('../data/incidents_2019-08-09/hl2010toPresent.xlsx', 
                          sheet_name=1)

incidents.sample(5)
```

```python jupyter={"outputs_hidden": false} pycharm={"is_executing": false, "name": "#%%\n"}
incidents['NAME'].value_counts().head(10)
```

```python jupyter={"outputs_hidden": false} pycharm={"name": "#%%\n"}
incidents['OPERATOR_ID'].value_counts().head(10)
```

```python
incidents['COMMODITY_RELEASED_TYPE'].unique()
```

There seem to be some minor discrepancies between ID and name. Matching every ID to its most common company name should fix it. 

```python
incidents['OPERATOR_ID'].value_counts().hist(bins=30, figsize=(20, 10))
```

```python
len(incidents)
```

## 2.2 Oil pipeline data

```python
oil_pipelines = pd.read_excel('../data/pipelines_2010_present_2019-08-09/annual_hazardous_liquid_2010.xlsx', skiprows=2)

oil_pipelines.sample(5)
```

```python
from os import listdir

pipeline_files = [file for file in listdir('../data/pipelines_2010_present_2019-08-09/') if'annual_hazardous_liquid' in file]
pipeline_files
```

```python
pipelines = pd.concat([pd.read_excel(f'../data/pipelines_2010_present_2019-08-09/{file}', skiprows=2) for file in pipeline_files])
pipelines = pipelines.reset_index(drop = True)

pipelines.sample(5)
```

See which company has the vastest pipeline network.

```python
pipelines.loc[pipelines.groupby('OPERATOR_ID')['PARTBHCATOTAL'].idxmax()].nlargest(10, 'PARTBHCATOTAL')[['REPORT_YEAR', 'OPERATOR_ID', 'PARTA2NAMEOFCOMP', 'PARTBHCATOTAL']]
```

```python
pipelines['PARTA5COMMODITY'].unique()
```

Compare to

```python
incidents['COMMODITY_RELEASED_TYPE'].unique()
```

The types correspond well, but the terminology is different.


## 2.3 Gas pipelines

```python
gas_pipelines = pd.read_excel('../data/gas_2010_present_2019-08-09/annual_liquefied_natural_gas_2015.xlsx', skiprows=1)

gas_pipelines.sample(5)
```

```python
gas_files = [file for file in listdir('../data/gas_2010_present_2019-08-09/') if'annual_liquefied_natural_gas' in file]
gas_files
```

```python
gas = pd.concat([pd.read_excel(f'../data/gas_2010_present_2019-08-09/{file}', skiprows=1) for file in gas_files[:3]], sort=False)
gas = gas.reset_index(drop = True)

gas.sample(5)
```

The warning stems from the fact that the PARTA4NAMEOFCOMP columns was dropped, starting from 2014 (see below). Fortunately, we can use the field "PARTA2NAMEOFCOMP" and "PARTA2NAMEOFPARENT_COM" to get the information.

```python
gas_columns_2010 = pd.read_excel('../data/gas_2010_present_2019-08-09/annual_liquefied_natural_gas_2010.xlsx', skiprows=1, skipfooter=999).columns.tolist()
gas_columns_2014 = pd.read_excel('../data/gas_2010_present_2019-08-09/annual_liquefied_natural_gas_2014.xlsx', skiprows=1, skipfooter=999).columns.tolist()
set(gas_columns_2010) - set(gas_columns_2014)
```

## 2.4. Where do incidents occur? Regular, or LNG pipelines?


### 2.4.1 Are there operators who operate both regular and LNG pipelines?

```python
gas_operators = np.unique(gas['OPERATOR_ID']).tolist()
gas_operators[:5]
```

```python
pipeline_operators = np.unique(pipelines['OPERATOR_ID']).tolist()
pipeline_operators[:5]
```

```python
common_operators = set(gas_operators).intersection(set(pipeline_operators))
print(common_operators)
```

Only one company occurs on both lists.

```python
pipelines.loc[pipelines['OPERATOR_ID'].isin(common_operators) & (pipelines['REPORT_YEAR'] == 2017)]['PARTA2NAMEOFCOMP'].tolist()
```

### 2.4.2 Where do the accidents occur?

```python
incidents.loc[incidents['OPERATOR_ID'] == 31636]
```

Our common operators has no incidents, so we can ignore this segment.

```python
regular_pipeline_incidents = incidents['OPERATOR_ID'].isin(pipelines['OPERATOR_ID']).sum()
regular_pipeline_incidents
```

```python
nlg_pipeline_incidents = incidents['OPERATOR_ID'].isin(gas['OPERATOR_ID']).sum()
nlg_pipeline_incidents
```

Looks like we can ignore this second dataset for our analysis.


## 2.5 Pipeline age - distribution and missingness

```python
import rpy2.rinterface
```

```python
%load_ext rpy2.ipython
```

```python
pipelines_age = pipelines[['OPERATOR_ID', 'REPORT_YEAR', 'PARTEUNKNTOTAL', 'PARTEPRE40TOTAL'] + 
                          [f'PARTE19{decade}0TOTAL' for decade in range(5,10)] + 
                          ['PARTE2000TOTAL', 'PARTE2010TOTAL', 'PARTETOTAL']]
pipelines_age.sample(5)
```

```R magic_args="-i pipelines_age"
suppressMessages(library(tidyverse))

pipelines_age %>%
    group_by(OPERATOR_ID, REPORT_YEAR) %>%
    mutate(perc_unknown = PARTEUNKNTOTAL / PARTETOTAL) %>%
    ggplot(aes(x=perc_unknown)) + 
    geom_histogram()
```

Unknown age fortunately is not an issue.

```R magic_args="-i pipelines_age"
pipelines_age %>%
    gather(PARTEPRE40TOTAL, PARTE1950TOTAL, PARTE1960TOTAL, PARTE1970TOTAL, PARTE1980TOTAL, PARTE1990TOTAL, 
           PARTE2000TOTAL, PARTE2010TOTAL, key = 'DECADE', value = 'MILES') %>%
    ggplot(aes(x=MILES)) + 
    geom_histogram() +
    facet_wrap(~DECADE, nrow=3) + 
    scale_y_log10()
```

```R magic_args="-i pipelines_age"
pipelines_age %>%
    gather(PARTEPRE40TOTAL, PARTE1950TOTAL, PARTE1960TOTAL, PARTE1970TOTAL, PARTE1980TOTAL, PARTE1990TOTAL, 
           PARTE2000TOTAL, PARTE2010TOTAL, key = 'DECADE', value = 'MILES') %>%
    filter(MILES > 100) %>%
    ggplot(aes(x=MILES)) + 
    geom_histogram() +
    facet_wrap(~DECADE, nrow=3)
```

```R magic_args="-i pipelines_age"
pipelines_age %>%
    gather(PARTEPRE40TOTAL, PARTE1950TOTAL, PARTE1960TOTAL, PARTE1970TOTAL, PARTE1980TOTAL, PARTE1990TOTAL, 
           PARTE2000TOTAL, PARTE2010TOTAL, key = 'DECADE', value = 'MILES') %>%
    group_by(DECADE) %>%
    summarize(total_miles = sum(MILES))
```

```R magic_args="-i pipelines_age"
pipelines_age %>%
    gather(PARTEPRE40TOTAL, PARTE1950TOTAL, PARTE1960TOTAL, PARTE1970TOTAL, PARTE1980TOTAL, PARTE1990TOTAL, 
           PARTE2000TOTAL, PARTE2010TOTAL, key = 'DECADE', value = 'MILES') %>%
    group_by(DECADE, REPORT_YEAR) %>%
    summarize(total_miles = sum(MILES)) %>%
    spread(REPORT_YEAR, total_miles)
```

The distribution across decades is surprisingly balanced. Strong trends are not discernible, there is the construction of new pipelines, and some pre-1980 pipelines are being retired.


## 2.6 How much % is offshore?

```python
pipeline_offshore = pipelines[['OPERATOR_ID', 'REPORT_YEAR', 'PARTBHCAOFFSHORE', 'PARTBHCATOTAL', 'PARTA5COMMODITY']]
```

```python
pipeline_offshore['PARTBHCAOFFSHORE'].isna().value_counts()
```

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    group_by(REPORT_YEAR) %>%
    summarize(perc_na = mean(is.na(PARTBHCAOFFSHORE)))
```

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    group_by(PARTA5COMMODITY) %>%
    summarize(perc_na = mean(is.na(PARTBHCAOFFSHORE)))
```

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    mutate(missing_offshore = is.na(PARTBHCAOFFSHORE)) %>%
    group_by(OPERATOR_ID) %>%
    summarize(perc_missing = sprintf("%0.1f", sum(missing_offshore) / n())) %>%
    {table(.$perc_missing)}
```

```R magic_args="-i pipeline_offshore"

pipeline_offshore %>% 
    #Picking a year at random
    filter(REPORT_YEAR == 2015) %>%
    mutate(perc_offshore = sprintf("%0.2f", PARTBHCAOFFSHORE / PARTBHCATOTAL)) %>%
    {table(.$perc_offshore)}
```

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    #Picking a year at random
    mutate(perc_offshore = sprintf("%0.1f", PARTBHCAOFFSHORE / PARTBHCATOTAL)) %>%
    {table(.$perc_offshore, .$REPORT_YEAR)}
```

Are there any values close to 1, but not equal to 1?

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    mutate(perc_offshore = sprintf("%0.2f", PARTBHCAOFFSHORE / PARTBHCATOTAL)) %>%
    filter(perc_offshore > 0.8) %>%
    {table(.$perc_offshore, .$REPORT_YEAR)}
```

The presence of organizations that have a high share of offshore is somewhat concerning, because the data on the age of the pipelines does not differentiate between on and offshore. We could rectify this issue by removing any operators with offshore pipelines, since most operators do not have offshore pipelines. Let's see hwo many observations we would lose.

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>% 
    mutate(perc_offshore = PARTBHCAOFFSHORE / PARTBHCATOTAL) %>%
    mutate(perc_offshore = ifelse(is.na(perc_offshore), 0, perc_offshore)) %>%
    mutate(perc_offshore = sprintf("%0.2f", perc_offshore)) %>%
    {table(.$perc_offshore)}
```

Looks like we can exclude offshore without losing too many observations.

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>%
    mutate(perc_offshore = PARTBHCAOFFSHORE / PARTBHCATOTAL) %>%
    mutate(perc_offshore = ifelse(is.na(perc_offshore), 0, perc_offshore)) %>%
    group_by(OPERATOR_ID) %>%
    summarize(offshore_max = max(perc_offshore)) %>%
    mutate(offshore_max = sprintf("%0.1f", offshore_max)) %>%
    {table(.$offshore_max)}
```

By setting a strict limit of no offshore, we will lose 43 out of 703 observations (organizations).

```R magic_args="-i pipeline_offshore"
pipeline_offshore %>%
    mutate(perc_offshore = PARTBHCAOFFSHORE / PARTBHCATOTAL) %>%
    mutate(perc_offshore = ifelse(is.na(perc_offshore), 0, perc_offshore)) %>%
    group_by(OPERATOR_ID) %>%
    summarize(offshore_max = max(perc_offshore)) %>%
    filter(offshore_max < 0.1) %>%
    mutate(offshore_max = sprintf("%0.2f", offshore_max)) %>%
    {table(.$offshore_max)}
```

More like 47 for a strict limit of 0.0.


## 2.7 FERC Notices

```python
notices = pd.read_csv('../data/ferc_notices_2019-08-01.csv')

len(notices)
```

Check whether any notes were read incorrectly (too many requests).

```python
notices['full-text'].str.contains('too manyrequests').value_counts()
```

## 2.8 Continuity between 2004/2010 dataset

```python
pipelines_2004_2009 = [file for file in listdir('../data/pipelines_2004_2009_2019-08-02/') if 'annual_hazardous_liquid' in file]
pipelines_2004_2009 = pd.concat([pd.read_excel(f'../data/pipelines_2004_2009_2019-08-02/{file}') 
                                 for file in pipelines_2004_2009])
pipelines_2004_2009 = pipelines_2004_2009.reset_index(drop = True)

pipelines_2004_2009.sample(5)
```

```python
pipelines_total = pipelines[['REPORT_YEAR', 'OPERATOR_ID', 'PARTA5COMMODITY', 'PARTBHCAONSHORE']].copy()
pipelines_total = pipelines_total.rename(columns={'REPORT_YEAR': 'YEAR', 'PARTA5COMMODITY': 'COMMODITY', 'PARTBHCAONSHORE': 'MILES'})
new_names_pipelines_1 = {'Crude Oil': 'crude', 
                       'HVL': 'hvl',
                       'Refined and/or Petroleum Product (non-HVL)': 'non-hvl'}
pipelines_total = pipelines_total.replace({'COMMODITY': new_names_pipelines_1})
pipelines_total.sample(5)
```

```python
pipelines_total_2 = pipelines_2004_2009[['YR', 'OPERATOR_ID', 'SYSTEM_TYPE', 'HCAONM']]
pipelines_total_2 = pipelines_total_2.rename(columns={'YR': 'YEAR', 'SYSTEM_TYPE': 'COMMODITY', 'HCAONM': 'MILES'})
new_names_pipelines_2 = {"CRUDE OIL": "crude", "HVLS": "hvl", "PETROLEUM & REFINED PRODUCTS": "non-hvl"}
pipelines_total_2 = pipelines_total_2.replace({'COMMODITY': new_names_pipelines_2})
pipelines_total_2.sample(5)
```

```python
pipelines_total = pd.concat([pipelines_total, pipelines_total_2]).reset_index(drop=True)
pipelines_total.sample(5)
```

```R magic_args="-i pipelines_total"
pipelines_total %>%
    group_by(YEAR) %>%
    filter(!is.na(MILES)) %>%
    summarize(total_miles = sum(MILES)) %>%
    ggplot(aes(x=YEAR, y=total_miles)) +
        geom_point()
```

```R magic_args="-i pipelines_total"
pipelines_total %>%
    filter(COMMODITY %in% c('hvl', 'crude', 'non-hvl')) %>%
    filter(!is.na(MILES)) %>%
    group_by(YEAR, COMMODITY) %>%
    summarize(total_miles = sum(MILES)) %>%
    ggplot(aes(x=YEAR, y=total_miles)) +
        geom_point() +
        facet_wrap(.~COMMODITY)
```

## 2.9 Distribution of data


See how incidents are distributed over time/operators.

```python
pipelines['PARTA5COMMODITY'].unique()
```

```python
pipelines_match = pipelines[['OPERATOR_ID', 'REPORT_YEAR', 'PARTA5COMMODITY', 'PARTBHCAONSHORE'
                            ]].rename({'REPORT_YEAR': 'YEAR', 'PARTA5COMMODITY': 'COMMODITY', 'PARTBHCAONSHORE': 'MILES'})
new_names_pipelines = {'Crude Oil': 'crude', 
                       'CO2': 'co2',
                       'Fuel Grade Ethanol (dedicated system)': 'fge', 
                       'HVL': 'hvl',
                       'Refined and/or Petroleum Product (non-HVL)': 'non-hvl'}
pipelines_match = pipelines_match.replace({'PARTA5COMMODITY': new_names_pipelines})
pipelines_match = pipelines_match.rename(columns=
                                         {'PARTA5COMMODITY': 'COMMODITY', 'PARTBHCAONSHORE': 'MILES', 'REPORT_YEAR': 'YEAR'})

pipelines_match.sample(5)
```

```python
sum(pipelines_match['MILES'].isna())
```

```python
incidents['COMMODITY_RELEASED_TYPE'].unique()
```

```python
incidents_match = incidents[['OPERATOR_ID', 'LOCAL_DATETIME', 'SIGNIFICANT', 'COMMODITY_RELEASED_TYPE']]
incidents_match = incidents_match.rename(columns={'COMMODITY_RELEASED_TYPE': 'COMMODITY'})

new_names_incidents = {'REFINED AND/OR PETROLEUM PRODUCT (NON-HVL) WHICH IS A LIQUID AT AMBIENT CONDITIONS': 'non-hvl', 
                       'CO2 (CARBON DIOXIDE)': 'co2', 
                       'HVL OR OTHER FLAMMABLE OR TOXIC FLUID WHICH IS A GAS AT AMBIENT CONDITIONS': 'hvl', 
                       'CRUDE OIL': 'crude', 
                       'BIOFUEL / ALTERNATIVE FUEL(INCLUDING ETHANOL BLENDS)': 'hvl'}

incidents_match = incidents_match.replace({'COMMODITY': new_names_incidents})
incidents_match['SIGNIFICANT'] = incidents_match.loc[incidents_match['SIGNIFICANT'] == 'YES']
incidents_match['YEAR'] = incidents_match['LOCAL_DATETIME'].dt.year
incidents_match = incidents_match.drop(columns=['SIGNIFICANT', 'LOCAL_DATETIME'])
incidents_match = incidents_match.groupby(['OPERATOR_ID', 'COMMODITY', 'YEAR']).size().reset_index(name='INCIDENTS')
incidents_match.sample(5)
```

```python
incidents_match = incidents_match.loc[incidents_match['COMMODITY'].isin(['crude', 'hvl', 'non-hvl'])]
n_incident_obs = len(incidents_match.loc[~incidents_match[['OPERATOR_ID', 'YEAR', 'COMMODITY']].duplicated()])
print(n_incident_obs)

pipelines_match = pipelines_match.loc[pipelines_match['COMMODITY'].isin(['crude', 'hvl', 'non-hvl'])]
n_pipelines_obs = len(pipelines_match.loc[~pipelines_match[['OPERATOR_ID', 'YEAR', 'COMMODITY']].duplicated()])
print(n_pipelines_obs)
```

```python
pipelines_incidents = pipelines_match.merge(incidents_match, how='left', on=['YEAR', 'COMMODITY', 'OPERATOR_ID'])

print(len(pipelines_incidents))
pipelines_incidents['MILES'] = pipelines_incidents['MILES'].fillna(value=0)
pipelines_incidents['INCIDENTS'] = pipelines_incidents['INCIDENTS'].fillna(value=0)
pipelines_incidents.sample(5)
```

### 2.9.1 Visualize


### Incidents (raw)

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    ggplot(aes(x=INCIDENTS)) +
        geom_histogram(bins=50) + 
        scale_y_log10()
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    ggplot(aes(x=INCIDENTS)) +
        geom_histogram(bins=50) + 
        facet_wrap(.~COMMODITY) +
        scale_y_log10()
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    ggplot(aes(x=INCIDENTS)) +
        geom_histogram(bins=30) + 
        facet_wrap(.~YEAR) +
        scale_y_log10()
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    group_by(YEAR) %>%
    summarize(n=sum(INCIDENTS))
```

### Incidents per mile

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    group_by(COMMODITY) %>%
    summarize(sum(INCIDENTS) / sum(MILES))
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    group_by(COMMODITY) %>%
    summarize(sum(MILES))
```

```R magic_args="-i pipelines_incidents"
length(unique(pipelines_incidents$OPERATOR_ID))
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    group_by(OPERATOR_ID) %>%
    summarize(INCIDENTS_MILE = sum(INCIDENTS) / (sum(MILES) + 0.01)) %>%
    mutate(INCIDENTS_MILE = sprintf("%0.2f", INCIDENTS_MILE)) %>%
    {table(.$INCIDENTS_MILE)}
```

```R magic_args="-i pipelines_incidents"
nrow(unique(select(pipelines_incidents, OPERATOR_ID, YEAR)))
```

```R magic_args="-i pipelines_incidents"
pipelines_incidents %>%
    group_by(OPERATOR_ID, YEAR) %>%
    summarize(INCIDENTS_MILE = sum(INCIDENTS) / (sum(MILES) + 0.01)) %>%
    mutate(INCIDENTS_MILE = sprintf("%0.2f", INCIDENTS_MILE)) %>%
    {table(.$INCIDENTS_MILE)}
```

```R magic_args="-i pipelines_incidents"
incident_prone <- pipelines_incidents %>%
    group_by(OPERATOR_ID) %>%
    summarize(INCIDENTS_MILE = sum(INCIDENTS) / (sum(MILES) + 0.01)) %>%
    filter(INCIDENTS_MILE < 5) %>%
    filter(INCIDENTS_MILE >= 0.05)

print(incident_prone[1:10, ])
print(incident_prone[11:20, ])
```

## 2.10 Source of duplicates in 2004- data


Check source for duplicate observations in 2004- data

```python
from os import listdir

pipelines_2004_2009 = [file for file in listdir('../data/pipelines_2004_2009_2019-08-02/') if 'annual_hazardous_liquid' in file]
pipelines_2004_2009 = pd.concat([pd.read_excel(f'../data/pipelines_2004_2009_2019-08-02/{file}') 
                                 for file in pipelines_2004_2009])
pipelines_2004_2009 = pipelines_2004_2009.reset_index(drop = True)

pipelines_2004_2009.sample(3)
```

```python
duplicates = pipelines_2004_2009.loc[pipelines_2004_2009.duplicated(subset=['OPERATOR_ID', 'YR', 'SYSTEM_TYPE'], 
                                                                    keep=False)]
duplicates['ORIGINAL'].value_counts()
```

```python
duplicates['OPERATOR_ID'].value_counts()
```

```python
operators_w_duplicates = list(duplicates['OPERATOR_ID'].unique())
operators_w_duplicates = pipelines_2004_2009[pipelines_2004_2009['OPERATOR_ID'].isin(operators_w_duplicates)]

operators_w_duplicates.groupby('YR')['HCAONM'].sum()
```

```python
operators_w_duplicates.groupby(['SYSTEM_TYPE', 'YR'])['HCAONM'].sum()
```

It all seems consisten enough. Let's pick out a case.

```python
duplicates.groupby('OPERATOR_ID')['HCAONM'].sum()
```

```python
duplicates[duplicates['OPERATOR_ID'] == 18718]['NAME']
```

### 2.10.1 Example: Sunoco


Let's look at the two cases that actually contain data.

```python
sunoco = duplicates.loc[duplicates['OPERATOR_ID'] == 18718]

sunoco['YR'].value_counts()
```

```python
sunoco.groupby('YR')['HCAONM'].sum()
```

```python
sunoco[['YR', 'NAME', 'SYSTEM_TYPE', 'HCAONM']].sort_values('YR')
```

Looks like Sunoco used to report Western Area and Eastern Area separately. In 2008 there seem to have been acquisitions/expansions, including a diversification into transport of Petroleum.

```python
sunoco.loc[(sunoco['YR'] == 2008) & (sunoco['SYSTEM_TYPE'] == 'PETROLEUM & REFINED PRODUCTS')]
```

The different addresses here also indicate that there are different areas that Sunoco reports on.


Although there are many empty observations, at least the combined observations are consistent over time.


### 2.10.4 Test for other variables of interest

```python
columns_of_interest = ['HCAONM', 'HCAOFFM', 'ERWTM_1', 'ERWTM_2', 'ERWTM_3', 'ERWTM_4', 'ERWTM_5', 'ERWTM_6',
                       'ERWTM_7', 'ERWTM_8']
timeline = pd.DataFrame([operators_w_duplicates.groupby('YR')[column].sum() for column in columns_of_interest])
timeline
```

Again, it seems consistent enough.

```python

```
