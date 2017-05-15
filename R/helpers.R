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
  
  if( length(list(...) ) == 0 ){
    path <- NA
  }else if( length(list(...)) > 1 ){
    path <- file.path(...)
    
  }else{
    path <- do.call(file.path, as.list(...))
  }
  
  if( !is.na(path) && startsWith(path, "s3://") ){
    path <- path
  }else if( !is.na(path) && check_vars("cwd") ){
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

relative_path_adjuster <- function(path){
  path
}

aws_cli <- function(cmd){
  cmd  <- paste(cmd, s3e$aws.args, s3e$profile)
  cmd  <- gsub(" +", " ", cmd)
  response <- list(content = system(cmd,       intern = T),
                   code    = system('echo $?', intern = T))
  
  if( response$code == 0 ){
    return(response)
  }else{
    message(paste('aws error code:', response$code))
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
    grepl("^[^ ]+$", uri),        # no spaces
    !grepl("\\/{2}.*\\/{2}", uri) # only one set of double "//"
  ))
}
