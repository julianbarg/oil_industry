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

# 16. Create results table

```python
import pandas as pd
import numpy as np
```

```python
model1_file = "../results/model1_2019-09-16.xlsx"
model2_file = "../results/model2_2019-09-16.xlsx"
model3_file = "../results/model3_2019-09-16.xlsx"
model4_file = "../results/model4_2019-09-16.xlsx"
model5_file = "../results/model5_2019-09-16.xlsx"
model6_file = "../results/model6_2019-09-16.xlsx"
```

```python
model1 = pd.read_excel(model1_file)
model2 = pd.read_excel(model2_file)
model3 = pd.read_excel(model3_file)
model4 = pd.read_excel(model4_file)
model5 = pd.read_excel(model5_file)
model6 = pd.read_excel(model6_file)

model1.head()
```

```python
def is_significant(value: float):
    if value < 0.01:
        return("^{***}")
    elif value < 0.05:
        return("^{**}")
    elif value < 0.1:
        return("^{*}")
    else: 
        return("")
    
is_significant(0.06)
```

```python
def create_column(data: pd.DataFrame):
    results = {}
    for _, row in data.iterrows():
        test = {}
        name = row['Unnamed: 0']
        value = "$\makecell{" + str(round(row['b'], 2)) + is_significant(row['pvalue']) + "\\\\(" + str(round(row['se'], 2)) + ")}$"
        results[name] = value
    return(results)
```

```python
def create_table(results: list):
    table = []
    for result in results:
        column = create_column(result)
        table.append(column)
    return pd.DataFrame(table).transpose()
```

## Results 1

```python
results1 = create_table([model1, model2, model3])
results1.head()
```

```python
first_columns1 = results1.index.values[:18]
first_columns1
```

```python
year_cols1 =  results1.index.values[20:]
year_cols1
```

```python
results1 = results1.reindex(list(first_columns1) + list(year_cols1) + ['_cons'])
results1
```

```python
sample_size = {'Model 1': [69, 401, 0.33, 0.30, 0.34], 'Model 2': [70, 474, 0.32, 0.43, 0.42], 'Model 3': [69, 401, 0.33, 0.30, 0.33]}
sample_size= pd.DataFrame(data=sample_size)
sample_size
```

```python
results1.columns = ['Model 1', 'Model 2', 'Model 3']
results1 = pd.concat([results1, sample_size])

results1_names = ["Adjustments", "Adjustments sq.", "Miles add", "Consolidation", "M and A", "M and A t-1", 
                  "Miles Crude", "Age Crude", "Miles x Age Crude", "Miles HVL", "Age HVL", "Miles x Age HVL", "Miles Non-HVL", 
                  "Age Non-HVL", "Miles x Age Non-HVL", "No Crude", "No HVL", "No Non-HVL", "2007", "2008", "2009", "2010", "2011", "2012",
                  "Constant", "Groups", "Observations", "R-sq within", "R-sq between", "R-sq overall"]
results1.index = results1_names
```

```python
results1.to_latex("../drafts/summer_paper/illustrations/results1.tex", na_rep="", escape=False)
```

## Results 2

```python
results2 = create_table([model4, model5, model6])
```

```python
first_columns2 = results2.index.values[:30]
first_columns2
```

```python
year_cols2 =  results2.index.values[32:]
year_cols2
```

```python
results2 = results2.reindex(list(first_columns2) + list(year_cols2) + ['_cons'])
results2
```

```python
sample_size2 = {'Model 4': [69, 401, 0.75, 0.20, 0.21], 'Model 5': [78, 624, 0.62, 0.30, 0.30], 'Model 6': [69, 401, 0.76, 0.19, 0.20]}
sample_size2 = pd.DataFrame(data=sample_size2)
sample_size2
```

```python
results2.columns = ['Model 4', 'Model 5', 'Model 6']
results2 = pd.concat([results2, sample_size2])

results2_names = ["Adjustments", "Adjustments sq.", "Miles add", "Consolidation", "M and A", "M and A t-1", "Miles Crude 1940s", 
                  "Miles Crude 1950s", "Miles Crude 1960s", "Miles Crude 1970s", "Miles Crude 1980s", "Miles Crude 1990s", 
                  "Miles Crude 2000s", "Miles Crude 2010s", "Miles HVL 1940s", "Miles HVL 1950s", "Miles HVL 1960s", "Miles HVL 1970s", 
                  "Miles HVL 1980s", "Miles HVL 1990s", "Miles HVL 2000s", "Miles HVL 2010s", "Miles Non-HVL 1940s", "Miles Non-HVL 1950s", 
                  "Miles Non-HVL 1960s", "Miles Non-HVL 1970s", "Miles Non-HVL 1980s", "Miles Non-HVL 1990s", "Miles Non-HVL 2000s",
                  "Miles Non-HVL 2010s", "2007", "2008", "2009", "2010", "2011", "2012", "Constant", "Groups", "Observations", 
                  "R-sq within", "R-sq between", "R-sq overall"]
results2.index = results2_names
```

```python
results2.to_latex("../drafts/summer_paper/illustrations/results2.tex", na_rep="", escape=False)
```
