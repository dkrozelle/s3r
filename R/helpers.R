#  -----------------------------------------------------------------------------
#' Build an S3 uri
#'
#' Internal function to quick ly generate fully formed uris from partial
#' uri fragments.
#'
#' @param ...  components of a uri that you'd like to build
#' 
#' @return character string uri
#' @export
build_uri <- function(..., dir = F){
  if( !"s3e" %in% ls(envir = globalenv()) ){ 
    message('please use s3_set() before use.')
    return()
  }
  
  # logic
  # if ... argument used and starts with s3, use it
  # if ... argument used and has cwd, add cwd
  # if no ... and has cwd, use cwd
  # else warning
  
  new.path <- ( length(list(...) ) > 0 )
  
  # always prefer the provided path over cwd
  if( new.path ){
    # TODO: chomp each argument before passing on to file.path
    path <- file.path( ... ) }
  
  if( new.path && startsWith(path, "s3://") ){
    path <- path
  }else if( new.path && check_vars("cwd") ){
    path <- file.path(chomp_slash(s3e$cwd), chomp_slash(path))
  }else if( check_vars("cwd") ){
    path <- chomp_slash(s3e$cwd)
  }else{
    message("path not supplied and default bucket/working directory not defined")
    return()
  }
  
  # add terminal slash if dir = T
  if(dir){
    uri <- paste0(chomp_slash(path), .Platform$file.sep  )
  }else{
    uri <- chomp_slash(path)
  }
  
  if( valid_uri(uri) ){ 
    return(uri)
  }else{
    message('valid uri was not able to be created')
    return()
  }
}

chomp_slash <- function(x){
  gsub("^\\/+|\\/+$","",x)
}

relative_path_adjuster <- function(){
  
}



