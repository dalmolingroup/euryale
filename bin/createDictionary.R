#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_file <- args[1]
genbank_file <- args[2]
refseq_file <- args[3]
threads <- args[4]

library(dplyr)
library(tidyr)
library(data.table)

fixCollapsed <- function(df){
    colnames(df) <- c("key", "value")
    df <- df %>%
        mutate(key = strsplit(key, "; ")) %>%
        unnest(key)
    df <- df[, c(2, 1)]
    return(df)
}
fixDuplicated <- function(df){
    df <- df %>%
        group_by(key) %>%
        summarise(value = paste(value, collapse = "; "))
    values <- strsplit(df$value, "; ")
    values <- lapply(values, unique)
    values <- sapply(values, paste, collapse = "; ")
    df$value <- values
    return(df)
}
removeUnknown <- function(df){
    idx <- grepl("^-", df$key)
    df <- df[!idx,]
    return(df)
}
df <- fread(genbank_file, stringsAsFactors = FALSE,
    head = FALSE, nThread = as.integer(threads))
df <- as.data.frame(df)
df %>%
    fixCollapsed() %>%
    fixDuplicated() %>%
    removeUnknown() %>%
    fwrite(file = out_file, sep = "\t",
        nThread = as.integer(threads))
df <- fread(refseq_file, stringsAsFactors = FALSE,
    head = FALSE, nThread = as.integer(threads))
df <- as.data.frame(df)
df %>%
    fixCollapsed() %>%
    fixDuplicated() %>%
    removeUnknown() %>%
    fwrite(file = out_file, sep = "\t",
        append = TRUE, nThread = as.integer(threads))
