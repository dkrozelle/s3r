## ------------------------------------------------------------------------
# devtools::install_github("dkrozelle/s3r")
library(s3r)
s3_set(bucket  = "s3r-test-bucket", 
       profile = "s3r-read-write-user", 
       sse     = F )

## ------------------------------------------------------------------------
s3_cd()

## ------------------------------------------------------------------------
s3_ls()
s3_cd("top")
s3_ls()

## ------------------------------------------------------------------------
s3_ls()
# if we try to move into a directory that doesn't exist, we'll fail
s3_cd("another")
s3_ls("..")
s3_cd("..")
s3_cd("top", "next")
# in addition to the typical ".." and "." notation, you can also base your path
# relative to the bucket root by prefixing with "/"
s3_cd("/")

## ------------------------------------------------------------------------
# you can do a simple list to return an R list of basic filenames 
# and immediate directories
s3_ls()
# You can also list files or directories only (but only choose one)
s3_ls(files.only = T)
# the full names option returns a fully qualified s3 name
s3_ls(full.names = T)
# or if you'd like the date/size metadata you can use
s3_ls(full.response = T)

## ------------------------------------------------------------------------
s3_ls(pattern = "txt$")
s3_ls(pattern = "2|3")

## ------------------------------------------------------------------------
s3_ls(recursive = T)
# You can combine some options, but others don't play well together 
# (as one might expect)
s3_ls(recursive = T, pattern = "\\/") # works as expected
s3_ls(recursive = T, full.names = T)  # also works fine, almost better ;) 
# this will never return anything because directories don't actually exist in s3
s3_ls(recursive = T, dir.only = T) 

## ------------------------------------------------------------------------
# Since we haven't set it, our local cache is set to the current directory, 
# let's change it to a folder named /tmp/s3-cache folder. It will be created 
# if it doesn't exist
(settings <- s3_set())
s3_set(cache = "/tmp/s3-cache")

## ------------------------------------------------------------------------
s3_cd("top/next/third")
s3_ls()
# conveniently the get_save() will return the directory, so save this for import
local.path <- s3_get_save("file.csv")
read.csv(local.path)
# using the get_with() notation we perform an identical operation in a single line
s3_get_with("file.csv", FUN = read.csv)
# and finally we can use the preconfigured csv reader 
df <- s3_get_csv('file.csv')

## ------------------------------------------------------------------------
s3_get_table <- build_custom_get(FUN = read.table, 
                                 fun.defaults = list(header     = T,
                                                     sep        = "\t", 
                                                     quote      = F,
                                                     na.strings = c("NA", "")
                                 ))

s3_note <- build_custom_get(FUN = utils::file.edit)
# s3_note("file.csv") # only works interactively

## ------------------------------------------------------------------------
# if you were paying attention, a very bad person saved the file.csv and 
# included row.names. Lets fix this and put the file back into a 
# processed subfolder of our cwd.
df$X <- NULL
s3_put_table(df, "processed_data/fixed_rownames.txt")
# lets take a look at what we have now, but only files below the 
# directory named "third" 
s3_ls(recursive = T, pattern = "third")

