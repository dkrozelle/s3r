#' Configure s3r environment which stores S3 bucket metadata.
#'
#' This environment is required for all s3r functions. Sets bucket name,
#' defines and creates a local cache directory, tracks working directory. There are
#' no default function arguments on purpose, to enable you to call update individual
#' settings without explicitly changing previous settings. 
#'
#' @param bucket base name for s3 bucket e.g. "s3://bucket-name" or "bucket-name"
#' @param cwd character string path, optional to define a working prefix
#' @param local.cache character string, path of a local scratch directory. This will
#'                    be placed at /tmp/s3-cache when called the first time if none
#'                    is specified. 
#'
#' @return list, invisibly returns a list of environment variable settings
#' @export
s3_set <- function(
  bucket   = 's3r-test-bucket',
  profile  = 's3r-read-write-user',
  cache    = NULL,
  sse      = NULL,
  cwd      = NULL,
  aws.args = NULL){
  
  if( !exists("s3e", envir = globalenv()) ) s3e <<- new.env(parent = emptyenv())
  
  # profile --------------------------------------------------------------------
  # 
  # set the profile argument if anything other than a non-blank 
  # character string is specified
  
  if( !is.null(profile) ){
    if( is.character(profile) && profile != "" ){
      profile <- paste('--profile', profile, sep = "=")
      # check if this profile exists
      keys.found <- system(paste('aws configure list',
                                 profile,
                                 '| grep -e key | wc -l'), intern = T) == 2
      
      # check if these keys exist
      if( keys.found ) {
        s3e$profile <- profile
      }else{ 
        message('Please use \"aws configure --profile=NAME\" to set the',
                'access key and secret key you\'d like to use')
      }
      
    }else if( exists(s3e$profile) ){ 
      # remove if profile argument is a blank string
      rm(s3e$profile)
    }
  }
  
  
  # bucket  --------------------------------------------------------------
  if( !is.null(bucket) ){
    
    bucket <- gsub("(?:s3\\:\\/\\/)?([^\\/]*).*$", "s3://\\1", bucket)
    
    if( valid_uri(bucket) ){ 
      # when a new bucket is set, also set the cwd. if a new cwd is defined it
      # will be reset below.
      s3e$bucket <- s3e$cwd <- bucket
    }
    
  }else if( !check_vars("bucket") ){
    message('s3 bucket is a required parameter')
    return()
  }
  
  # local cache ----------------------------------------------------------------
  if( is.null(s3e$cache) && is.null(cache)) cache <- "."
  
  # define local directory to store get/put files
  # will attempt to create non-existant directories
  # trailing fsep is trimmed to allow easier file.path joining downstream
  if( !is.null(cache) ){
    s3e$cache <- gsub("\\/$", "", cache)
    if( !dir.exists(s3e$cache) ) dir.create(s3e$cache, recursive = T)
    if( !dir.exists(s3e$cache) ){
      s3e$cache <- NULL
      stop("local cache directory could  not be created")
    }
  }
  # working directory ----------------------------------------------------------
  if( !is.null(cwd) & is.character(cwd) ){
    s3e$cwd <- s3_cd(cwd)
  }else if( !check_vars("cwd") ){
    s3e$cwd <- s3_cd()
  }
  
  # other options --------------------------------------------------------------
  # remove the sse flag if anything other than TRUE is specified
  if( is.logical(sse)  && sse ){ s3e$sse <- "--sse"
  }else if( !is.null(sse) && exists("sse", envir = s3e) ){ rm(sse, envir = s3e) }
  
  # generic argument strings to be appended to ALL s3 calls
  # use this for default arguments not explicitly supported by s3r
  # 
  # we don't suggest using this for arguments that need to be differentially applied
  # to copy/move functions as to list/get functions. For example encryption scheme 
  # arguments passed to list functions cause an error, you should only use where 
  # appropriate.
  # 
  # for options like --dryrun mode we suggest setting these on individual calls
  # instead of here so they can be quickly removed  after you confirm proper usage
  if( !is.null(aws.args) ) s3e$aws.args <- aws.args
  

  invisible(sapply(ls(s3e), function(x){s3e[[x]]}))
}

#' Set the current working directory on S3
#' @return returns the new cwd value
#' @export
s3_cd <- function(...){
  
  if( !exists("s3e", envir = globalenv()) ){
    message('please use s3_set() before attempting to set cwd.')
    return()
  }
  
  # if any arguments, use them to set new cwd
  if( length(list(...)) > 0 ){
    # if arguments provided, set new cwd
    proposed.cwd <- build_uri(...)
  }else{
    # otherwise use default build_uri which creates from cwd or bucket
    proposed.cwd <- build_uri()
  }
  
  # check the cwd exists, aws_cli throws it's own error if does not exist
  cmd <- paste('aws s3 ls', proposed.cwd)
  
  response <- aws_cli(cmd)

  if( any(response == 1) ){
    message(paste('unable to set cwd, does', proposed.cwd, 'location exist?'))
    return(s3e$cwd)
  }else{
    s3e$cwd <- proposed.cwd
    return(s3e$cwd)
  }
}



