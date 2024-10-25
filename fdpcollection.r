library(dplyr)
library(selenider)

# Start the session
session <- selenider_session("chromote", timeout = 10)

# Open the FDP blog article overview page
open_url("https://www.fdp.de/uebersicht/artikel")

# Handle the cookie banner if it appears (check if it is present)
cookiebanner <- s('#consent-overlay-submit-all')

# Check if the cookie banner is present before clicking
if (elem_wait_until(cookiebanner, is_present, timeout = 5)) {
  elem_click(cookiebanner)
  reload()
}

# Initialize a data frame to store blog links, titles, and dates
all_blog_info <- data.frame(link = character(), title = character(), date = character(), summary = character(), stringsAsFactors = FALSE)

# Loop for 10 pages
for (i in 1:10) {
  
  # Extract all articles (each one wraps around the `a` tag that contains the link and other info)
  articles <- ss("a.mode-search")  # This returns multiple articles
  
  # Check if articles were found
  if (length(articles) == 0) {
    cat("No articles found on page", i, "\n")
    next
  }
  
  # Loop through each article and extract the URL, title, date, and summary
  article_info <- lapply(articles, function(article) {
    
    tryCatch({
      # Extract the URL from the href attribute
      url <- elem_attr(article, "href")
      
      # Extract the title from the h3 element within the article
      title_elem <- find_element(article, "h3")
      title <- elem_text(title_elem)
      
      # Extract the date from the time element within the article
      date_elem <- find_element(article, "time")
      date <- elem_attr(date_elem, "datetime")
      
      # Extract the summary from the p element within the article
      summary_elem <- find_element(article, "p")
      summary <- elem_text(summary_elem)
      
      # Return as a list
      return(c(link = url, title = title, date = date, summary = summary))
      
    }, error = function(e) {
      cat("Error extracting data on page", i, ": ", e$message, "\n")
      return(c(link = NA, title = NA, date = NA, summary = NA))  # Return NA if there is an error
    })
  })
  
  # Combine the article info into a data frame (remove stringsAsFactors argument)
  page_info <- do.call(rbind.data.frame, article_info)
  
  # Add this page's articles to the overall data frame
  all_blog_info <- bind_rows(all_blog_info, page_info)
  
  # Scroll to and click the "Next" button to go to the next page
  next_button <- s("a[rel='next']")
  
  # Check if the "Next" button is present
  if (!elem_wait_until(next_button, is_present, timeout = 5)) {
    cat("No 'Next' button found on page", i, "\n")
    break  # Stop if there is no next button
  }
  
  # Scroll to the button before clicking
  elem_scroll_to(next_button)
  
  # Click the "Next" button
  elem_click(next_button)
  
  # Wait for the page to load (adjust as needed)
  Sys.sleep(3)
}

# Show the dataframe with all articles, titles, dates, and summaries
print(all_blog_info)