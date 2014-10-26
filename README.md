---
title: "README.md"
author: "Patricia Tressel"
date: "Saturday, October 25, 2014"
output: html_document
---

This is an exercise in data cleaning.  It starts with an activity recognition dataset available in the UCI machine learning dataset collection:
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

It extracts some statistics from the data as a proxy for a more realistic analysis.  It then reorganizes and relabels the data as a "tidy" dataset.

This is done by the script run_analysis.R.  To try it out, you will need to have R installed, plus the packages stringr, data.table, and reshape2.

Download the dataset from:
https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

Unzip the file.  In it there will be a directory "UCI HAR Dataset".  Change directory into the "UCI HAR Dataset".

Execute the script via RStudio, RGui, or with Rscript on the command line.  It takes no arguments, and writes out the tidied dataset into the file subject_activity_mean_std.csv in the current directory.

For example, if you have the run_analysis.R script in your home directory, ~, on a Linux or OSX system, or Windows with Cygwin:

```
cd "UCI HAR Dataset"
Rscript ~/run_analysis.R

```