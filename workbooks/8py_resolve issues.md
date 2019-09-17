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

# 8. Resolve data issues


The analysis in section 8.2 is based on data retrieved from LexisNexis (LexisNexis Dossier).

```python
sample_file = '../preprocessed_data/sample_2019-09-10.feather'
issues_to_address = '../preprocessed_data/issues_to_address_2019-09-10.pickle'
names_table_file = '../preprocessed_data/names_table_2019-09-09.feather'

pipelines_2010_raw = '../data/pipelines_2010_2019-08-11.feather'
pipelines_2004_raw = '../data/pipelines_2004_2019-08-11.feather'
```

## Setup

```python
import pandas as pd
import numpy as np
from datetime import date
from functools import partial

today = date.today().isoformat()
```

## Load data

```python
import pickle

with open(issues_to_address, 'rb') as file:
    issues = pickle.load(file)
    
issues = (issue for issue in issues)
```

```python
sample = pd.read_feather(sample_file)
sample.sample(5)
assert sample.duplicated(subset=['OPERATOR_ID', 'YEAR', 'COMMODITY']).sum() == 0
```

```python
names_table = pd.read_feather(names_table_file)
names_table['NAME'] = names_table['NAME'].str.title()
names_table['NAME'] = names_table['NAME'].str.replace(r'[^A-Za-z0-9\s]+', '')
names_table.sample(3)
```

```python
pipelines_2010_raw = pd.read_feather(pipelines_2010_raw)
pipelines_2004_raw = pd.read_feather(pipelines_2004_raw)
```

## 8.1 Functions for analysis

```python
from functools import partial

def find_info(OPERATOR_ID, info_col: str, title: str, df = names_table, id_col = 'OPERATOR_ID', 
              year_col = 'YEAR', fuzzy=False):
    from fuzzywuzzy import fuzz
    
    values = np.unique(df[df[id_col] == int(OPERATOR_ID)][info_col]).tolist()
    result = []
    for value in values:
        start_year = df[df[info_col] == value][year_col].min()
        end_year = df[df[info_col] == value][year_col].max()
        id_ = OPERATOR_ID
        result = result + [{title: value, 'start_year': start_year, 'end_year': end_year, 'id_': id_}]
        
    if fuzzy and len(result) == 2 and fuzz.ratio(result[0][title].lower(), result[1][title].lower()) >= 95:
            result = [result[0]]
            
    return(result)

find_address = partial(find_info, info_col='STREET', title='street')
find_name = partial(find_info, info_col='NAME', title='name', fuzzy=True)
find_name('3445')
```

```python
def report_names(names: list):
    for name in names: 
        hist = find_name(name)
        if len(hist) > 1:
            print(f"\nOrganization {hist[0]['id_']} has changed its name:")
            for row in hist:
                print(f"    {row['id_']} was named {row['name']} from {row['start_year']} to {row['end_year']}.")
    
    if max([len(find_name(name)) for name in names]) < 2:
        print('No organizations were renamed at any time.')

report_names(['4907', '3445'])
```

```python
def find_total_miles_year(OPERATOR_ID, year, df = pipelines_2010_raw, year_col = 'REPORT_YEAR', 
                          id_col = 'OPERATOR_ID', miles_col='PARTBHCATOTAL'):
    observations = df.loc[(df[year_col] == year) & (df[id_col] == int(OPERATOR_ID))][miles_col]
    return observations.sum()

find_total_miles_year('4906', 2015)
```

```python
def find_total_miles(OPERATOR_ID, years, df = pipelines_2010_raw, year_col = 'REPORT_YEAR', miles_col='PARTBHCATOTAL', id_col='OPERATOR_ID'):
    result = []
    for year in years:
        result.append([year, find_total_miles_year(OPERATOR_ID, year, df=df, year_col=year_col, id_col=id_col, miles_col=miles_col)])
    return(result)

find_total_miles('4906', range(2013, 2017))
```

```python
find_total_miles_2004 = partial(find_total_miles, df = pipelines_2004_raw, year_col = 'YR', miles_col = 'HCAONM')
find_total_miles_2004(31579, range(2007, 2010))
```

## 8.2 Iterate over issues and resolve them one at a time


We use the dictionary "company groups" to capture any companies we have to combine to form one observation. At every step we consult ownership_changes.txt to see if there are changed in ownership over time.


### Store results in

```python
company_groups = pd.DataFrame()

def add_company_group(name: str, members: list, df = company_groups):
    new_group = pd.DataFrame({'members': members})
    new_group['name'] = name
    df = df.append(new_group, ignore_index=True)
    return df
```

```python
m_as = pd.DataFrame()

def add_m_a(name: str, members: list, df, start_year: str = None, end_year: str = None):
    new_group = pd.DataFrame({'members': members})
    new_group['name'] = name
    
    if start_year:
        new_group['start_year'] = start_year
    if end_year:
        new_group['end_year'] = end_year
    
    df = df.append(new_group, sort=False, ignore_index=True)
    return df
```

```python
spin_offs = []
```

### 8.2.1 Enterprise Products Operating

```python
print(next(issues))
```

```python
report_names(['31618', '3445', '14194', '30829', '31270', '32209'])
```

As per ownership_changes.txt, enterprise products hold a majority stake in Dixie Pipelines since at leat 2005, since data on an M&A is missing, we assume it has held a majority stake for the whole observation period before that. Teppco was acquired on Oct 26, 2009 (Deal Number 511604).

```python
company_groups = add_company_group('Enterprise Products (Group)', ['31618', '14194', '31270'], company_groups)
company_groups = add_company_group('Teppco (Group)', ['30829', '32209', '3445'])
company_groups.tail()
```

```python
m_as = add_m_a('Enterprise Products (Group)', ['Enterprise Products (Group)', 'Teppco (Group)'], start_year = '2010')
m_as.tail()
```

### 8.2.2 Oneok NGL

```python
print(next(issues))
```

```python
company_groups = add_company_group('ONEOK (Group)', ['32109', '30629'], company_groups)
```

### 8.2.3 Phillips 66

```python
print(next(issues))
```

Downstream business was spun off in 2011 as Phillips 66.


Sweeny refinery is not an independent organizations. We will reconsolidate the two organizations.


### Decision

```python
company_groups = add_company_group('Phillips 66 (Group)', ['15485', '31684'], company_groups)
company_groups.tail()
```

### 8.2.4 Magellan

```python
print(next(issues))
```

```python
report_names(['22610', '12105', '31579', '39504'])
```

LexisNexis yielded no reports of ownership changed for any subsidiaries (some assets changed hands, but that case is appropriately covered by the FERC data).


### Decision

```python
company_groups = add_company_group('Magellan (Group)', ['22610', '12105', '31579', '39504'], company_groups)
company_groups.tail()
```

### 8.2.5 Colonial Pipeline

```python
print(next(issues))
```

Not a concern.


### 8.2.6 Buckeye

```python
print(next(issues))
```

### Decision


LexisNexis does not indicate that Buckeye Development & Logistics is an outside acquisition by Buckeye Partners. We consolidate the two organizations into one.

```python
company_groups = add_company_group('Buckeye (Group)', ['1845', '31371'], company_groups)
company_groups.tail()
```

### 8.2.7 Sunoco

```python
print(next(issues))
```

```python
report_names(['18718', '7063', '12470', '22442', '32099', '32683', '39205', '39596'])
```

According to our .txt file on ownership changes, Sunoco 

    - acquired a majority stake in Inland Corp (32683) on May 17, 2011
    
    - acquired a majority stake in West Texas Gulf Pipeline (22442) on Aug 18, 2010
    
    - merged with Energy Transfer (32099) on Oct 5, 2012

```python
company_groups = add_company_group('Sunoco (Group)', ['18718', '12470', '39205', '39596', '7063'], company_groups)
company_groups = add_company_group('Energy Transfer Partners (Group)', ['32099'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Sunoco (Group)', ['Sunoco (Group)', '32683', '22442'], m_as, start_year = '2011')
m_as = add_m_a('Sunoco (Group)', ['Sunoco (Group)', 'Energy Transfer Partners (Group)'], m_as, start_year = '2013')

m_as.tail()
```

### 8.2.8 Flint Hills

```python
print(next(issues))
```

```python
find_total_miles('22855', range(2015, 2019))
```

The restructuring or sell-off does not seem to affect the organizations pipeline assets. We will ignore the rebranding efforts.


### 3.2.9 Kinder Morgan

```python
print(next(issues))
```

```python
report_names(['19237', '2190', '4472', '15674', '18092', '19585', '26125', '31555', '31957', '32114', 
              '32258', '32541', '32619', '32678', '39023', '39440', '39518'])
```

According to our .txt file on ownership changes, Kinder Morgan:

    - has held a majority share in Plantation Pipe Line (15674) since June 16, 1999
    
    - sold off Cochin (32258) to Pembina on Aug 21, 2019

```python
company_groups = add_company_group('Kinder Morgan (Group)', 
                                   ['19237', '2190', '4472', '15674', '18092', '19585', '26125', '31555', '31957', '32114', 
                                    '32258', '32541', '32619', '32678', '39023', '39440', '39518'], 
                                   company_groups)
company_groups.tail()
```

### 8.2.10 NuStar

```python
print(next(issues))
```

```python
report_names(['10012', '26094', '31454', '39348'])
```

Before Kaneb became Nustar Pipeline, it was operated by a partnership between Valero and NuStar (http://nustarenergy.com/en-us/Company/Pages/History.aspx).


LexisNexis Doessier does not list any M&As for the other three subsidiaries. They just seem to be two separate subsidiaries, that we can group together.

```python
company_groups = add_company_group('NuStar (Group)', ['26094', '31454', '39348'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('NuStar (Group)', ['NuStar (Group)', '10012'], m_as, start_year = '2007')
m_as = add_m_a('NuStar (Group)', ['NuStar (Group)', '31454'], m_as, start_year = '2006')
m_as.tail()
```

### 8.2.11 Plantation Pipeline

```python
print(next(issues))
```

Not a concern.


### 8.2.12 Enbridge

```python
print(next(issues))
```

```python
report_names(['11169', '31448', '31720', '31947', '32080', '15774', '32502'])
```

Spectra Energy bought Express Pipeline (31720) in 2012 from a number of stakeholders, including Kinder Morgan (Deal Number 741207). Enbridge merged with Spectra Energy on Feb 27, 2017 (LexisNexis Dossier Deal Number 885812).


North Dakota Pipeline Company is a subsidiary of Marathon, so we will assume that this asset has been bough by marathon in 2013.

```python
company_groups = add_company_group('Enbridge (Group)', 
                                   ['11169', '31448', '31720', '31947', '32080', '32502'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Enbridge (Group)', ['Enbridge (Group)', '15774'], m_as, end_year='2013')
m_as = add_m_a('Enbridge (Group)', ['Enbridge (Group)', '31720'], m_as, start_year='2012')
m_as.tail()
```

According to our notes, Enbridge also acquired a majority in Olympic pipeline (30781) from BP on Feb 1, 2006.

```python
m_as = add_m_a('Enbridge (Group)', ['Enbridge (Group)', '30781'], m_as, start_year='2006')
m_as = add_m_a('BP (Group)', ['BP (Group)', '30781'], m_as, start_year='2001', end_year='2006')
m_as.tail()
```

### 9.2.13 Marathon

```python
print(next(issues))
```

```python
report_names(['32147', '15774', '22830', '26026', '31570', '31574', '31583', '31871', '38933', '39013', '39029', '39347', '12127'])
```

As we have touched on above, the North Dakota pipeline's owner was named "Enbridge Pipelines", but it was actually owned by a consortium of different actors.


LexisNexis indicates that Tesoro was renamed to Andeavor, and acquired by Marathon on Oct 1, 2018 (LexisNexis Dossier Deal Number 3052392). We will group Wolverine with Marathon, and also combine all Tesoros into one observation. For 2019, we would subsume Tesoro under Marathon.

```python
# Marathon and Wolverine
company_groups = add_company_group('Marathon (Group)', 
                                   ['32147', '22830', '26026', '31574', '31871', '39347', '12127'], company_groups)

# Tesoro
company_groups = add_company_group('Tesoro (Group)', ['31570', '31583', '38933', '39013', '39029'], company_groups)
company_groups.tail()
```

North Dakota Pipeline was acquired from Enbridge in 2013.

```python
m_as = add_m_a('Marathon (Group)', ['Marathon (Group)', '15774'], m_as, start_year='2013')
```

### 8.2.14 ExxonMobil

```python
print(next(issues))
```

```python
report_names(['4906', '12624', '12628', '12634', '30005'])
```

All are wholly owned subsidiaries of exxonmobil. LexisNexis indicates no M&A activities. We combine them into one observation.

```python
company_groups = add_company_group('ExxonMobil (Group)', ['4906', '12624', '12628', '12634', '30005'], company_groups)
company_groups.tail()
```

### 8.2.15 Chevron

```python
print(next(issues))
```

```python
report_names(['2731', '2339', '31556', '31554'])
```

Texaco merged with Chevron in early 2002. Our notes indicate that Boardwalk is a subsidiary of the Loews Corporation (which does not hold any other pipeline assets) that acquired assets from Chevron on Oct 8, 2014.

```python
company_groups = add_company_group('Chevron (Group)', ['2731', '2339'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Chevron (Group)', ['Chevron (Group)', '31556'], m_as, start_year='2002')
m_as = add_m_a('Chevron (Group)', ['Chevron (Group)', '31554'], m_as, start_year='2002', end_year='2014')
m_as.tail()
```

### 8.2.16 NuStar (repeat)

```python
print(next(issues))
```

We have addressed NuStar above and will address Valero below.


### 8.2.17 SFPP

```python
print(next(issues))
```

Not a concern.


### 8.2.18 Marathon (repeat)

```python
print(next(issues))
```

Already addressed above, not a concern.


### 8.2.19 Explorer Pipeline

```python
print(next(issues))
```

Not a concern.


### 8.2.20 Buckeye

```python
print(next(issues))
```

Not a concern.


### 8.2.21 Enterprise

```python
print(next(issues))
```

Already addressed above.


### 8.2.22 Equistar

```python
print(next(issues))
```

Not a concern.


### 8.2.23 Teppco

```python
print(next(issues))
```

Not a conern/already adressed above.


### 8.2.24 Kinder Morgan

```python
print(next(issues))
```

Not a concern/already addressed above.


### 8.2.25 Permian

```python
print(next(issues))
```

Permian is already integrated with NuStar.


### 8.2.26 Tesoro (repeat)

```python
print(next(issues))
```

Already covered above.


### 8.2.27 Plains Pipeline

```python
print(next(issues))
```

```python
report_names(['31666', '300', '26085'])
```

LexisNexis Doassiers indicates no M&As for the subsidiaries, Plains Marketing and Rocky Mountain Pipeline System.

```python
company_groups = add_company_group('Plains Pipeline (Group)', ['300', '31666', '26085'], company_groups)
company_groups.tail()
```

### 3.2.28 Mid-Valley

```python
print(next(issues))
```

No concern.


### 8.2.29 Kinder Morgan (repeat)

```python
print(next(issues))
```

Already covered above.


### 8.2.30 Shell pipeline

```python
print(next(issues))
```

Not a concern.


### 8.2.31 DCP 

```python
print(next(issues))
```

Since it is the only organization in the group, this is not a concern.


### 3.2.32 BP

```python
print(next(issues))
```

```python
report_names(['31189', '18386', '30781', '31610', '1466', '31549'])
```

```python
company_groups = add_company_group('BP (Group)', ['31189', '18386', '31610', '1466', '31549'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('BP (Group)', ['BP (Group)', '30781'], m_as, start_year='2001', end_year='2006')
m_as.tail()
```

### 8.2.33 ExxonMobil (repeat)

```python
print(next(issues))
```

Already covered above.


### 8.2.34 Amoco

```python
print(next(issues))
```

According to our notes, Dome has been part of Amoco since 1988.

```python
company_groups = add_company_group('Amoco (Group)', ['395', '3466'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

Name change is not a concern.


###  8.2.35 Dixie (repeat)

```python
print(next(issues))
```

Name change is not a concern.


### 8.2.36 West shore

```python
print(next(issues))
```

Name change is not a concern.


### 8.2.37 Alon USA

```python
print(next(issues))
```

Seems the organization has adapted a new operator ID for some reason.

```python
report_names(['31443', '26136'])
```

```python
find_total_miles('31443', range(2010, 2013))
```

```python
find_total_miles_2004('31443', range(2005, 2009))
```

```python
find_total_miles('26136', range(2010, 2015))
```

Seems to be two separate subsidiaries.

```python
company_groups = add_company_group('Alon (Group)', ['31443', '26136'], company_groups)
```

### 8.2.38 Citgo

```python
print(next(issues))
```

```python
report_names(['30755', '2387', '31023'])
```

Our notes suggest no M&A activities.

```python
company_groups = add_company_group('Citgo (Group)', ['30755', '2387', '31023'], company_groups)
company_groups.tail()
```

### 8.2.39 Sinclair

```python
print(next(issues))
```

Not a concern.


### 8.2.40 Holly

```python
print(next(issues))
```

```python
report_names(['32011', '32493', '5656', '13161'])
```

```python
company_groups = add_company_group('HollyFrontier (Group)', ['32011', '32493', '5656', '13161'], company_groups)
company_groups.tail()
```

Repeats

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.41 Genesis

```python
print(next(issues))
```

```python
report_names(['31045', '32407'])
```

```python
company_groups = add_company_group('Gensis (Group)', ['31045', '32407'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

### 3.2.42 Williams Field services

```python
print(next(issues))
```

```python
report_names(['30826', '994', '32614'])
```

```python
company_groups = add_company_group('Williams Field Services (Group)', ['30826', '994', '32614'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

### 8.2.43 Pacific pipeline system

```python
print(next(issues))
```

```python
report_names(['31325', '31695', '31885'])
```

```python
company_groups = add_company_group('Pacific (Group)', ['31325', '31695', '31885'], company_groups)
company_groups.tail()
```

### 8.2.44 Velero

```python
print(next(issues))
```

```python
report_names(['4430', '39105', '32679', '31415', '31742', '32032', '31454'])
```

Since 31454 was held in a partnership, we do not include this observation in the group. Premcor was acquired by Valero in 2005.

```python
company_groups = add_company_group('Valero (Group)', ['4430', '39105', '32679', '31415', '32032'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Valero (Group)', ['Valero (Group)', '31742'], m_as, start_year='2005')
m_as.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.45 CHS

```python
print(next(issues))
```

```python
report_names(['2170', '9175', '14391', '26065', '26086', '32283'])
```

```python
company_groups = add_company_group('CHS (Group)', ['2170', '9175', '14391', '26065', '26086', '32283'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

### 8.2.46 Rose Rock

```python
print(next(issues))
```

```python
company_groups = add_company_group('Rose Rock (Group)', ['31476', '32288'], company_groups)
company_groups.tail()
```

### 8.2.47 BKEP

```python
print(next(issues))
```

```python
report_names(['32551', '32481'])
```

```python
company_groups = add_company_group('BKEP (Group)', ['32551', '32481'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.48 Targa Resources

```python
print(next(issues))
```

```python
report_names(['32296', '30626', '39823', '22175', '31977'])
```

Dynegy still exists under different ownership. Targa probably bought the pipeline assets in 2005.

```python
company_groups = add_company_group('Targa (Group)', ['32296', '39823', '31977'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Dynegy (Group)', ['30626', '22175'], m_as, end_year = '2005')
m_as = add_m_a('Targa (Group)', ['307626', '22175'], m_as, start_year = '2006')
m_as.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 3.2.49 Dow

```python
print(next(issues))
```

```python
report_names(['3527', '2162', '3535', '30959', '26086', '39823'])
```

```python
company_groups = add_company_group('Dow (Group)', ['3527', '2162', '3535', '30959'], company_groups)
company_groups.tail()
```

### 8.2.50 Boardwalk

```python
print(next(issues))
```

```python
report_names(['39138', '31554'])
```

```python
company_groups = add_company_group('Boardwalk (Group)', ['39138'], company_groups)
company_groups.tail()
```

```python
m_as = add_m_a('Boardwalk (Group)', ['Boardwalk (Group)', '31554'], m_as, start_year = '2014')
m_as.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.51 Enlink

```python
print(next(issues))
```

```python
report_names(['32005', '32107'])
```

No indicator of an M&A taking place on LexisNexis.

```python
company_groups = add_company_group('Enlink (Group)', ['32005', '32107'], company_groups)
company_groups.tail()
```

### 8.2.52 Hunt

```python
print(next(issues))
```

```python
report_names(['26048', '7660'])
```

```python
company_groups = add_company_group('Hunt (Group)', ['26048', '7660'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.53 Eastman Chemical

```python
print(next(issues))
```

```python
company_groups = add_company_group('Eastman Chemical (Group)', ['31166', '26103'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.54 Delek

```python
print(next(issues))
```

```python
report_names(['11551', '15851', '26061', '26136', '39183'])
```

LexisNexis does not indicate that Delek bought Lion Oil.

```python
company_groups = add_company_group('Delek (Group)', ['11551', '15851', '26061', '26136'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

### 8.2.55 Suncor

```python
print(next(issues))
```

```python
company_groups = add_company_group('Suncor (Group)', ['15786', '31822'], company_groups)
company_groups.tail()
```

### 8.2.56 Arrow

```python
print(next(issues))
```

```python
report_names(['39083', '39368'])
```

```python
company_groups = add_company_group('Crestwood (Group)', ['39083', '39368'], company_groups)
```

### 8.2.57 Torrance

```python
print(next(issues))
```

```python
report_names(['39534', '26120', '31167', '39535'])
```

```python
company_groups = add_company_group('Torrance (Group)', ['39534', '26120', '31167', '39535'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.58 LDH

```python
print(next(issues))
```

```python
report_names(['32035', '31673', '32246'])
```

Our notes don't indicate an M&A has taken place.

```python
company_groups = add_company_group('LDH Energy (Group)', ['32035', '31673', '32246'], company_groups)
company_groups.tail()
```

According to our notes, LDH has been acquired by JV between Energy Transfer Partners and Regency Energy Partners, controlled by ETP on May 2, 2011.

```python
m_as = add_m_a('Energy Transfer Partners (Group)', ['Energy Transfer Partners (Group)', 'LDH Energy (Group)'], m_as, start_year = '2011')
m_as.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

### 8.2.59 Glass Mountain

```python
print(next(issues))
```

```python
find_total_miles('39080', range(2015, 2020))
```

```python
find_total_miles('39774', range(2015, 2020))
```

```python
report_names(['39080', '39774'])
```

LexisNexis does not indicate who the owner of Glass Mountain is, but shows that Navigator Energy was acquired by NuStar on May 4, 2017 (Deal Number 3004179). Since the two IDs obviously refer to the same organization, and this organization did not then continue reporting as part of NuStar, there is nothing we need to do other than group them together.

```python
company_groups = add_company_group('Glass Mountain (Group)', ['39080', '39774'], company_groups)
company_groups.tail()
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

```python
print(next(issues))
```

## 8.3 Overview

```python
company_groups
```

```python
m_as
```

```python
spin_offs
```

## 8.4 Additions from ownership changes text file

```python
find_name('39029')
```

Was sold by Chevron to Tesoro in 2013, but Tesoro set up a new unit for this pipeline, so we do not need to take any action.

```python
company_groups.to_feather(f'../preprocessed_data/company_groups_{today}.feather')
m_as.to_feather(f'../preprocessed_data/m_as_{today}.feather')
```

```python

```
