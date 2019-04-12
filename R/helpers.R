

build_uri <- function(..., dir = F){
  if( !"s3e" %in% ls(envir = globalenv()) ){ 
    message('please use s3_set() before use.')
    return() }
  
  # logic
  # if ... argument used and starts with s3, use it
  # if ... argument used and has cwd, add cwd
  # if no ... and has cwd, use cwd
  # else warning
  
  path <- capture_path_args(...)

  if( !is.na(path) && grepl("^s3:\\/\\/", path) ){
    path <- path
  }else if( !is.na(path) && check_vars("cwd") ){
    path <- relative_path_adjustment(path)
    
    if( path == 1 ){return(1)}
    
  }else if( check_vars("cwd") ){
    path <- chomp_slash(s3e$cwd)
  }else{
    message("path not supplied and default bucket/working directory not defined")
    return(1)
  }
  
  # add terminal slash if dir = T
  if(dir){
    uri <- paste0(chomp_slash(path), .Platform$file.sep  )
  }else{
    uri <- chomp_slash(path)
  }

  # check before returning
  if( valid_uri(uri) ){ 
    return(uri)
  }else{
    message('valid uri was not able to be created')
    return(1)
  }
}

chomp_slash <- function(x){
  gsub("(.)\\/*$","\\1",x)
}

relative_path_adjuster <- function(path){
  path
}

aws_cli <- function(cmd){
  cmd  <- paste(cmd, s3e$aws.args, s3e$profile)
  cmd  <- gsub(" +", " ", cmd)
  
  if(s3e$create_command_log){
    write(cmd, file=file.path(s3e$cache, "command.log"), append=TRUE)
  }
  
  suppressWarnings(
    response <- system(cmd, intern = T)
  )
  if( any(length(response) == 0) ){
    return(1)
  }else{
    return(response)
  }
}

check_vars <- function(...){
  if( !exists("s3e", envir = globalenv()) ){
    message('please configure s3_set() before using other functions.')
    return(FALSE)
  }
  
  if( length(list(...)) > 0 ){ 
    bool <- sapply(list(...), function(x){
      exists(x, envir = s3e)
    })
    return( all(bool) )
  }else{
    return(FALSE)
  }
  
}

valid_uri <- function(uri){
  Reduce("&", list( 
    grepl("^s3:\\/\\/", uri),     # starts with "s3://"
    # grepl("^[^ ]+$", uri),        # no spaces
    !grepl("\\/{2}.*\\/{2}", uri) # only one set of double "//"
  ))
}

relative_path_adjustment <- function(path, wd = s3e$cwd){
  
  wd   <- chomp_slash(wd)
  path <- chomp_slash(path)
  
  if( grepl("^\\.\\..*", path) ){
    # make sure you have a higher directory
    if( wd == s3e$bucket ){
      message('invalid path, already in at the top of bucket')
      return(1)
    }else{
      relative_path_adjustment( path = gsub("^\\.\\.\\/*", "", path), wd = dirname(wd))
    }
  }else if( grepl("^\\/.*", path) ){
    relative_path_adjustment( path = gsub("^\\/", "", path), wd = s3e$bucket)
    
  }else if( grepl("^\\..*", path) ){
    relative_path_adjustment( path = gsub("^\\.\\/*", "", path), wd = s3e$cwd)
    
  }else{
    
    return(file.path(wd, path))
  }
}

capture_path_args <- function(...){
  # combine path elements, should accept separate objects, list, or a character vector
  if( length(list(...) ) == 0 ){
    path <- NA
  }else if( length(list(...)) > 1 ){
    path <- file.path(...)
  }else{
    path <- do.call(file.path, as.list(...))
  }
}


path_exists <- function(s3.path){
  cmd <- paste('aws s3 ls', paste0('"',s3.path,'"'))
  response <- aws_cli(cmd)

  if( any(response == 1) ){
    return(FALSE)
  }else{
    return(TRUE)
  }}

build_local_path <- function(name, unique_filename){
  
  if(unique_filename){
    files <- c(list.files(s3e$cache),name)
    # check if ther are any totally duplicate files
    if(any(duplicated(files))){
      # remove file extension before increment
      # this only takes off the last . extension
      
      no.ext <- gsub("^(.*)\\.(.*)$", "\\1", files)
      ext    <- gsub("^(.*)\\.(.*)$", "\\2", files)
      l      <- length(files)
      name <- paste(make.unique(no.ext)[l], ext[l], sep = ".")
    }
    
  }
  file.path(s3e$cache, name)
  
}

