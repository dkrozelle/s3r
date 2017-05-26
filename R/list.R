#' List objects in an S3 bucket.
#'
#' List the items in an S3 bucket. Lots of time-saving filters are built-in, including
#' the default use of a defined working directory and grep pattern matching. As with 
#' all functions in this package, you must first define your environment with s3_set().
#'
#' @param ... flexible s3 path description of s3 location and object name. This is 
#' relative to your cwd (use s3_cd() to print your cwd). Accepts a character 
#' vector "top/next", separate character strings c("top", "next"), or 
#' lists list("top", "next").
#' @param recursive  logical, when enabled lists all files under the defined 
#' directory. Currently the return is not optimal, and returns a root-based path 
#' independent of cwd. For example: cwd=s3"//bucket/one/two/three/ will return
#' s3_ls(".") as "one/two/three/file.txt" instead of the expected "file.txt"
#' @param pattern    character string pattern to filter results.
#' @param full.names logical return fully qualified file names.
#' @param files.only logical filter to show only files
#' @param dir.only   logical filter to show only directories. NOTE: Due to the fact 
#' that directories don't actually exist on S3, this won't work with recursive = T
#' @param all.files logical show unnamed objects ("")
#' @param full.response logical list entire metadata string from aws. Includes file
#' modified date/time and size.
#' @param aws.args character string of any additional values you need appended 
#' to this aws.cli command line call.
#' 
#' @return character vector of bucket contents
#' @export
s3_ls <- function( ... ,
                   recursive  = FALSE,
                   pattern    = NULL,
                   full.names = FALSE,
                   files.only = FALSE,
                   dir.only   = FALSE, 
                   all.files  = FALSE,
                   full.response = FALSE,
                   aws.args   = NULL){
  
  # we assume the path supplied is a directory
  path      <- build_uri(..., dir = T)
  path.base <- gsub(paste0(s3e$bucket,"\\/"), "", path)

  cmd <- paste('aws s3 ls',
               aws.args,
               if(recursive) "--recursive",
               path)
  response <- aws_cli(cmd)

  if( any(response == 1) ){
    message('unable to find that location')
    return(1)
  }else{
    resp <- response
  }
  

  if( full.response ){ 
    resp
  }else{
    # trim date and size info
    resp <- gsub("^.* ", "", resp) 
  }
  

  if( all.files ){
    resp 
  }else{
    resp <- resp[resp != ""]
  }

  if( files.only ){
    resp <- resp[!endsWith(resp, "/")]
  }else if( dir.only ){
    resp <- resp[endsWith(resp, "/")]
  }

  if( !is.null(pattern) ) resp <- grep(pattern, resp, value = T)
  
  
  if(!is.na(path.base)){
    resp <- gsub(path.base, "", resp)
  }
  
  if( full.names ){
    resp <- file.path(chomp_slash(s3e$bucket), chomp_slash(path.base), resp)
  }
  
  return(resp)
}