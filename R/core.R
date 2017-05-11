chomp_slash <- function(x){
  gsub("^\\/+|\\/+$","",x)
}

#  -----------------------------------------------------------------------------
#' Establish an environment which defines the current S3 bucket metadata.
#'
#' This environment is required for all of my S3... functions. Sets bucket name,
#' defines and creates a local cache directory, tracks working directory. There are
#' no default function arguments on purpose, to enable you to call update individual
#' settings without explicitly changing previous settings. 
#'
#' @param bucket base name for s3 bucket e.g. "s3://bucket-name" or "bucket-name"
#' @param wd character string path, optional to define a working prefix
#' @param local.cache character string, path of a local scratch directory. This will
#'                    be placed at /tmp/s3-cache when called the first time if none
#'                    is specified. 
#'
#' @return print details about current environment
#' @export
s3_set <- function(bucket  = NULL,
                   profile = NULL,
                   cache   = NULL,
                   sse     = NULL,
                   wd      = NULL,
                   aws.args = NULL){
  # make a new environment in the top environment,
  # this will overwrite any non-environment variables named "e"
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
  
  
  
  
  
  
  
  
  # bucket string --------------------------------------------------------------
  if( !is.null(bucket) ){
    if( grepl("^s3:\\/\\/", bucket) ){
      s3e$bucket <- gsub("^s3:\\/\\/(.*)\\/*", 
                         "s3://\\1", bucket)  
    }else{
      s3e$bucket <- paste0("s3://", bucket)
    }
    
    # make sure paths have a trailing file separator
    s3e$bucket <- paste0(chomp_slash(s3e$bucket), .Platform$file.sep )
  }
  
  # local cache ----------------------------------------------------------------
  if( is.null(s3e$cache) ) cache <- "/tmp/s3-cache"
  
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
  if( !is.null(wd) & !is.null(s3e$bucket) & is.character(wd) ){
    # coerce to fully qualified path
    if( startsWith(wd, s3e$bucket) ){
      s3e$wd <- wd
    }else{
      s3e$wd <- file.path(chomp_slash(s3e$bucket), chomp_slash(wd))
    }
    
    s3e$wd <- paste0(chomp_slash(s3e$wd), .Platform$file.sep )
  }
  
  # other options --------------------------------------------------------------
  # remove the sse flag if anything other than TRUE is specified
  if( is.logical(sse)  && sse ){ s3e$sse <- "--sse"
  }else if( !is.null(sse) ){ s3e$sse <- NULL }
  
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
  
  # print current environment variables ----------------------------------------
  if( length(ls(s3e)) > 0 ){
    knitr::kable(data.table::rbindlist(
      lapply(ls(s3e), function(x){
        data.frame(var = as.character(x), 
                   val = as.character(s3e[[x]]))
      })
    ))}
  
}
