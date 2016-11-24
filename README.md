
<!-- README.md is generated from README.Rmd. Please edit that file -->
platforms
=========

All Saccharomyces cerevisiae experimental platforms in the public dabases:
1. Gene Expression Omnibus (GEO) \[cite: <https://doi.org/10.1093/nar/gks1193>\]
2. Array Express (AE) \[cite: <https://doi.org/10.1093/nar/gku1057>\]

### how pkg was created

Create empty repo on github

``` shell
git clone https://github.com/scerden/platforms
Rscript -e 'devtools::create("platforms")'
```

Next steps:

``` r
library(devtools)
use_readme_rmd()
use_data_raw()
```

numbered rscripts to create main platforms tbl
