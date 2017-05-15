#' Write an object in memory to S3 using specified write function.
#'
#' @return character string for s3 uri where an object was written
#' @export
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
  
  on.exit(unlink(local.path))
  do.call(FUN, args = c(list(x, file = local.path), fun.args ))
  
  if( file.exists(local.path) ){
    cmd <- paste('aws s3 cp',
                 aws.args,
                 s3e$sse,
                 local.path,
                 s3.path
    )
    resp <- aws_cli(cmd)
    return(s3.path)
    
  }else{
    message('unable to write file')
    return()
  }
}

#' Helper function to build custom S3 object readers.
#' 
#' @return function
#' @export
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

#' Write an S3 table into R
#' 
#' @return character string for s3 uri where an object was written with write.table
#' @export
s3_put_table <- build_custom_put(FUN          = write.table, 
                                 fun.defaults = list(sep       = "\t", 
                                                     row.names = F, 
                                                     col.names = T, 
                                                     quote     = F))