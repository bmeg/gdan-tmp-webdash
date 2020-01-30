library(DBI)
library(dplyr)
library(tidyr)

feature_files <- list.files("./v7-matrices/", ".tsv", full.names = T)

con <- dbConnect(RSQLite::SQLite(), "./features_by_cancer.sqlite")

i <- 1
for (f in feature_files) {
  message("processing file: ", i, "/", length(feature_files))
  cancer_id <- strsplit(basename(f), "_")[[1]][1] 
  data <- data.table::fread(f) %>%
    as_tibble() %>%
    rename(sample_id = 1) %>%
    mutate(subtype = paste(cancer_id, Labels, sep=":")) %>% 
    select(-Labels) %>%
    gather(-sample_id, -subtype, key = "feature_id", value = "value") %>%
    select(feature_id, sample_id, subtype, value)
  copy_to(con, data, cancer_id, temporary = FALSE, overwrite = TRUE,
          indexes = list("feature_id"))
  i <- i + 1
}

i <- 1
for (f in feature_files) {
  message("processing file: ", i, "/", length(feature_files))
  cancer_id <- strsplit(basename(f), "_")[[1]][1]
  features <- data.table::fread(f, nrow=0) %>%    
    colnames()
  copy_to(con, tibble(feature_id = features[3:length(features)]), sprintf("%s_features", cancer_id), temporary = FALSE, overwrite = TRUE)
  i <- i + 1
}

## con <- dbConnect(RSQLite::SQLite(), "./features.sqlite")
## i <- 1
## for (f in feature_files) {
##   message("processing file: ", i, "/", length(feature_files))
##   cancer_id <- strsplit(basename(f), "_")[[1]][1] 
##   data <- data.table::fread(f) %>%
##     as_tibble() %>%
##     rename(sample_id = 1) %>%
##     mutate(subtype = paste(cancer_id, Labels, sep=":"),
##            cancer_id = cancer_id) %>% 
##     select(-Labels) %>%
##     gather(-sample_id, -cancer_id, -subtype, key = "feature_id", value = "value") %>%
##     select(feature_id, cancer_id, sample_id, subtype, value)
##   if (i == 1) {
##       copy_to(con, data, "features", temporary = FALSE, overwrite = TRUE,
##               indexes = list("feature_id", "cancer_id"))
##   } else {
##       dbWriteTable(con, "features", data, overwrite = FALSE, append = TRUE)
##   }
##   i <- i + 1
## }