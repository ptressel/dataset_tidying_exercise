# Computes ...
# Requires packages:
# - stringr
# - data.table
# - reshape2
# Usage:
# - Download the dataset from:
#   https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
# - Unzip it. This should yield a directory called "UCI HAR Dataset".
# - Set working directory to that direcotry, so that the test and train
#   directories are in the working directory.
# - Run this script.
# - Output is written to subject_activity_mean_std.csv

# Verify presence of required packages.
if (!require(stringr) |
    !require(data.table) |
    !require(reshape2)) {
    stop("Please install these packages: stringr, data.table, reshape2")
}

# Verify presence of files.
if (!file.exists("activity_labels.txt") |
    !file.exists("features.txt") |
    !file.exists("test/subject_test.txt") |
    !file.exists("test/X_test.txt") |
    !file.exists("test/y_test.txt") |
    !file.exists("train/subject_train.txt") |
    !file.exists("train/X_train.txt") |
    !file.exists("train/y_train.txt")) {
    stop("Please change directory into the UCI HAR Dataset directory.")
}

# Read the feature column numbers and names.
features <- fread(
    "features.txt",
    sep = " ",
    header = FALSE
    )
setnames(features, c("index", "name"))

# Preserve the original number of features as we'll need it later while reading
# in the feature vectors.
num.all.features <- nrow(features)

# Select out only those containing "-mean()" or "-std()".
features <- features[grepl("(-mean\\(\\)|-std\\(\\))", features$name),]

# The feature names encode information about the corresponding measurement.
# The names will be parsed to extract this information.  This will be used
# later to assist in restructuring the data, and in constructing readable
# column names.

# The strings in quotes are substrings of the feature names that provide each
# component of the information in the feature name:
# domain: "t" (time-based) or "f" (frequency-domain)
# driver (i.e. what caused this motion): "Body" or "Gravity"
# device: "Acc" (accelerometer) or "Gyro" (gyroscope)
# jerk (whether the motion was a jerk): "Jerk"
# direction of the measurment: "X", "Y", or "Z", or "Mag" (magnitude)
# statistic: "mean" or "std"
feature.pattern <- "(t|f)(Body|Gravity)(Body)?(Acc|Gyro)(Jerk)?(Mag)?-(mean|std)\\(\\)-?(X|Y|Z)?"

# That regular expression will capture 9 parts out of the original feature name.
# After some rearranging, these parts are the ones we'll keep --
parts.to.extract <- list(
    domain = 2,    # time, frequency
    driver = 3,    # body, gravity
    device = 5,    # accelerometer, gyroscope
    jerk = 6,      # TRUE if jerk, FALSE if not
    direction = 7, # x, y, z, or magnitude
    statistic = 8  # mean, std
    )
# For efficiency, get the indices in a vector.
parts.indices <- unlist(parts.to.extract)

# Uniform, unabbreviated names or values for each feature component's value.
part.meanings <- list(
    f = "frequency",
    t = "time",
    Body = "body",
    Gravity = "gravity",
    Acc = "accelerometer",
    Gyro = "gyroscope",
    Jerk = "jerk",     # Will be replaced by TRUE
    NoJerk = "nojerk", # Will be replaced by FALSE
    Mag = "magnitude",
    X = "x",
    Y = "y",
    Z = "z",
    mean = "mean",
    std = "std"
    )
jerk.value <- list(
    "jerk" = TRUE,
    "nojerk" = FALSE
    )

# Helper function to extract the feature parts.
extract.feature.parts <- function(feature.name) {
    parts <- str_match_all(feature.name, feature.pattern)
    parts <- parts[[1]][1,]
    # X, Y, Z are mutually exclusive with Mag -- combine them.
    if (parts[7] == "") parts[7] <- parts[9]
    # If Jerk isn't present, set an alternate key.
    if (parts[6] == "") parts[6] <- "NoJerk"
    # Pick out the parts to replace.
    parts.before <- parts[parts.indices]
    # Get the extracted and renamed parts in a list.
    parts.after <- part.meanings[parts.before]
    # Set names to the component names.
    names(parts.after) <- names(parts.to.extract)
    # Construct a column name to be applied when reading in the feature
    # vectors.  (This is not going to be exposed externally, but can be useful
    # while debugging.)
    name.after <- paste(parts.after, collapse = ".")
    # Insert the name in the results.
    parts.after$new.name <- name.after
    # For the name, we used "jerk" and "nojerk", but for the actual value of
    # the jerk component, we want TRUE and FALSE.
    parts.after$jerk <- jerk.value[parts.after$jerk]
    parts.after
}

# Extract the meanings from the feature names.
features.meaning <- lapply(features$name, extract.feature.parts)

# Add these into the table of features.
features.domain <- unlist(sapply(features.meaning, "[", "domain"))
features[, domain := features.domain]
features.driver <- unlist(sapply(features.meaning, "[", "driver"))
features[, driver := features.driver]
features.device <- unlist(sapply(features.meaning, "[", "device"))
features[, device := features.device]
features.jerk <- unlist(sapply(features.meaning, "[", "jerk"))
features[, jerk := features.jerk]
features.direction <- unlist(sapply(features.meaning, "[", "direction"))
features[, direction := features.direction]
features.statistic <- unlist(sapply(features.meaning, "[", "statistic"))
features[, statistic := features.statistic]
features.new.name <- unlist(sapply(features.meaning, "[", "new.name"))
features[, new.name := features.new.name]

# Read the test and train feature vectors and discard all but the mean and
# std columns.
#
# Note:  One cannot use fread from the data.table package for this, as
# attempting to read the feature vector data with fread consistently crashes
# both RStudio and RGui.  So instead...
#
# read.fwf will be used to read the feature vectors.  Each column is 16
# characters wide.  read.fwf takes a vector of column widths.  If a width is
# negative, it skips that many characters, so this can be used to skip the
# non-mean, non-std columns.  So construct a vector of column widths that has
# -16 for each column to skip, and 16 for each column to keep.
column.widths <- rep(-16, num.all.features)
column.widths[features$index] = 16
feature.vectors.test.df <- read.fwf(
    "test/X_test.txt",
    widths = column.widths,
    header = FALSE,
    col.names = features$new.name
    )
feature.vectors.test <- data.table(feature.vectors.test.df)
feature.vectors.train.df <- read.fwf(
    "train/X_train.txt",
    widths = column.widths,
    header = FALSE,
    col.names = features$new.name
    )
feature.vectors.train <- data.table(feature.vectors.train.df)

# We want to group by subject and activity.  Put these in a separate
# data.table, so they don't interfere with aggregate().

# Read the subject ids.
groupby.test <- fread(
    "test/subject_test.txt",
    header = FALSE)
setnames(groupby.test, c("subject"))
groupby.train <- fread(
    "train/subject_train.txt",
    header = FALSE)
setnames(groupby.train, c("subject"))

# The activity names are uppercase and contain underscores -- we'll convert
# them to the same form as the other labels we're using, lowercase and dot
# separated.
standardize.activity.name <- function(activity.name) {
    tolower(gsub("_", ".", activity.name))
}

# Read the activity names.
activity.names <- fread(
    "activity_labels.txt",
    header = FALSE)
setnames(activity.names, c("number", "name"))
# Convert them.
activity.names[, new.name := sapply(activity.names$name, standardize.activity.name, USE.NAMES=FALSE)]
# For convenience, put the new names in a vector indexed by the activity number.
num.activities <- max(activity.names$number)
activity.number.to.name <- rep("none", num.activities)
for (i in 1:nrow(activity.names)) {
    activity.number.to.name[activity.names$number] <- activity.names$new.name
}

# Read the activity outcomes.
activities.test <- fread(
    "test/y_test.txt",
    header = FALSE)
setnames(activities.test, c("activity.number"))
activities.train <- fread(
    "train/y_train.txt",
    header = FALSE)
setnames(activities.train, c("activity.number"))

# Attach the activites to the subjects.  Use activity names instead of
# numbers.
groupby.test[, activity := activity.number.to.name[activities.test$activity.number]]
groupby.train[, activity := activity.number.to.name[activities.train$activity.number]]

# Combine the test and train datasets.
feature.vectors <- rbindlist(
    list(feature.vectors.train, feature.vectors.test),
    use.names = TRUE)
groupby <- rbindlist(
    list(groupby.train, groupby.test),
    use.names = TRUE)

# Group by subject and activity, and compute mean and std of each feature.
subject.activity.mean <- aggregate(
    feature.vectors,
    by = list(subject = groupby$subject, activity = groupby$activity),
    mean)
subject.activity.std <- aggregate(
    feature.vectors,
    by = list(subject = groupby$subject, activity = groupby$activity),
    sd)

# At this point, we have one row for each subject and activity pair,
# with every feature's mean and standard deviation.  Instead, would like
# to have a row per subject, activity, and feature, with the mean and
# standard deviation of that feature.  And rather than denoting the
# feature by a cryptic name, include the components of the feature.

# First, melt the two tables so that they are indexed by subject,
# activity, *and feature*.  That means the statistics we computed are
# *grouped by* subject, activity, and feature.
subject.activity.feature.mean.df <- melt(
    subject.activity.mean,
    id.vars = c("subject", "activity"),
    variable.name = "feature",
    value.name = "mean")
subject.activity.feature.mean.df$feature <- as.character(subject.activity.feature.mean.df$feature)
subject.activity.feature.mean <- data.table(subject.activity.feature.mean.df)
subject.activity.feature.std.df <- melt(
    subject.activity.std,
    id.vars = c("subject", "activity"),
    variable.name = "feature",
    value.name = "standard.deviation")
subject.activity.feature.std.df$feature <- as.character(subject.activity.feature.std.df$feature)
subject.activity.feature.std <- data.table(subject.activity.feature.std.df)

# Join the tables, so we have columns subject, activity, feature,
# mean, standard.deviation.
subject.activity.feature.stats <- merge(
    subject.activity.feature.mean,
    subject.activity.feature.std,
    by = c("subject", "activity", "feature"))

# Include columns for the components of each feature.  This extracts the
# information encoded in the original feature names, and makes it available
# for use in analysis.  It also provides a human-readable interpretation of
# each feature.
# Note that a data.table simply does not work for this operation -- it
# returns an entire data.table if one attempts logical row indexing, even if
# with=False is specified.
features.df <- data.frame(features)
extract.component.by.feature.name <- function(new.name, component) {
    features.df[features.df$new.name == new.name, component]
}

# Index the table of feature components by the feature names in the melted
# table to extract the component value that goes with each feature.
# Insert these in the result table.

components.domain <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "domain", USE.NAMES=FALSE)
subject.activity.feature.stats[, domain := components.domain]
components.driver <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "driver", USE.NAMES=FALSE)
subject.activity.feature.stats[, driver := components.driver]
components.device <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "device", USE.NAMES=FALSE)
subject.activity.feature.stats[, device := components.device]
components.jerk <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "jerk", USE.NAMES=FALSE)
subject.activity.feature.stats[, jerk := components.jerk]
components.direction <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "direction", USE.NAMES=FALSE)
subject.activity.feature.stats[, direction := components.direction]
components.statistic <- sapply(subject.activity.feature.stats$feature, extract.component.by.feature.name, "statistic", USE.NAMES=FALSE)
subject.activity.feature.stats[, statistic := components.statistic]

# Rearrange the columns so that the main index columns (subject, activity)
# are first, followed by the feature components, and finally the statistics.
setcolorder(subject.activity.feature.stats,
    c("subject", "activity", "feature",
      "domain", "driver", "device", "jerk", "direction", "statistic",
      "mean", "standard.deviation"))
# We no longer need the feature name.
subject.activity.feature.stats <- subject.activity.feature.stats[, !"feature", with = FALSE]

# Write out the tidied dataset.
write.table(
    subject.activity.feature.stats,
    file = "subject_activity_mean_std.csv",
    sep = ",",
    row.names = FALSE)