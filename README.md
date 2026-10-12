# The COVID-19 shock in the US labour market — BLS API with R

![R](https://img.shields.io/badge/R-276DC3?style=flat-square&logo=r&logoColor=white)
![ggplot2](https://img.shields.io/badge/ggplot2-tidyverse-1A162D?style=flat-square)
![REST API](https://img.shields.io/badge/REST%20API-BLS%20Public%20Data-0969da?style=flat-square)
![Data](https://img.shields.io/badge/data-Jan%202015%20–%20Sep%202026-59636e?style=flat-square)

An end-to-end R pipeline that pulls official labour-market statistics from the **U.S. Bureau of Labor Statistics (BLS) Public Data API**. It tidies the series and charts how deep the COVID-19 shock went and how long the recovery took.

<p align="center">
  <img src="assets/covid-labour-market.svg" width="100%" alt="Three line charts, 2015 to 2026. Unemployment jumped from 3.5% in February 2020 to 14.8% in April 2020 and was back near 4% by May 2022. The employment–population ratio fell from 61.1% to 51.2%. Nonfarm payrolls lost 21.9 million jobs in two months and regained the February 2020 level in June 2022.">
</p>

## Key findings

| Indicator | Feb 2020 (pre-COVID) | Apr 2020 (trough) | Change | Back to pre-COVID level |
|---|---:|---:|---:|---|
| Unemployment rate | 3.5% | **14.8%** | +11.3 pp | May 2022 (≤ 3.6%) |
| Employment–population ratio | 61.1% | **51.2%** | −9.9 pp | Not fully. It peaked near 60.4% and was 59.2% in Sep 2026 |
| Total nonfarm payrolls | 152.3 M | **130.4 M** | **−21.9 M jobs** | **Jun 2022, after 28 months** |

- **The fastest collapse in the series' history:** one in seven US jobs disappeared within two months.
- **Jobs came back faster than people:** payrolls recovered by mid-2022, but the share of the population in work never returned to its 2019 peak. Population ageing and lower participation explain much of the gap.
- **Data quality is part of the story:** the household survey was not conducted in October 2025 because of the federal shutdown. The pipeline keeps the gap rather than interpolating a value.

## What the code does

```text
BLS Public Data API ──► JSON ──► tidy tibble ──► data/bls_series.csv
   (POST, 3 series,            (monthly periods,      │
    10-year windows)            numeric, dates)       └─► ggplot2 small multiples
                                                          + key figures printed to console
```

| Series ID | Measure | Survey |
|---|---|---|
| `LNS14000000` | Unemployment rate, 16+ years, seasonally adjusted | Current Population Survey (households) |
| `LNS12300000` | Employment–population ratio, 16+ years, seasonally adjusted | Current Population Survey (households) |
| `CES0000000001` | Total nonfarm payroll employment, thousands, seasonally adjusted | Current Employment Statistics (establishments) |

Technical points:

- **API limits are handled automatically.** The request is split into 10-year windows, and the script uses v2 when a key is available and falls back to v1 without one.
- **No secret in the code.** The optional API key is read from the `BLS_API_KEY` environment variable.
- **Reproducible output.** A tidy CSV (`series_id, date, value`) is written next to the chart, so the figures can be checked without calling the API.

## Run it

```r
install.packages(c("httr", "jsonlite", "dplyr", "purrr", "readr", "ggplot2", "tibble"))

# optional, for higher API limits: https://data.bls.gov/registrationEngine/
Sys.setenv(BLS_API_KEY = "your-key")

source("BLS_EmploymentRetrievalWithAPI.R")
```

Outputs: `data/bls_series.csv`, `assets/covid-labour-market-ggplot.png`, and the key figures printed to the console.

## Repository structure

```text
├── BLS_EmploymentRetrievalWithAPI.R   # fetch → tidy → key figures → chart
├── data/bls_series.csv                # tidy monthly data, Jan 2015 – Sep 2026
└── assets/covid-labour-market.svg     # README figure (adapts to light/dark theme)
```

---

<sub>Data: U.S. Bureau of Labor Statistics, retrieved October 2026. Recession dates: NBER (peak Feb 2020, trough Apr 2020).</sub>
