#  -----------------------------------------------------------------------------
#' List objects in an S3 bucket.
#'
#' List the items in an S3 bucket. Lots of time-saving filters are built-in, including
#' the default use of a defined working directory and grep pattern matching. As with
#' all functions i nthis package, you must first define your environment with s3_set().
#'
#' @param x an object in R
#' @param FUN function used to write R-object to a file. Currently this is limited to 
#'                     functions in which accept the object and file as the first argument 
#'                    (e.g. write.csv(x, file) ). 
#' @param opts list arguments to pass to FUN (e.g. opts = list(quote = F, row.names = F))
#' @param ... character vector describing s3 location, this must end with a valid s3 object name
#' @param aws.args   character, special arguments for writing to s3
#'
#' @return
#' @export
#' 
s3_put_with <- function(x, FUN, ..., 
                        fun.args = NULL, aws.args = NULL) {
  
  if( !check_vars("cache") ){
    message('please define a local cache with s3_set(cache = "/tmp") before use')
    return()
  } 
  if( length(list(...)) == 0 ){ 
    message('missing required s3 object name (...)')
    return()
  }

  s3.path    <- build_uri(...) 
  local.path <- file.path(s3e$cache, basename(s3.path))
  
  # on.exit(unlink(local.path))
  do.call(FUN, args = c(list(x, file = local.path), fun.args ))
  
  if( file.exists(local.path) ){
    cmd <- paste('aws s3 cp',
                 aws.args,
                 s3e$sse,
                 local.path,
                 s3.path
    )
    resp <- aws_cli(cmd)
    return(resp)
    
  }else{
    message('unable to write file')
    return()
  }
}

build_custom_put <- function(FUN, fun.defaults = NULL){
  
  # returns an s3_put_with function using predefined file writer and args
  function(x, ..., fun.args = NULL, aws.args = NULL){
    
    if( length(fun.args) > 0){
      fun.args <- c(fun.args, fun.defaults[!names(fun.defaults) %in% names(fun.args)])
    }else{
      fun.args <- fun.defaults
    }
    
    do.call("s3_put_with", c(list(x = x, FUN = FUN), 
                             list(...) , 
                             list(aws.args = aws.args, fun.args = fun.args))
    )
  }
}


s3_put_table <- build_custom_put(FUN = write.table, 
                                 fun.defaults = list(sep       = "\t", 
                                                     row.names = F, 
                                                     col.names = T, 
                                                     quote     = F))