#' Move objects in an S3 bucket.
#'
#' To recursively move or copy entire directories use the aws.args = "--recursive"
#'
#' @param to character vector or list
#' @param from character vector or list
#' @param aws.args character string of any additional values you need appended to this
#' aws.cli command line call.
#'
#' @return character, new location
#' @export
s3_mv <- function( from            = NULL,
                   to              = NULL,
                   allow.overwrite = FALSE,
                   aws.args        = NULL){
  .s3_move(verb = "mv",
           from = from, to = to,
           aws.args = aws.args, allow.overwrite = allow.overwrite)
}

#' @export
s3_cp <- function( from            = NULL,
                   to              = NULL,
                   allow.overwrite = FALSE,
                   aws.args        = NULL){
  .s3_move(verb = "cp",
           from = from,
           to   = to,
           aws.args = aws.args,
           allow.overwrite = allow.overwrite)
}


.s3_move <- function(verb      = NULL,
                     from      = NULL,
                     to        = NULL,
                     allow.overwrite = F,
                     aws.args = NULL){

  if( is.null(verb) || !(verb %in% c("mv", "cp", "sync")) ){
    message('function not called correctly')
  }

  if( is.null(to) | is.null(from) ){
    message('Where two s3 locations are required named to/from arguments are required')
    return(1)
  }

  from.path <- build_uri(from)
  to.path   <- build_uri(to)

  # check for missing, overwrite conditions
    if( !path_exists(from.path) ){
    message(paste('from=',from.path,'does not exist'))
    return(1)
  }else if( !allow.overwrite & path_exists(to.path) ){
    message(paste('to=',to.path,'exists and allow.overwrite=F'))
    return(1)
  }else{
     cmd <- paste('aws s3',
                 verb,
                 from.path,
                 to.path,
                 s3e$aws.args,
                 aws.args)

    response <- aws_cli(cmd)

    if( any(response == 1) ){
      message('unable to write file')
      return(1)
    }else{
      return(to.path)
    }
  }




}