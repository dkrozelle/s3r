% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get.R
\name{build_custom_get}
\alias{build_custom_get}
\title{Helper function to build custom S3 object readers.}
\usage{
build_custom_get(FUN, fun.defaults = NULL)
}
\arguments{
\item{FUN}{function name, unquoted, used to read the file.}

\item{fun.args}{list of named arguments to pass to FUN}
}
\value{
function
}
\description{
Use this helper function to build custom reader tools. Define a function and 
associated arguments for reading into R and save as a reusable function.
}
