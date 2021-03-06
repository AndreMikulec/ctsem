% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ctStanModel.R
\name{ctStanModel}
\alias{ctStanModel}
\title{Convert a frequentist (omx) ctsem model specification to Bayesian (Stan).}
\usage{
ctStanModel(ctmodelobj, type = "stanct", indvarying = "all")
}
\arguments{
\item{ctmodelobj}{ctsem model object of type 'omx' (default)}

\item{type}{either 'stanct' for continuous time, or 'standt' for discrete time.}

\item{indvarying}{either 'all' or a logical vector of the same length as the number of
free parameters in the model. Generally it is much simpler to set 'all' and then restrict this
by modififying the output model object afterwards.}
}
\value{
List object of class ctStanModel
}
\description{
Convert a frequentist (omx) ctsem model specification to Bayesian (Stan).
}
\examples{
model <- ctModel(type='omx', Tpoints=50,
n.latent=2, n.manifest=1, 
manifestNames='sunspots', 
latentNames=c('ss_level', 'ss_velocity'),
LAMBDA=matrix(c( 1, 'ma1' ), nrow=1, ncol=2),
DRIFT=matrix(c(0, 1,   'a21', 'a22'), nrow=2, ncol=2, byrow=TRUE),
MANIFESTMEANS=matrix(c('m1'), nrow=1, ncol=1),
# MANIFESTVAR=matrix(0, nrow=1, ncol=1),
CINT=matrix(c(0, 0), nrow=2, ncol=1),
DIFFUSION=matrix(c(
  0, 0,
  0, "diffusion"), ncol=2, nrow=2, byrow=TRUE))

stanmodel=ctStanModel(model)


}
