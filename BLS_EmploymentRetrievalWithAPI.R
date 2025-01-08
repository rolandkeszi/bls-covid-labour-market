# Load required packages
library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(glue)

# Insert API Key
api_key <- "_____API_Key_____"

# API URL
url <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"

# Payload body
payload <- glue('{
  "seriesid":["LNS12300000"],
  "startyear":"2010",
  "endyear":"2024",
  "registrationkey":"{{api_key}}"
}', .open = "{{", .close = "}}")

# POST request
response <- POST(
  url = url,
  body = payload,
  content_type("application/json"),
  encode = "json"
)

# Convert JSON to list
x <- content(response, "text") %>% fromJSON()

# Create tibble (w/ data cleaning)
if (!is.null(x$Results$series$data)) {
  df <- x$Results$series$data[[1]] %>% as_tibble()
  
  # Convert 'year' and 'period' into a datetime column
  df <- df %>%
    mutate(
      datetime = as.Date(paste0(year, "-", substr(period, 2, 3), "-01")),
      value = as.numeric(value)
    ) %>%
    arrange(datetime)
  
  # Print first few rows of the dataframe
  print(head(df))
  
  # Plot the data
  ggplot(df, aes(x = datetime, y = value)) +
    geom_line(color = "blue") +
    geom_point(color = "red") +
    labs(
      title = "Time Series Values of Employment from BLS API",
      x = "Date",
      y = "Value"
    ) +
    theme_minimal()
} else {
  cat("No data found in the response.\n")
}
