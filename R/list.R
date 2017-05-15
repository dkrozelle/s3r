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
  
  resp <- aws_cli(cmd)

  
  # check the aws response code to confirm success
  if(system('echo $?', intern = T) != "0"){
    stop('aws call did not return as expected') }
  
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
  
  resp
}