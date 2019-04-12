---
title: "Introduction to s3r"
author: "Dan Rozelle"
date: "2019-04-11"
output:
  rmarkdown::html_vignette:
    keep_md: true
vignette: >
  %\VignetteIndexEntry{"Introduction to s3r"}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
  
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
##  [1] "PRE processed_data2/" "PRE processed_data3/" "PRE top/"            
##  [4] "file1.txt"            "file2.csv"            "file2.txt"           
##  [7] "file3.csv"            "file4.csv"            "new_filename.txt"    
## [10] "new_filename2.txt"
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
## [1] "PRE next/"
```

Before we get into additional functions, here are a few other examples of how to move around the cwd. These types of flexible arguments are accepted by all s3r functions, and are only required to be wrapped in a list when multiple locations are specified at one time (put, get, etc).

```r
s3_ls()
```

```
## [1] "PRE next/"
```

```r
# if we try to move into a directory that doesn't exist, we'll fail
s3_cd("another")
```

```
## proposed location s3://s3r-test-bucket/top/another does not exist
```

```
## [1] "s3://s3r-test-bucket/top"
```

```r
s3_ls("..")
```

```
##  [1] "PRE processed_data2/" "PRE processed_data3/" "PRE top/"            
##  [4] "file1.txt"            "file2.csv"            "file2.txt"           
##  [7] "file3.csv"            "file4.csv"            "new_filename.txt"    
## [10] "new_filename2.txt"
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
##  [1] "PRE processed_data2/" "PRE processed_data3/" "PRE top/"            
##  [4] "file1.txt"            "file2.csv"            "file2.txt"           
##  [7] "file3.csv"            "file4.csv"            "new_filename.txt"    
## [10] "new_filename2.txt"
```

```r
# You can also list files or directories only (but only choose one)
s3_ls(files.only = T)
```

```
## [1] "file1.txt"         "file2.csv"         "file2.txt"        
## [4] "file3.csv"         "file4.csv"         "new_filename.txt" 
## [7] "new_filename2.txt"
```

```r
# the full names option returns a fully qualified s3 name
s3_ls(full.names = T)
```

```
##  [1] "s3://s3r-test-bucket//PRE processed_data2/"
##  [2] "s3://s3r-test-bucket//PRE processed_data3/"
##  [3] "s3://s3r-test-bucket//PRE top/"            
##  [4] "s3://s3r-test-bucket//file1.txt"           
##  [5] "s3://s3r-test-bucket//file2.csv"           
##  [6] "s3://s3r-test-bucket//file2.txt"           
##  [7] "s3://s3r-test-bucket//file3.csv"           
##  [8] "s3://s3r-test-bucket//file4.csv"           
##  [9] "s3://s3r-test-bucket//new_filename.txt"    
## [10] "s3://s3r-test-bucket//new_filename2.txt"
```

```r
# or if you'd like the date/size metadata you can use
s3_ls(full.response = T)
```

```
##  [1] "                           PRE processed_data2/" 
##  [2] "                           PRE processed_data3/" 
##  [3] "                           PRE top/"             
##  [4] "2017-05-16 22:30:57         22 file1.txt"        
##  [5] "2017-05-16 22:29:34         41 file2.csv"        
##  [6] "2017-05-16 22:31:04         22 file2.txt"        
##  [7] "2017-05-16 22:29:46         41 file3.csv"        
##  [8] "2017-05-16 22:29:51         41 file4.csv"        
##  [9] "2017-05-18 12:06:56         41 new_filename.txt" 
## [10] "2017-05-18 12:34:57         41 new_filename2.txt"
```

Some of the more advanced features include the usage of regex filtering. This is based on normal R grepl functionality, see ?grepl for more info.

```r
s3_ls(pattern = "txt$")
```

```
## [1] "file1.txt"         "file2.txt"         "new_filename.txt" 
## [4] "new_filename2.txt"
```

```r
s3_ls(pattern = "2|3")
```

```
## [1] "PRE processed_data2/" "PRE processed_data3/" "file2.csv"           
## [4] "file2.txt"            "file3.csv"            "new_filename2.txt"
```

You can also look recursively into the directory, although due to some peculiarities with s3 structure, it will always be root-qualified instead of cwd qualified as with other s3_ls() calls. I'll likely fix this soon.

```r
s3_ls(recursive = T)
```

```
##  [1] "file1.txt"                                        
##  [2] "file2.csv"                                        
##  [3] "file2.txt"                                        
##  [4] "file3.csv"                                        
##  [5] "file4.csv"                                        
##  [6] "new_filename.txt"                                 
##  [7] "new_filename2.txt"                                
##  [8] "processed_data2/fixed_rownames.txt"               
##  [9] "processed_data3/fixed_rownames.txt"               
## [10] "top/next/filename.txt"                            
## [11] "top/next/third/file.csv"                          
## [12] "top/next/third/filename2.txt"                     
## [13] "top/next/third/fourth/filename.txt"               
## [14] "top/next/third/processed_data/fixed_rownames.txt" 
## [15] "top/next/thuird/file.csv"                         
## [16] "top/next/thuird/filename2.txt"                    
## [17] "top/next/thuird/fourth/filename.txt"              
## [18] "top/next/thuird/processed_data/fixed_rownames.txt"
```

```r
# You can combine some options, but others don't play well together 
# (as one might expect)
s3_ls(recursive = T, pattern = "\\/") # works as expected
```

```
##  [1] "processed_data2/fixed_rownames.txt"               
##  [2] "processed_data3/fixed_rownames.txt"               
##  [3] "top/next/filename.txt"                            
##  [4] "top/next/third/file.csv"                          
##  [5] "top/next/third/filename2.txt"                     
##  [6] "top/next/third/fourth/filename.txt"               
##  [7] "top/next/third/processed_data/fixed_rownames.txt" 
##  [8] "top/next/thuird/file.csv"                         
##  [9] "top/next/thuird/filename2.txt"                    
## [10] "top/next/thuird/fourth/filename.txt"              
## [11] "top/next/thuird/processed_data/fixed_rownames.txt"
```

```r
s3_ls(recursive = T, full.names = T)  # also works fine, almost better ;) 
```

```
##  [1] "s3://s3r-test-bucket//file1.txt"                                        
##  [2] "s3://s3r-test-bucket//file2.csv"                                        
##  [3] "s3://s3r-test-bucket//file2.txt"                                        
##  [4] "s3://s3r-test-bucket//file3.csv"                                        
##  [5] "s3://s3r-test-bucket//file4.csv"                                        
##  [6] "s3://s3r-test-bucket//new_filename.txt"                                 
##  [7] "s3://s3r-test-bucket//new_filename2.txt"                                
##  [8] "s3://s3r-test-bucket//processed_data2/fixed_rownames.txt"               
##  [9] "s3://s3r-test-bucket//processed_data3/fixed_rownames.txt"               
## [10] "s3://s3r-test-bucket//top/next/filename.txt"                            
## [11] "s3://s3r-test-bucket//top/next/third/file.csv"                          
## [12] "s3://s3r-test-bucket//top/next/third/filename2.txt"                     
## [13] "s3://s3r-test-bucket//top/next/third/fourth/filename.txt"               
## [14] "s3://s3r-test-bucket//top/next/third/processed_data/fixed_rownames.txt" 
## [15] "s3://s3r-test-bucket//top/next/thuird/file.csv"                         
## [16] "s3://s3r-test-bucket//top/next/thuird/filename2.txt"                    
## [17] "s3://s3r-test-bucket//top/next/thuird/fourth/filename.txt"              
## [18] "s3://s3r-test-bucket//top/next/thuird/processed_data/fixed_rownames.txt"
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
##              create_command_log                             cwd 
##                          "TRUE"          "s3://s3r-test-bucket" 
##                         profile 
## "--profile=s3r-read-write-user"
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
## [1] "PRE fourth/"         "PRE processed_data/" "file.csv"           
## [4] "filename2.txt"
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
## [1] "file written to: /tmp/s3-cache/fixed_rownames.txt"
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
## [1] "file.csv"                          "filename2.txt"                    
## [3] "fourth/filename.txt"               "processed_data/fixed_rownames.txt"
```

#### Move, Copy and Sync
This suite of functions operate similarly to listing functions above, however since from/to locations need to be distinguished you must wrap each path vector in a list. 

#### TBD 
There are a couple of holes, somwhat on purpose, but mainly because I haven't had the time to do them well. Namely removing items from an s3 bucket. If you're really in a pinch it can be accomplished by using the ```s3_mv()``` function along with the param ```allow.overwrite = T```.  

Dan
