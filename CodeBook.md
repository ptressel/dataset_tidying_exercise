---
title: "CodeBook.md"
author: "Patricia Tressel"
date: "Saturday, October 25, 2014"
output: html_document
---

This is an exercise in data cleaning and forming a "tidy" dataset.  It uses an activity recognition dataset available in the UCI machine learning dataset collection:
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

This consists of movement features captured from multiple subjects, as each performed any of several activities.  Data are from an accelerometer and gyroscope, from which a large number of features were captured or computed.  The description of the data is on the above page.  This is not detailed, so for actual analysis, it would be appropriate to consult related publications.  What we're concerned with here is the structure of the dataset, and what transformations were needed to tidy it.

It contains three descriptive files:

activity_labels.txt:
List, one per line, of names of activities (all caps, underscores for word breaks).

features.txt:
An unlabeled, space-separated columnar file, with two columns:
* index of each feature in the feature vector files
* descriptive name of the feature

features_info.txt:
Prose description of the sensors, collection of data, and computation of derived features.

Data are divided into a test set and training set.  Each has:

A file of feature vectors, X_test.txt or X_train.txt:
The features are fixed-column-width numbers.

A file of the ground-truth activities for each feature vector, y_test.txt or y_train.txt:
These are numbers that index into the list of activities in activity_labels.txt.

A file of subject id numbers, subject_test.txt, subject_train.txt:
These are numbers assigned to each subject, one per line, corresponding to the feature vector rows.

Points to note about the form of the data:

Each feature vector row contains 561 features for a given observation.  The column labels are the feature labels given in features.txt.  Although lining up all features in rows may be convenient for some automated machine learning systems, it is not very useful for human data exploration -- one can't look at it and pick out interesting relationships, for instance.

The feature labels encode a lot of information about the feature.  In fact, the feature labels are equivalent to key-value pairs that specify the values of multiple properties.  In this exercise, a subset of features are examined -- for these, the feature labels encode six items of information.  Here are some example rows from the features.txt file, showing the form of the labels:

1 tBodyAcc-mean()-X
26 tBodyAcc-arCoeff()-X,1
38 tBodyAcc-correlation()-X,Y
198 tBodyGyroJerk-correlation()-X,Y
210 tBodyAccMag-arCoeff()1
214 tGravityAccMag-mean()
227 tBodyAccJerkMag-mean()
502 fBodyGyro-bandsEnergy()-25,48
504 fBodyAccMag-std()
538 fBodyBodyGyroMag-maxInds
555 angle(tBodyAccMean,gravity)

The subset of features we're dealing with are those that report the mean and standard deviation of collections of measurements.  Extracting a few of those, that show the variety of "values" are encoded in the labels:

tBodyAcc-mean()-X
tBodyAcc-mean()-Y
tBodyAcc-mean()-Z
tBodyGyro-mean()-X
tBodyAccJerk-mean()-X
tGravityAccMag-mean()
tBodyAccJerkMag-mean()
fBodyAccMag-std()

The six components of these feature labels are:

* domain:
  t -> time domain
  f -> frequency domain
* driver:
  Body -> acceleration is due to movement
  Gravity -> acceleration is due to gravity
* device:
  Acc -> accelerometer
  Gyro -> gyroscope
* jerk:
  Jerk -> data at this time indicates an abrupt motion
  [ ] -> absense of this text indicates no abrupt motion
* directionality:
  X -> sensor X measurement
  Y -> sensor Y measurement
  Z -> sensor Z measurement
  Mag -> magnitude of the sensor vector
* statistic:
  mean() -> mean of some set of measurements
  std() -> standard deviation of that set of measurements
  
The information provided by the labels can be restructured to make it easier to understand and use.  The separate items of information they encode can be extracted, each into its own column, with a descriptive property (column) name, and descriptive value names.  This helps in two ways:
* It is more human-understandable.  One does not have to parse a cryptic name.
* It is easier to do analysis involving these properties if the values for each are directly and individually accessible.

As a proxy for actual analysis, the features for "mean()" and "std()" measurements were selected out, grouped by subject and activity, and within those, the mean and standard deviation were computed.

This smaller dataset was then reformatted according to "tidy" principles:
* Rather that lining up all features in one row, each feature was split out onto its own row, retaining the subject and activity, and the corresponding summary statistics.
* The feature was then expanded to columns for the six properties, with the values for those properties extracted from the feature name.

A note about the placement of the summary statistics.  The mean and standard deviation were *not* each assigned their own row, with a column to specify whether the statistic was the mean or standard deviation, but rather were retained together in one row.  The rationale for that is that these represent parameters of the distribution of the feature value when grouped by subject and activity.  The distribution *as a whole* is the *value* associated with the index columns, subject, activity, and feature properties.  That is, the distribution should be regarded as an indivisible object, whether it's represented by mean and standard deviation, or particle filter, or mathematical formula, or surface plot.  It's only because this is a proxy analysis that we happen to have two items of data to represent the distribution.  It is recognized that others may make the alternate choice.

Two actual errors in the dataset labels should be noted.
* Some feature names have the text "Body" repeated, but the rest of the label is intact, so these Body doubles (sorry) were simply removed.
* One of the "angle" features (which were not used here) contains a spurious ")" in its label: angle(tBodyAccJerkMean),gravityMean)

Please see the detailed comments in the script run_analysis.R, including some oddities encountered in the dataset, and more oddities with R and its packages...

Also please see README.md for instructions on running run_analysis.R.
