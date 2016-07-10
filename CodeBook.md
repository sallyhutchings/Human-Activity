# Human-Activity
## Getting and Cleaning Data Course Project on human activity recognition using smartphones

## Scope of this document
In this document you will find a description of the input data, output data and any transformations or intermediate steps that were performed to arrive at the ouput data set. In essence, a description and explanation of the steps performed in the script run_analysis.R.

At a high level, run_analysis.R does the following.
1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement.
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive variable names.
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

## 1. Merge the training and the test sets to create one data set.
All the data forming the basis of this analysis comes from a study on human activity whose details can be found here:
http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
The data from the study was downloaded using this link and extracted to a folder called "UCI HAR Dataset":
https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip
Here are the details of the files used in this project (for full details of available files see the readme file "/UCI HAR Dataset/README.txt"):
* Feature labels ("/UCI HAR Dataset/features.txt") which contains two fields, the feature ID and the feature label.
* Activity labels ("./UCI HAR Dataset/activity_labels.txt") which contains  similar information for the activities (an ID and a label).
* Train data:
..* Feature measurements  ("./UCI HAR Dataset/train/X_train.txt"): values corresponding to the feature labels
..* Activity IDs  ("./UCI HAR Dataset/train/y_train.txt"): a list of activity IDs corresponding to the feature measurements
..* Subject IDs  ("./UCI HAR Dataset/train/subject_train.txt"): a list of subject IDs corresponding to the feature measurements
* Test data:
..* Feature measurements  ("./UCI HAR Dataset/test/X_test.txt"): values corresponding to the feature labels
..* Activity IDs  ("./UCI HAR Dataset/test/y_test.txt"): a list of activity IDs corresponding to the feature measurements
..* Subject IDs  ("./UCI HAR Dataset/test/subject_test.txt"): a list of subject IDs corresponding to the feature measurements
Note that I have not included the inertial signals data, because the analysis I will be doing only involves variables related to the mean or standard deviation of features and therefore these are not relevant.
**Note on reading in files:** *fread* was my chosen method as it's faster and more convenient than data.table and automatically detects key parameters such as the delimeter.

### 1a. Set working directory
I set a working directory to download the files to. Note that this directory contains the branch of the Github repo that I will be outputting the final tidy data set to.
```
setwd("C:/Users/Dom/Documents/Sally/Data Science/Getting and Cleaning Data/Course Project")
```

### 1b. Load required packages
The following libraries will be required as I will be using functions including *fread*, *melt*, *arrange* and *str* (the latter is not used directly but was used to interrogate the data).
```
library(data.table)
library(dplyr)
library(stringr)
```

### 1c. Download and unzip data
This section checks whether the directory "UCI HAR Dataset" already exists, creates it, downloads and unzips the data from the study (described in the overview above).
```
if (!file.exists("UCI HAR Dataset")) dir.create("UCI HAR Dataset")
fileUrl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(fileUrl,destfile="/UCI HAR Dataset.zip", method="curl")
unzip ("/UCI HAR Dataset.zip",exdir=".")
```

### 1d. Read in column labels for features and activities
Here I use *fread* to read in the feature and activity labels to data tables called "FeatureLabels" and "ActivityLabels " respectively, naming their columns to make their application to the IDs easy later on.
```
FeatureLabels <- fread("./UCI HAR Dataset/features.txt",col.names=c("featureid","featurelabel"))
ActivityLabels <- fread("./UCI HAR Dataset/activity_labels.txt",col.names=c("activityid","activitylabel"))
```

### 1e. Read in train data sets for features, activities and subjects
Here I use *fread* again to read in the feature measurement data for the train data sets to a data table called "Features_train", naming the columns using the feature labels from the previous step. I also use *fread* to read in the activity and subject IDs for each row, naming the columns consistently with the previous step to make adding labels later easy. 
```
Features_train <- fread("./UCI HAR Dataset/train/X_train.txt",
                           col.names=FeatureLabels$featurelabel)
ActivityId_train <- fread("./UCI HAR Dataset/train/y_train.txt",
                           col.names="activityid")
SubjectId_train <- fread("./UCI HAR Dataset/train/subject_train.txt",
                           col.names="subjectid")
```

### 1f. Cbind train data to form a single train data set
Note that all the data sets from the previous step have 7352 observations and can therefore be combined using *cbind* function. Thus I use *cbind* to collate the subject, activity and feature data from the train data sets into a single train data set called "Train_data".
```
Train_data <- cbind(SubjectId_train,ActivityId_train,Features_train)
```

### 1g. Read in test data sets for features, activities and subjects
Here I use *fread* again to read in the feature measurement data for the test data sets, exactly as I did for the train data.
```
Features_test <- fread("./UCI HAR Dataset/test/X_test.txt",
                        col.names=FeatureLabels$featurelabel)
ActivityId_test <- fread("./UCI HAR Dataset/test/y_test.txt",
                          col.names="activityid")
SubjectId_test <- fread("./UCI HAR Dataset/test/subject_test.txt",
                         col.names="subjectid")
```

### 1h. Cbind test data to form a single test data set
Here I use *cbind* to collate the subject, activity and feature data from the test data sets into a single test data set, exactly as I did for the train data.
```
Test_data <- cbind(SubjectId_test,ActivityId_test,Features_test)
```

### 1i. Rbind test and train data to form a single data set containing all data required for analysis
As the test and train data has the same structure and columns, here I use *rbind* to create a single data set called "All_data" from the test and train data.
```
All_data <- rbind(Train_data,Test_data)
```

## 2. Extract only the measurements on the mean and standard deviation for each measurement.
There is some abiguity here as there are features with the word "mean" in their title and therefore could be included along with the ones that contain mean() and std(). However the naming convention suggest that the latter were generated using the mean() or std() functions and that the others were weighted averages or additional variables applied to the angle() variable and therefore have not been included.

### 2a. Get list of the relevant measurements for analysis (i.e. whose name contains "-mean()" or "-std()" only)
Here I use the pattern ```-(mean|std)\\(\\)``` to identify column names in the collated data set that contain the string "-mean()" or "-std()". The *grep* function outputs a list of the positions in the vector of names that contain such a pattern to a vector called "Selected_features". I will use this vector in the next step to extract just those columns using the *select* function.
```
Selected_features <- grep("-(mean|std)\\(\\)",names(All_data))
```

### 2b. Extract the IDs and relevant fields from the combined data
Here I use the *select* function together with the list of columns from the previous step to extract the relevant columns (plus activity and subject IDs which have positions 1 and 2 in the data set) and output the result to a data set called "Selected_data".
```
Selected_data<-select(All_data,1,2,Selected_features)
```

## 3. Uses descriptive activity names to name the activities in the data set
This part requires just a single step to read in the activity label for each activity ID in the "Selected_data" data set and I use the function *merge* to do this.
```
Labelled_data <- merge(ActivityLabels,Selected_data,
                       by.x="activityid",by.y="activityid",all=FALSE)
```

## 4. Appropriately labels the data set with descriptive variable names.
This step requires identifying a list of all the parts of the naming convention used in the study that are unclear or untidy and replacing them with clear and descriptive counterparts. To do this I will need to apply the function *gsub* over a list of substitutions and therefore I first define a new function, *gsub2*, which loops *gsub* over a list (thanks to Jean-Robert's response on Stack Overflow for this function, which can be found here: http://stackoverflow.com/a/6954308). The text patterns I have identified as needing replacement are:
* "t" at the start instead of "Time"
* "f" at the start instead of "Frequency"
* "acc" or "Acc" instead of "Acceleration"
* "mag" or "Mag" instead of "Magnitude"
* "gyro" or "Gyro" instead of "Gyroscope"
* "std()" or "Std()" instead of "Std"
* "mean()" or "Mean()" instead of "Mean"
* "body" or "Body" + repetitions instead of a single "Body"
I will also replace any hyphens and use the capitalisation of the words in the feature name as the only separation.

### 4a. Define a new function to substitute through a list (thanks to Jean-Robert's response on Stack Overflow for this)
First define the new function, *gsub2*, which loops *gsub* over a list.
```
gsub2 <- function(pattern, replacement, x, ...) {
  for(i in 1:length(pattern))
    x <- gsub(pattern[i], replacement[i], x, ...)
  x
}
```

### 4b. Define a list of (unclear) original text patterns
Next define the list of text patterns to be replaced.
```
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
```

### 4c. Define a list of (clear and descriptive) substitute patterns
Now define the list of replacements.
```
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
```

### 4d. Substitute out the originals using the new function gsub2 defined in 13a
Now substitute the original patterns in the names of the data set "Labelled_data" for their replacements using *gsub2* defined above.
```
names(Labelled_data) <- gsub2(Originals, Substitutes, names(Labelled_data))
```

### 4e. Also substitute out hyphens to leave a single descriptive text string for each column name
Now remove any hyphens in the names of the data set "Labelled_data" using *gsub*.
```
names(Labelled_data) <- gsub("-","", names(Labelled_data))
```

## 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
To do this I need to restructure the data so that it has columns for activity ID and label, subject ID and feature label, with a single mean or std value in a column I will call "value". I will use the *melt* function and output the data to a data set called "Molten_data". The I need to calculate the mean across each feature label, for each subject and activity, and output the data to a txt file created with write.table() using row.name=FALSE.

### 5a. Melt the data to transform the features into a single column rather than multiple columns and calculate the mean for each feature
Use the *melt* function to restructure the data as described in the overview, calculate the mean for each feature/activity/subject, and output the result to a data set called "Molten_data".
```
Molten_data<-melt(Labelled_data,
                  id.vars=c("activityid","activitylabel","subjectid"),
                  variable.name="featurelabel",
                  value.name="value",
                  variable.factor=FALSE)[,mean(value),by=.(activitylabel,subjectid,featurelabel)] 
```

### 5b. Rename the mean to "mean" and reorder the data set
Use chains to rename the mean to "mean" and reorder the "Molten_data" data set by activity label,subject ID, and feature label, outputting the data to a data set called "Tidy_data".
```
Tidy_data<-Molten_data%>%
  rename(mean=V1) %>%
  arrange(activitylabel,subjectid,featurelabel)
```

### 5c. Output the data as a txt file created with write.table() using row.name=FALSE
As required by the course instructions the final dataset "Tidy_data" is output as a txt file created with write.table() using row.name=FALSE into my Github repo folder.
```
write.table(Tidy_data,"Human-Activity/Tidy_data.txt",row.names = FALSE)
```

