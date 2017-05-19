# s3r
Life is short, you shouldn't type so much when interacting with s3 buckets

# Introduction to s3r
Dan Rozelle  
2017-05-15
  
Just sketching out how to use the core functionality of s3r. Be aware this is very alpha, and please feel free to reach out if you use this and have any feedback, much appreciated.
  
The main improvements this package makes over using the default AWS commandline tools is the use of a configured R environment that is used to keep track of various things; bucket name, authentication profile, local storage directory and a current working directory. Rather than explain in text, I'll go into a few of the expected use cases.
  
> big caveat, I'm only be testing this package initially on amazon linux and ubuntu, so usage on windows or osx at your own risk.
  
### Requirements
To use this package you need to have [aws.cli](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) installed and configured on your machine. If you are interacting with a private bucket this'll include configuring your credentials. Default credentials (without specifying a --profile) will be used unless a profile name is specified.
  

```bash
# on commandline
aws configure help
aws configure --profile=user
```
  
### Usage
At the start of any s3r session you'll need to configure your environment. Here I've added the bucket name (with or without the "s3://" prefix), a profile that has been configured with the necessary access key and pass, and I've defined that any write operation into the bucket require sse encryption. 

```r
# devtools::install_github("dkrozelle/s3r")
library(s3r)
s3_set(bucket  = "s3r-test-bucket", 
       profile = "s3r-read-write-user", 
       sse     = F )
```
  
By default the current working directory (cwd) is set at the bucket root. When used without an argument, the s3_cd() function returns the cwd. 

```r
s3_cd()
```

```
## [1] "s3://s3r-test-bucket"
```
  
### Using the current working directory
To change the cwd just add prefix arguments. I've attempted to keep this as flexible as possible, accepting a character vector, separate character strings, or lists. You are only allowed to set an existing prefix as the cwd, which is done on purpose to prevent mistakenly moving files into a new (misspelled directory). Check out how the s3_ls() changes when the cwd is reset, by default it'll list the directory contents of the cwd.

```r
s3_ls()
```

```
## [1] "processed_data/" "top/"            "file.csv"        "file1.txt"      
## [5] "file2.csv"       "file2.txt"       "file3.csv"       "file4.csv"
```

```r
s3_cd("top")
```

```
## [1] "s3://s3r-test-bucket/top"
```

```r
s3_ls()
```

```
## [1] "next/"
```

Before we get into additional functions, here are a few other examples of how to move around the cwd. These types of flexible arguments are accepted by all s3r functions, and are only required to be wrapped in a list when multiple locations are specified at one time (put, get, etc).

```r
s3_ls()
```

```
## [1] "next/"
```

```r
# if we try to move into a directory that doesn't exist, we'll fail
s3_cd("another")
```

```
## unable to set cwd, does s3://s3r-test-bucket/top/another location exist?
```

```
## [1] "s3://s3r-test-bucket/top"
```

```r
s3_ls("..")
```

```
## [1] "processed_data/" "top/"            "file.csv"        "file1.txt"      
## [5] "file2.csv"       "file2.txt"       "file3.csv"       "file4.csv"
```

```r
s3_cd("..")
```

```
## [1] "s3://s3r-test-bucket"
```

```r
s3_cd("top", "next")
```

```
## [1] "s3://s3r-test-bucket/top/next"
```

```r
# in addition to the typical ".." and "." notation, you can also base your path
# relative to the bucket root by prefixing with "/"
s3_cd("/")
```

```
## [1] "s3://s3r-test-bucket"
```

#### Listing directory contents
The function s3_ls() performs all the expected functions of listing files and directories at the cwd, but supplements it with a number of additional features.

```r
# you can do a simple list to return an R list of basic filenames 
# and immediate directories
s3_ls()
```

```
## [1] "processed_data/" "top/"            "file.csv"        "file1.txt"      
## [5] "file2.csv"       "file2.txt"       "file3.csv"       "file4.csv"
```

```r
# You can also list files or directories only (but only choose one)
s3_ls(files.only = T)
```

```
## [1] "file.csv"  "file1.txt" "file2.csv" "file2.txt" "file3.csv" "file4.csv"
```

```r
# the full names option returns a fully qualified s3 name
s3_ls(full.names = T)
```

```
## [1] "s3://s3r-test-bucket/processed_data/"
## [2] "s3://s3r-test-bucket/top/"           
## [3] "s3://s3r-test-bucket/file.csv"       
## [4] "s3://s3r-test-bucket/file1.txt"      
## [5] "s3://s3r-test-bucket/file2.csv"      
## [6] "s3://s3r-test-bucket/file2.txt"      
## [7] "s3://s3r-test-bucket/file3.csv"      
## [8] "s3://s3r-test-bucket/file4.csv"
```

```r
# or if you'd like the date/size metadata you can use
s3_ls(full.response = T)
```

```
## [1] "                           PRE processed_data/"
## [2] "                           PRE top/"           
## [3] "2017-05-15 14:06:54         41 file.csv"       
## [4] "2017-05-16 22:30:57         22 file1.txt"      
## [5] "2017-05-16 22:29:34         41 file2.csv"      
## [6] "2017-05-16 22:31:04         22 file2.txt"      
## [7] "2017-05-16 22:29:46         41 file3.csv"      
## [8] "2017-05-16 22:29:51         41 file4.csv"
```

Some of the more advanced features include the usage of regex filtering. This is based on normal R grepl functionality, see ?grepl for more info.

```r
s3_ls(pattern = "txt$")
```

```
## [1] "file1.txt" "file2.txt"
```

```r
s3_ls(pattern = "2|3")
```

```
## [1] "file2.csv" "file2.txt" "file3.csv"
```

You can also look recursively into the directory, although due to some peculiarities with s3 structure, it will always be root-qualified instead of cwd qualified as with other s3_ls() calls. I'll likely fix this soon.

```r
s3_ls(recursive = T)
```

```
##  [1] "file.csv"                                        
##  [2] "file1.txt"                                       
##  [3] "file2.csv"                                       
##  [4] "file2.txt"                                       
##  [5] "file3.csv"                                       
##  [6] "file4.csv"                                       
##  [7] "processed_data/fixed_rownames.txt"               
##  [8] "top/next/third/file.csv"                         
##  [9] "top/next/third/filename2.txt"                    
## [10] "top/next/third/fourth/filename.txt"              
## [11] "top/next/third/processed_data/fixed_rownames.txt"
```

```r
# You can combine some options, but others don't play well together 
# (as one might expect)
s3_ls(recursive = T, pattern = "\\/") # works as expected
```

```
## [1] "processed_data/fixed_rownames.txt"               
## [2] "top/next/third/file.csv"                         
## [3] "top/next/third/filename2.txt"                    
## [4] "top/next/third/fourth/filename.txt"              
## [5] "top/next/third/processed_data/fixed_rownames.txt"
```

```r
s3_ls(recursive = T, full.names = T)  # also works fine, almost better ;) 
```

```
##  [1] "s3://s3r-test-bucket/file.csv"                                        
##  [2] "s3://s3r-test-bucket/file1.txt"                                       
##  [3] "s3://s3r-test-bucket/file2.csv"                                       
##  [4] "s3://s3r-test-bucket/file2.txt"                                       
##  [5] "s3://s3r-test-bucket/file3.csv"                                       
##  [6] "s3://s3r-test-bucket/file4.csv"                                       
##  [7] "s3://s3r-test-bucket/processed_data/fixed_rownames.txt"               
##  [8] "s3://s3r-test-bucket/top/next/third/file.csv"                         
##  [9] "s3://s3r-test-bucket/top/next/third/filename2.txt"                    
## [10] "s3://s3r-test-bucket/top/next/third/fourth/filename.txt"              
## [11] "s3://s3r-test-bucket/top/next/third/processed_data/fixed_rownames.txt"
```

```r
# this will never return anything because directories don't actually exist in s3
s3_ls(recursive = T, dir.only = T) 
```

```
## character(0)
```

#### Loading s3 objects into R
The function _**s3_get**_ suite of tools automatically save an s3 object to your defined local cache (if you didn't define one, it'll be the current directory) and can load it into R using your preferred utility. Since you could potentially read any file into R, you must define what you'd like to use. You can do this either by using the s3_get_save() function and manually reading the local file, using s3_get_with(object, FUN) to read in with a FUNction defined at run time, or better yet you can use the function builders to make as many custom importers along with their associated default arguments as you'd like. I'll show you how to all three here:

```r
# Since we haven't set it, our local cache is set to the current directory, 
# let's change it to a folder named /tmp/s3-cache folder. It will be created 
# if it doesn't exist
(settings <- s3_set())
```

```
##                          bucket                           cache 
##          "s3://s3r-test-bucket"                             "." 
##                             cwd                         profile 
##          "s3://s3r-test-bucket" "--profile=s3r-read-write-user"
```

```r
s3_set(cache = "/tmp/s3-cache")
```

Now lets assume we want to work with files in one of the deeper locations. It'd make sense to set the cwd to that directory before getting and putting files to save us the trouble of typing the fully qualified directory list.

```r
s3_cd("top/next/third")
```

```
## [1] "s3://s3r-test-bucket/top/next/third"
```

```r
s3_ls()
```

```
## [1] "fourth/"         "processed_data/" "file.csv"        "filename2.txt"
```

```r
# conveniently the get_save() will return the directory, so save this for import
local.path <- s3_get_save("file.csv")
read.csv(local.path)
```

```
##   X col1 col2
## 1 1    1    2
## 2 2    2    3
## 3 3    3    4
```

```r
# using the get_with() notation we perform an identical operation in a single line
s3_get_with("file.csv", FUN = read.csv)
```

```
##   X col1 col2
## 1 1    1    2
## 2 2    2    3
## 3 3    3    4
```

```r
# and finally we can use the preconfigured csv reader 
df <- s3_get_csv('file.csv')
```

You can build other import functions to keep on a local code import, I've purposefully left this up to you so you know how easy it is to define a custom import tool including your preferred default parameters. For example, I'll show you how I built the tab-delimiter file imported included with this package. This approach is not limited to tabular data either, use it to open text documents directly from s3

```r
s3_get_table <- build_custom_get(FUN = read.table, 
                                 fun.defaults = list(header     = T,
                                                     sep        = "\t", 
                                                     quote      = F,
                                                     na.strings = c("NA", "")
                                 ))

s3_note <- build_custom_get(FUN = utils::file.edit)
# s3_note("file.csv") # only works interactively
```

#### Putting files back onto s3
For every get() function, there is a put() function. This makes sense since all the different file formats need to be saves in their own special way. Just remember, these all still use relative s3 file paths, so feel free to go crazy!

```r
# if you were paying attention, a very bad person saved the file.csv and 
# included row.names. Lets fix this and put the file back into a 
# processed subfolder of our cwd.
df$X <- NULL
s3_put_table(df, "processed_data/fixed_rownames.txt")
```

```
## [1] "s3://s3r-test-bucket/top/next/third/processed_data/fixed_rownames.txt"
```

```r
# lets take a look at what we have now, but only files below the 
# directory named "third" 
s3_ls(recursive = T, pattern = "third")
```

```
## [1] "top/next/third/file.csv"                         
## [2] "top/next/third/filename2.txt"                    
## [3] "top/next/third/fourth/filename.txt"              
## [4] "top/next/third/processed_data/fixed_rownames.txt"
```

#### TBD
I've just added s3_mv() and s3_cp() function but not quite ready, coming soon. 
Dan
