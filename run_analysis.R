# This script does the following.
## 1. Merges the training and the test sets to create one data set.
## 2. Extracts only the measurements on the mean and standard deviation for each measurement.
## 3. Uses descriptive activity names to name the activities in the data set
## 4. Appropriately labels the data set with descriptive variable names.
## 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

## 1. Merge the training and the test sets to create one data set.

### 1a. Set working directory
setwd("C:/Users/Dom/Documents/Sally/Data Science/Getting and Cleaning Data/Course Project")

### 1b. Load required packages
library(data.table)
library(dplyr)
library(stringr)

### 1c. Download and unzip data
if (!file.exists("UCI HAR Dataset")) dir.create("UCI HAR Dataset")
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(fileUrl,destfile="/UCI HAR Dataset.zip", method="curl")
unzip ("/UCI HAR Dataset.zip",exdir=".")

### 1d. Read in column labels for features and activities
FeatureLabels <- fread("./UCI HAR Dataset/features.txt",col.names=c("featureid","featurelabel"))
ActivityLabels <- fread("./UCI HAR Dataset/activity_labels.txt",col.names=c("activityid","activitylabel"))

### 1e. Read in train data sets for features, activities and subjects
Features_train <- fread("./UCI HAR Dataset/train/X_train.txt",
                           col.names=FeatureLabels$featurelabel)
ActivityId_train <- fread("./UCI HAR Dataset/train/y_train.txt",
                           col.names="activityid")
SubjectId_train <- fread("./UCI HAR Dataset/train/subject_train.txt",
                           col.names="subjectid")

### 1f. Cbind train data to form a single train data set
Train_data <- cbind(SubjectId_train,ActivityId_train,Features_train)

### 1g. Read in test data sets for features, activities and subjects
Features_test <- fread("./UCI HAR Dataset/test/X_test.txt",
                        col.names=FeatureLabels$featurelabel)
ActivityId_test <- fread("./UCI HAR Dataset/test/y_test.txt",
                          col.names="activityid")
SubjectId_test <- fread("./UCI HAR Dataset/test/subject_test.txt",
                         col.names="subjectid")

### 1h. Cbind test data to form a single test data set
Test_data <- cbind(SubjectId_test,ActivityId_test,Features_test)

### 1i. Rbind test and train data to form a single data set containing all data required for analysis
All_data <- rbind(Train_data,Test_data)

## 2. Extract only the measurements on the mean and standard deviation for each measurement.

### 2a. Get list of the relevant measurements for analysis (i.e. whose name contains "-mean()" or "-std()" only)
Selected_features <- grep("-(mean|std)\\(\\)",names(All_data))

### 2b. Extract the IDs and relevant fields from the combined data
Selected_data<-select(All_data,1,2,Selected_features)

## 3. Uses descriptive activity names to name the activities in the data set
Labelled_data <- merge(ActivityLabels,Selected_data,
                       by.x="activityid",by.y="activityid",all=FALSE)

## 4. Appropriately labels the data set with descriptive variable names.

### 4a. Define a new function to substitute through a list (thanks to Jean-Robert's response on Stack Overflow for this)
gsub2 <- function(pattern, replacement, x, ...) {
  for(i in 1:length(pattern))
    x <- gsub(pattern[i], replacement[i], x, ...)
  x
}

### 4b. Define a list of (unclear) original text patterns
Originals<-c(
  "^t",
  "^f",
  "[Aa]cc",
  "[Mm]ag",
  "[Gg]yro",
  "[Ss]td\\(\\)",
  "[Mm]ean\\(\\)",
  "([Bb]ody)+"
)

### 4c. Define a list of (clear and descriptive) substitute patterns
Substitutes<-c(
  "Time",
  "Frequency",
  "Acceleration",
  "Magnitude",
  "Gyroscope",
  "Std",
  "Mean",
  "Body"
)

### 4d. Substitute out the originals using the new function gsub2 defined in 13a
names(Labelled_data) <- gsub2(Originals, Substitutes, names(Labelled_data))

### 4e. Also substitute out hyphens to leave a single descriptive text string for each column name
names(Labelled_data) <- gsub("-","", names(Labelled_data))

## 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

### 5a. Melt the data to transform the features into a single column rather than multiple columns and calculate the mean for each feature
Molten_data<-melt(Labelled_data,
                  id.vars=c("activityid","activitylabel","subjectid"),
                  variable.name="featurelabel",
                  value.name="value",
                  variable.factor=FALSE)[,mean(value),by=.(activitylabel,subjectid,featurelabel)] 

### 5b. Rename the mean to "mean" and reorder the data set
Tidy_data<-Molten_data%>%
  rename(mean=V1) %>%
  arrange(activitylabel,subjectid,featurelabel)

### 5c. Output the data as a txt file created with write.table() using row.name=FALSE
write.table(Tidy_data,"Human-Activity/Tidy_data.txt",row.names = FALSE)