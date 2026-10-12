# US labour market and the COVID-19 shock
# Pulls monthly series from the BLS Public Data API, tidies them and plots
# small multiples with the Feb-Apr 2020 recession shaded.

# Load required packages
library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(readr)
library(ggplot2)

# API key: optional, read from the environment (never hard-code it).
# Without a key the API falls back to v1 limits (10 years per request, 25 requests per day).
api_key <- Sys.getenv("BLS_API_KEY")
api_version <- if (nzchar(api_key)) "v2" else "v1"
url <- sprintf("https://api.bls.gov/publicAPI/%s/timeseries/data/", api_version)

series <- tibble::tribble(
  ~series_id,      ~label,
  "LNS14000000",   "Unemployment rate (%)",
  "LNS12300000",   "Employment-population ratio (%)",
  "CES0000000001", "Total nonfarm payrolls (millions)"
)

start_year <- 2015
end_year <- as.integer(format(Sys.Date(), "%Y"))

# One POST request for one window of years
fetch_window <- function(from, to) {
  body <- list(
    seriesid = series$series_id,
    startyear = as.character(from),
    endyear = as.character(to)
  )
  if (nzchar(api_key)) body$registrationkey <- api_key

  response <- POST(url, body = body, encode = "json")
  stop_for_status(response)
  x <- content(response, "text", encoding = "UTF-8") %>% fromJSON()
  if (x$status != "REQUEST_SUCCEEDED") stop(paste(x$message, collapse = " "))

  map2_dfr(x$Results$series$seriesID, x$Results$series$data, function(id, d) {
    as_tibble(d) %>%
      select(year, period, value) %>%
      mutate(series_id = id)
  })
}

# The API caps the span of one request, so split the period into 10-year windows
windows <- tibble(from = seq(start_year, end_year, by = 10)) %>%
  mutate(to = pmin(from + 9, end_year))

raw <- pmap_dfr(windows, fetch_window)

# Tidy: monthly periods only, numeric values, real dates
df <- raw %>%
  filter(grepl("^M(0[1-9]|1[0-2])$", period), value != "-") %>%
  mutate(
    date = as.Date(paste0(year, "-", substr(period, 2, 3), "-01")),
    value = as.numeric(value)
  ) %>%
  distinct(series_id, date, .keep_all = TRUE) %>%
  arrange(series_id, date)

dir.create("data", showWarnings = FALSE)
write_csv(df %>% select(series_id, date, value), "data/bls_series.csv")

# Payrolls are reported in thousands; plot them in millions
df <- df %>%
  mutate(value = if_else(series_id == "CES0000000001", value / 1000, value)) %>%
  left_join(series, by = "series_id")

# Key figures of the shock
payroll <- df %>% filter(series_id == "CES0000000001")
feb20 <- payroll$value[payroll$date == as.Date("2020-02-01")]
apr20 <- payroll$value[payroll$date == as.Date("2020-04-01")]
recovered <- payroll %>%
  filter(date > as.Date("2020-04-01"), value >= feb20) %>%
  slice(1) %>%
  pull(date)
cat(sprintf("Jobs lost Feb-Apr 2020: %.1f million\n", feb20 - apr20))
cat(sprintf("Payrolls back at the Feb 2020 level: %s\n", format(recovered, "%b %Y")))

# Trough markers for the annotation
troughs <- df %>%
  filter(date == as.Date("2020-04-01")) %>%
  mutate(text = sprintf("%.1f · Apr 2020", value))

p <- ggplot(df, aes(date, value)) +
  annotate("rect",
    xmin = as.Date("2020-02-01"), xmax = as.Date("2020-04-01"),
    ymin = -Inf, ymax = Inf, fill = "#eaeef2"
  ) +
  geom_line(color = "#2a78d6", linewidth = 0.8) +
  geom_point(data = troughs, color = "#e34948", size = 2.5) +
  geom_text(data = troughs, aes(label = text), hjust = -0.1, size = 3.3, fontface = "bold") +
  facet_wrap(~label, ncol = 1, scales = "free_y") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = "The COVID-19 shock in the US labour market",
    subtitle = "Monthly, seasonally adjusted. Shaded band: NBER recession, Feb-Apr 2020",
    caption = "Source: U.S. Bureau of Labor Statistics, Public Data API",
    x = NULL, y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    strip.text = element_text(face = "bold", hjust = 0),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  )

print(p)
dir.create("assets", showWarnings = FALSE)
ggsave("assets/covid-labour-market-ggplot.png", p, width = 10, height = 9, dpi = 150)
