extract.ctStanFit <- function(fit){
  if(class(fit)!='ctStanFit') stop('Not a ctStanFit object')
  if(class(fit$stanfit)=='stanfit') out <- rstan::extract(fit$stanfit)
  if(class(fit$stanfit)!='stanfit') out <- fit$stanfit$transformedpars
  out$Ygen[out$Ygen==99999] <- NA
  return(out)
}
