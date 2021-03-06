% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/move.R
\name{s3_mv}
\alias{s3_mv}
\title{Move objects in an S3 bucket.}
\usage{
s3_mv(from = NULL, to = NULL, allow.overwrite = FALSE,
  aws.args = NULL)
}
\arguments{
\item{from}{character vector or list}

\item{to}{character vector or list}

\item{aws.args}{character string of any additional values you need appended to this
aws.cli command line call.}
}
\value{
character, new location
}
\description{
To recursively move or copy entire directories use the aws.args = "--recursive"
}
