#' Download an S3 object and read into R using specified read function.
#'
#' @param ... flexible s3 path description of s3 location and object name. This is 
#' relative to your cwd (use s3_cd() to print your cwd). Accepts a character 
#' vector "top/next", separate character strings c("top", "next"), or 
#' lists list("top", "next").
#' @param FUN function name, unquoted, used to read the file.
#' @param fun.args list of named arguments to pass to FUN
#' @param aws.args character string of any additional values you need appended 
#' to this aws.cli command line call.
#' 
#' @return S3 object
#' @export
s3_get_with <- function(..., FUN, fun.args = NULL, cache = F, unique_filename = T, aws.args = NULL) {
  
  if( !check_vars("cache") ){
    message('please define a local cache with s3_set(cache = "/tmp") before use')
    return(1)
  } 
  if( length(list(...)) == 0 ){ 
    message('missing required s3 object name (...)')
    return(1)
  }
  
  # define to/from locations
  s3.path    <- build_uri(...) 
  
  local.path <- build_local_path(basename(s3.path), 
                                 unique_filename = unique_filename)
  if(!cache) on.exit(unlink(local.path))
  
  # download the file
  cmd <- paste('aws s3 cp',
               aws.args,
               s3.path,
               local.path)
  
  response <- aws_cli(cmd)
  
  if( any(response == 1) ){
    message('error fetching object from s3')
    return(1)
  }else if(file.exists(local.path)){
    x <- do.call(FUN, args = c(list(file = local.path), fun.args ))
    return(x)
  }else{
    message('unable to write to local file')
    return(1)
  }
}

#' Download an S3 object to local cache directory.
#' 
#' Use this version if you'd like to keep the local file cached and work on it
#' directly (e.g. pass to other bash scripts). Particularly useful if this is a 
#' big file you only want to download once.
#'
#' @param ... flexible s3 path description of s3 location and object name. This is 
#' relative to your cwd (use s3_cd() to print your cwd). Accepts a character 
#' vector "top/next", separate character strings c("top", "next"), or 
#' lists list("top", "next").
#' @param aws.args character string of any additional values you need appended to this 
#' aws.cli command line call.
#' 
#' @return file path
#' @export
s3_get_save <- function(..., unique_filename = T, aws.args = NULL) {
  
  if( !check_vars("cache") ){
    message('please define a local cache with s3_set(cache = "/tmp") before use')
    return(1)
  } 
  if( length(list(...)) == 0 ){ 
    message('missing required s3 object name (...)')
    return(1)
  }
  
  # define to/from locations
  s3.path    <- build_uri(...) 
  local.path <- build_local_path(basename(s3.path), 
                                 unique_filename = unique_filename)
    
  # download the file
  cmd <- paste('aws s3 cp',
               aws.args,
               s3.path,
               local.path)
  
  response <- aws_cli(cmd)
  
  if( any(response == 1) ){
    message('error fetching object from s3')
    return(1)
  }else if(file.exists(local.path)){
    return(local.path)
  }else{
    message('unable to write to local file')
    return(1)
  }
}

#' Helper function to build custom S3 object readers.
#' 
#' Use this helper function to build custom reader tools. Define a function and 
#' associated arguments for reading into R and save as a reusable function.
#'
#' @param FUN function name, unquoted, used to read the file.
#' @param fun.args list of named arguments to pass to FUN
#' 
#' @return function
#' @export
build_custom_get <- function(FUN, fun.defaults = NULL){
  
  # returns an s3_put_with function using predefined file writer and args
  function(..., fun.args = NULL, aws.args = NULL){
    
    if( length(fun.args) > 0){
      fun.args <- c(fun.args, fun.defaults[!names(fun.defaults) %in% names(fun.args)])
    }else{
      fun.args <- fun.defaults
    }
    
    do.call("s3_get_with", c(list(...),
                             list(FUN = FUN),  
                             list(aws.args = aws.args, fun.args = fun.args))
    )
  }
}

#' Read a tab-delim table into R
#' 
#' Example of a custom import tool created with s3_get_table <- build_custom_get(FUN = read.table, fun.defaults = list(header = T, sep = {TAB}, quote = F, na.strings = c("NA", "") ))
#' @return an S3 object read into R using read.table
#' @export
s3_get_table <- build_custom_get(FUN = read.table, 
                                 fun.defaults = list(header     = T,
                                                     sep        = "\t", 
                                                     na.strings = c("NA", "")
                                 ))

#' Read a csv table into R
#' 
#' Example of a custom import tool created with 
#' s3_get_table <- build_custom_get(FUN = read.csv)
#' 
#' @return an S3 object read into R using read.table
#' @export
s3_get_csv <- build_custom_get(FUN = read.csv)