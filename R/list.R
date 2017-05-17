#' List objects in an S3 bucket.
#'
#' List the items in an S3 bucket. Lots of time-saving filters are built-in, including
#' the default use of a defined working directory and grep pattern matching. As with 
#' all functions i nthis package, you must first define your environment with s3_set().
#'
#' @param ...  
#' @param recursive  logical, when enabled lists all files under the defined 
#' directory. Currently the return is not optimal, and returns a root-based path 
#' independent of cwd. For example: cwd=s3"//bucket/one/two/three/ will return
#' s3_ls(".") as "one/two/three/file.txt" instead of the expected "file.txt"
#' @param pattern    character,
#' @param list.names logical,
#' @param files.only logical,
#' @param dir.only   logical, NOTE: does not work with recursive = T
#' @param aws.args   character,
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
  path <- build_uri(..., dir = T)
  
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
  
  if( full.names )        resp <- file.path(chomp_slash(path), resp)

  return(resp)
}