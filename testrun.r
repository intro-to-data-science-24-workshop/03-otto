library(selenider)

open_url("https://www.r-project.org/")

s(".row") |>
  find_element("div") |>
  find_elements("a") |>
  elem_find(has_text("CRAN")) |>
  elem_expect(attr_contains("href", "cran.r-project.org")) |>
  elem_click()

s("dl") |>
  find_elements("dt") |>
  elem_find(has_text("UK")) |>
  find_element(xpath = "./following-sibling::dd") |>
  find_elements("tr") |>
  elem_expect(has_at_least(1)) |>
  as.list() |>
  lapply(
    \(x) x |>
      find_element("a") |>
      elem_attr("href")
  )
