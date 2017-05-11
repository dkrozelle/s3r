#  -----------------------------------------------------------------------------
#' List objects in an S3 bucket.
#'
#' List the items in an S3 bucket. Lots of time-saving filters are built-in, including
#' the default use of a defined working directory and grep pattern matching. As with 
#' all functions i nthis package, you must first define your environment with s3_set().
#'
#' @param ...  
#' @param recursive  logical, 
#' @param pattern    character,
#' @param list.names logical,
#' @param files.only logical,
#' @param dir.only   logical,
#' @param aws.args   character,
#' 
#' @return 
#' @export
s3_ls <- function( ... ,
                   recursive  = FALSE,
                   pattern    = NULL,
                   list.names = TRUE,
                   files.only = FALSE,
                   dir.only   = FALSE,
                   aws.args   = NULL){
  
  # preferentially use passed path argument path
  if( length(list(...)) > 0){
    # use defined path, not yet implemented
    path <- "arg"
    
    # append bucket name if necessary
    # this should be a function
    
  }else if( exists("wd", envir = s3e) && !is.null(s3e$wd) ){
    # use working directory
    path <- s3e$wd
  }else if( exists("bucket", envir = s3e) && !is.null(s3e$bucket) ){
    # use the bucket root
    path <- s3e$bucket
  }else {
    message("path not supplied and default bucket/working directory not defined")
  }
  
  print(paste('aws s3 ls',
               s3e$aws.args,
               aws.args,
               path))
}