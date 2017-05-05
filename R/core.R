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
s3_set_env <- function(bucket  = NULL,
                       profile = NULL,
                       cache   = NULL,
                       sse     = NULL,
                       wd      = NULL,
                       aws.args = NULL){
  # make a new environment in the top environment,
  # this will overwrite any non-environment variables named "e"
  if( !exists("s3e", envir = globalenv()) ) s3e <<- new.env(parent = emptyenv())

  # if set, these variables are appended to all s3 calls  
  if( !is.null(aws.args) ) s3e$aws.args <- aws.args
  
  # remove the profile argument if anything other than a non-blank 
  # character string is specified
  if( !is.null(profile) && is.character(profile) && profile != "" ){ 
    s3e$profile  <- paste("--profile", profile)
  }else if( !is.null(profile) ){
    s3e$profile  <- NULL
    }
  
  # remove the sse flag if anything other than TRUE is specified
  if( is.logical(sse )  && sse ){ s3e$sse <- "--sse"
  }else if( !is.null(sse) ){ s3e$sse <- NULL }

  # format the full bucket string
  if( !is.null(bucket) ){
    if( grepl("^s3:\\/\\/", bucket) ){
      s3e$bucket <- gsub("^s3:\\/\\/(.*)\\/*", 
                       "s3://\\1", bucket)  
    }else{
      s3e$bucket <- paste0("s3://", bucket)
    }
  }
  
  # define a default local cache here. 
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
  
  if( !is.null(wd) ){

  }
 
  # print current environment variables
  if( length(ls(s3e)) > 0 ){
  knitr::kable(data.table::rbindlist(
    lapply(ls(s3e), function(x){
      data.frame(var = x, 
                 val = s3e[[x]])
    })
  ))}
}
