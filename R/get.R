#' Download an S3 object and read into R using specified write function.
#'
#' @return S3 object
#' @export
s3_get_with <- function(..., FUN, fun.args = NULL, aws.args = NULL) {
  
  if( !check_vars("cache") ){
    message('please define a local cache with s3_set(cache = "/tmp") before use')
    return()
  } 
  if( length(list(...)) == 0 ){ 
    message('missing required s3 object name (...)')
    return()
  }

  # define to/from locations
  s3.path    <- build_uri(...) 
  local.path <- file.path(s3e$cache, basename(s3.path))
  on.exit(unlink(local.path))
  
  # download the file
  cmd <- paste('aws s3 cp',
               aws.args,
               s3.path,
               local.path)
  resp <- aws_cli(cmd)  
  
  if( file.exists(local.path) ){

    do.call(FUN, args = c(list(file = local.path), fun.args ))
    
  }else{
    message('unable to write file')
    return()
  }
}

#' Download an S3 object to local cache directory.
#'
#' @return file path
#' @export
s3_get_save <- function(..., aws.args = NULL) {
  
  if( !check_vars("cache") ){
    message('please define a local cache with s3_set(cache = "/tmp") before use')
    return()
  } 
  if( length(list(...)) == 0 ){ 
    message('missing required s3 object name (...)')
    return()
  }

  # define to/from locations
  s3.path    <- build_uri(...) 
  local.path <- file.path(s3e$cache, basename(s3.path))

  # download the file
  cmd <- paste('aws s3 cp',
               aws.args,
               s3.path,
               local.path)
  resp <- aws_cli(cmd)  
  
  if( file.exists(local.path) ){
    local.path
  }else{
    message('unable to write file')
    return()
  }
}

#' Helper function to build custom S3 object readers.
#' 
#' @return function
#' @export
build_custom_get <- function(FUN, fun.defaults = NULL){
  
  # returns an s3_put_with function using predefined file writer and args
  function(x, ..., fun.args = NULL, aws.args = NULL){
    
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

#' Read an S3 table into R
#' 
#' @return an S3 object read into R using read.table
#' @export
s3_get_table <- build_custom_get(FUN = read.table, 
                                 fun.defaults = list(header     = T,
                                                     sep        = "\t", 
                                                     quote      = F,
                                                     na.strings = c("NA", "")
                                                     ))