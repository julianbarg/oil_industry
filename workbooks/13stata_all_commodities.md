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
    display_name: Stata
    language: stata
    name: stata
---

# 13. Modeling (Stata) - all commodities


## Setup

```stata
use "../stata_data/sample_combined_2019-09-16.dta"
```

```stata
local date : di  %tdCY-N-D  daily("$S_DATE", "DMY")
```

```stata
ds
```

```stata
xtset OPERATOR_ID YEAR
```

## 13.2 Total SD

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ DISC_ADDED CONSOLIDATE M_A M_A_2 CRUDE_MILES_3 CRUDE_AVG_AGE_3 CRUDExAGE ///
HVL_MILES_3 HVL_AVG_AGE_3 HVLxAGE NON_HVL_MILES_3 NON_HVL_AVG_AGE_3 NON_HVLxAGE NO_CRUDE NO_HVL NO_NON_HVL, fe vce(robust)
```

```stata
putexcel set "../results/model1_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

### Minimalist

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ M_A M_A_2 CRUDE_MILES_3 CRUDE_AVG_AGE_3 CRUDExAGE ///
HVL_MILES_3 HVL_AVG_AGE_3 HVLxAGE NON_HVL_MILES_3 NON_HVL_AVG_AGE_3 NON_HVLxAGE NO_CRUDE NO_HVL NO_NON_HVL, fe vce(robust)
```

```stata
putexcel set "../results/model2_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

### With year

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ i.YEAR DISC_ADDED CONSOLIDATE M_A M_A_2 CRUDE_MILES_3 CRUDE_AVG_AGE_3 CRUDExAGE ///
HVL_MILES_3 HVL_AVG_AGE_3 HVLxAGE NON_HVL_MILES_3 NON_HVL_AVG_AGE_3 NON_HVLxAGE NO_CRUDE NO_HVL NO_NON_HVL, fe vce(robust)
```

```stata
putexcel set "../results/model3_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

## 13.1.2 Extended model

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ DISC_ADDED CONSOLIDATE M_A M_A_2 CRUDE_MILES_1940_3 CRUDE_MILES_1950_3 CRUDE_MILES_1960_3 CRUDE_MILES_1970_3 ///
      CRUDE_MILES_1980_3 CRUDE_MILES_1990_3 CRUDE_MILES_2000_3 CRUDE_MILES_2010_3 HVL_MILES_1940_3 HVL_MILES_1950_3 HVL_MILES_1960_3 ///
      HVL_MILES_1970_3 HVL_MILES_1980_3 HVL_MILES_1990_3 HVL_MILES_2000_3 HVL_MILES_2010_3 NON_HVL_MILES_1940_3 ///
      NON_HVL_MILES_1950_3 NON_HVL_MILES_1960_3 NON_HVL_MILES_1970_3 NON_HVL_MILES_1980_3 NON_HVL_MILES_1990_3 ///
      NON_HVL_MILES_2000_3 NON_HVL_MILES_2010_3, fe vce(robust)
```

```stata
putexcel set "../results/model4_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

### Minimalist

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ M_A M_A_2 CRUDE_MILES_1940_3 CRUDE_MILES_1950_3 CRUDE_MILES_1960_3 CRUDE_MILES_1970_3 ///
      CRUDE_MILES_1980_3 CRUDE_MILES_1990_3 CRUDE_MILES_2000_3 CRUDE_MILES_2010_3 HVL_MILES_1940_3 HVL_MILES_1950_3 HVL_MILES_1960_3 ///
      HVL_MILES_1970_3 HVL_MILES_1980_3 HVL_MILES_1990_3 HVL_MILES_2000_3 HVL_MILES_2010_3 NON_HVL_MILES_1940_3 ///
      NON_HVL_MILES_1950_3 NON_HVL_MILES_1960_3 NON_HVL_MILES_1970_3 NON_HVL_MILES_1980_3 NON_HVL_MILES_1990_3 ///
      NON_HVL_MILES_2000_3 NON_HVL_MILES_2010_3, fe vce(robust)
```

```stata
putexcel set "../results/model5_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

### With year

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ i.YEAR DISC_ADDED CONSOLIDATE M_A M_A_2 CRUDE_MILES_1940_3 CRUDE_MILES_1950_3 CRUDE_MILES_1960_3 CRUDE_MILES_1970_3 ///
      CRUDE_MILES_1980_3 CRUDE_MILES_1990_3 CRUDE_MILES_2000_3 CRUDE_MILES_2010_3 HVL_MILES_1940_3 HVL_MILES_1950_3 HVL_MILES_1960_3 ///
      HVL_MILES_1970_3 HVL_MILES_1980_3 HVL_MILES_1990_3 HVL_MILES_2000_3 HVL_MILES_2010_3 NON_HVL_MILES_1940_3 ///
      NON_HVL_MILES_1950_3 NON_HVL_MILES_1960_3 NON_HVL_MILES_1970_3 NON_HVL_MILES_1980_3 NON_HVL_MILES_1990_3 ///
      NON_HVL_MILES_2000_3 NON_HVL_MILES_2010_3, fe vce(robust)
```

```stata
putexcel set "../results/model6_`date'.xlsx", replace
```

```stata
matrix D = r(table)'
```

```stata
putexcel A1 = matrix(D), names
```

## 13.3 Hausman test

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ DISC_ADDED CONSOLIDATE CRUDE_MILES_1940_3 CRUDE_MILES_1950_3 CRUDE_MILES_1960_3 CRUDE_MILES_1970_3 ///
      CRUDE_MILES_1980_3 CRUDE_MILES_1990_3 CRUDE_MILES_2000_3 CRUDE_MILES_2010_3 HVL_MILES_1940_3 HVL_MILES_1950_3 HVL_MILES_1960_3 ///
      HVL_MILES_1970_3 HVL_MILES_1980_3 HVL_MILES_1990_3 HVL_MILES_2000_3 HVL_MILES_2010_3 NON_HVL_MILES_1940_3 ///
      NON_HVL_MILES_1950_3 NON_HVL_MILES_1960_3 NON_HVL_MILES_1970_3 NON_HVL_MILES_1980_3 NON_HVL_MILES_1990_3 ///
      NON_HVL_MILES_2000_3 NON_HVL_MILES_2010_3, fe
```

```stata
estimate store fixed
```

```stata
xtreg INC_3 CHANGE_SD CHANGE_SD_SQ  DISC_ADDED CONSOLIDATE CRUDE_MILES_1940_3 CRUDE_MILES_1950_3 CRUDE_MILES_1960_3 CRUDE_MILES_1970_3 ///
      CRUDE_MILES_1980_3 CRUDE_MILES_1990_3 CRUDE_MILES_2000_3 CRUDE_MILES_2010_3 HVL_MILES_1940_3 HVL_MILES_1950_3 HVL_MILES_1960_3 ///
      HVL_MILES_1970_3 HVL_MILES_1980_3 HVL_MILES_1990_3 HVL_MILES_2000_3 HVL_MILES_2010_3 NON_HVL_MILES_1940_3 ///
      NON_HVL_MILES_1950_3 NON_HVL_MILES_1960_3 NON_HVL_MILES_1970_3 NON_HVL_MILES_1980_3 NON_HVL_MILES_1990_3 ///
      NON_HVL_MILES_2000_3 NON_HVL_MILES_2010_3, re
```

```stata
estimate store random
```

```stata
hausman fixed random, sigmamore
```

```stata

```
