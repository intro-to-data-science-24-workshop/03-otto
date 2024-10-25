library(dplyr)
library(selenider)
library(knitr)
library(kableExtra)

# Start the session
session <- selenider_session("chromote", timeout = 10)

# Open the FDP blog article overview page
open_url("https://www.fdp.de/uebersicht/artikel")

# Handle the cookie banner if it appears (check if it is present)
cookiebanner <- s("#consent-overlay-submit-all")

# Check if the cookie banner is present before clicking
if (elem_wait_until(cookiebanner, is_present, timeout = 5)) {
  elem_click(cookiebanner)
  reload()
}

# Initialize a data frame to store blog links, titles, dates, and summaries
all_blog_info <- data.frame(
  link = character(),
  title = character(),
  date = character(),
  summary = character(),
  stringsAsFactors = FALSE
)

# Loop for 3 pages (adjust as needed)
for (i in 1:3) {
  # Wait for articles to be present
  elem_wait_until(s("a.mode-search"), is_present, timeout = 10)

  # Extract all articles
  articles <- ss("a.mode-search")

  # Check if articles were found
  if (length(articles) == 0) {
    break # Stop if no articles are found
  }

  # Initialize a list to store article information
  article_info <- list()

  # Loop through each article and extract information
  for (j in seq_along(articles)) {
    article <- articles[[j]]

    info <- tryCatch(
      {
        # Extract the URL
        url <- elem_attr(article, "href")

        # Extract the title
        title_elem <- find_element(article, "h3")
        title <- if (elem_wait_until(title_elem, is_present, timeout = 5)) elem_text(title_elem) else NA

        # Extract the date
        date_elem <- find_element(article, "time")
        date <- if (elem_wait_until(date_elem, is_present, timeout = 5)) elem_attr(date_elem, "datetime") else NA

        # Extract the summary
        summary_elem <- find_element(article, "p")
        summary <- if (elem_wait_until(summary_elem, is_present, timeout = 5)) elem_text(summary_elem) else NA

        # Return as a named list
        list(link = url, title = title, date = date, summary = summary)
      },
      error = function(e) {
        # Return NA values in case of error
        list(link = NA, title = NA, date = NA, summary = NA)
      }
    )

    # Append the info to the list
    article_info[[j]] <- info
  }

  # Combine the article info into a data frame
  page_info <- bind_rows(article_info)

  # Add this page's articles to the overall data frame
  all_blog_info <- bind_rows(all_blog_info, page_info)

  # Attempt to select the "Next" button
  next_button <- s("a[rel='next']")

  # Check if the "Next" button is present before clicking
  if (!elem_wait_until(next_button, is_present, timeout = 5)) {
    break # Stop if there is no next button
  }

  # Scroll to the "Next" button before clicking
  elem_scroll_to(next_button)

  # Click the "Next" button
  elem_click(next_button)

  # Wait for the next page to load
  elem_wait_until(s("a.mode-search"), is_present, timeout = 10)
}

# Display the data frame as a nice knitr table
kable(all_blog_info, caption = "FDP Blog Articles") %>%
  kable_styling(full_width = FALSE)
