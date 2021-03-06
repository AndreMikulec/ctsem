#' ctStanPlotPost
#'
#' Plots prior and posterior distributions of model parameters in a ctStanModel or ctStanFit object.
#' 
#' @param obj fit or model object as generated by \code{\link{ctStanFit}},
#' \code{\link{ctModel}}, or \code{\link{ctStanModel}}.
#' @param rows vector of integers denoting which rows of obj$setup$popsetup to plot priors for. 
#' Character string 'all' plots all rows with parameters to be estimated. 
#' @param priorwidth if TRUE, plots will be scaled to show bulk of both the prior 
#' and posterior distributions. If FALSE, scale is based only on the posterior.
#' @param mfrow 2 dimensional integer vector defining number of rows and columns of plots,
#' as per the mfrow argument to \code{\link[graphics]{par}}.
#' 'auto' determines automatically, to a maximum of 4 by 4, while \code{NULL} 
#' uses the current system setting.
#' @param lwd line width for plotting.
#' @param parcontrol parameters to pass to \code{\link[graphics]{par}} which temporarily
#' change plot settings.
#' @param wait If true, user is prompted to continue before plotting next graph.  
#' If false, graphs are plotted one after another without waiting.
#' @examples
#' ctStanPlotPost(ctstantestfit, rows=3:4)
#' @export

ctStanPlotPost<-function(obj, rows='all', priorwidth=TRUE, mfrow='auto',lwd=2,
  parcontrol=list(mgp=c(1.3,.5,0),mar=c(3,2,2,1)+.2),wait=FALSE){
  
  if(!(class(obj) %in% c('ctStanFit','ctStanModel'))) stop('not a ctStanFit or ctStanModel object!')
  
  densiter <- 1e5
  popsetup <- obj$setup$popsetup
  popvalues<- obj$setup$popvalues
  
  paroriginal<-graphics::par()[c('mfrow','mgp','mar')]
  
  do.call(graphics::par,parcontrol)
  
  e<-extract.ctStanFit(obj)
  
  if(rows[1]=='all') rows<-which(!duplicated(obj$setup$popsetup$parname))
  
  if(all(mfrow=='auto')) {
    mfrow <- grDevices::n2mfrow( (length(rows)+sum(as.logical(obj$setup$popsetup$indvarying[rows]))*2))
    mfrow[mfrow > 3] <- 3
  }
  graphics::par(mfrow=mfrow)

  nsubjects<-obj$data$nsubjects 

  for(ri in rows){
    pname <- obj$setup$popsetup$parname[ri]
    pari <- obj$setup$popsetup[ri,'param']
    rawpopmeans<- e$rawpopmeans[,pari]
    param<-rawpopmeans
    popmeanspost<-tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])
   
    param<-stats::rnorm(densiter,0,1)
    meanprior <- tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])
  
    leg <- c('Pop. mean posterior','Pop. mean prior') 
    legcol <- c('black','blue') 
    
    ctDensityList(list(popmeanspost,meanprior),main=paste0(pname),
      xlimsindex=if(priorwidth) 1:2 else 1,
      xaxs='i',  yaxs='i', plot=TRUE,legend=leg,colvec=legcol,lwd=lwd)

    if(obj$setup$popsetup[ri,'indvarying']>0){ #then also plot sd and subject level pars

      sdscale <- obj$setup$popvalues[ri,'sdscale']
      sdtform <- gsub('.*', '*',obj$ctstanmodel$rawpopsdtransform,fixed=TRUE)
      
      rawpopsdbase<-e$rawpopsdbase[,popsetup$indvarying[ri]] 
      
      rawpopsd <- eval(parse(text=sdtform)) 
      
      param<-stats::rnorm(densiter,rawpopmeans,rawpopsd)
      subjectprior<-tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])

      if(!obj$data$ukfpop) {
        rawindparams<-e$baseindparams[,seq(popsetup$indvarying[pari],by=obj$data$nindvarying,length.out=obj$data$nsubjects)] *
          rawpopsd + rawpopmeans
        param<-rawindparams
        indparams<-tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])

        ctDensityList(list(indparams,subjectprior,meanprior),main=pname,
          colvec=c('black','red','blue'),plot=TRUE,lwd=lwd,xlimsindex=1:2,
          xaxs='i',  yaxs='i',legend=c('Subject param posterior','Subject param prior','Pop mean prior'))
      } else {
        ctDensityList(list(subjectprior,meanprior),main=pname,
          colvec=c('red','blue'),plot=TRUE,lwd=lwd,xlimsindex=1,
          xaxs='i',  yaxs='i',legend=c('Subject param prior','Pop mean prior'))
      }
      
      rawpopsdbase<-  stats::rnorm(densiter,0,1)
      rawpopsdprior <- eval(parse(text=sdtform)) #rawpopsd prior samples

      hsdpost <- e$popsd[,popsetup$param[ri]]

      param<-suppressWarnings(rawpopmeans+rawpopsdprior)
      high<-tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])
      param<-suppressWarnings(rawpopmeans-rawpopsdprior)
      low<-tform(param,popsetup$transform[pari],popvalues$multiplier[pari], popvalues$meanscale[pari],popvalues$offset[pari])
      hsdprior<-abs(high - low)/2

      leg <- c('Pop. sd posterior','Pop. sd prior') 
      legcol <- c('black','blue')
      # 
      # graphics::legend('topright',leg, text.col=legcol, bty='n')
      
      ctDensityList(list(hsdpost, hsdprior),main=paste0('Pop. sd ',pname),
        xlimsindex=1,
        xaxs='i',yaxs='i',plot = TRUE, colvec=legcol, legend=leg,lwd=lwd)
      
      
      
      
      # pmeans[,indvaryingcount]<-sum$summary[sumnames %in% 
      #     paste0(obj$pars$matrix[ri],'[',1:nsubjects,',',obj$pars$row[ri],
      #       if(!(obj$pars$matrix[ri] %in% c('T0MEANS','CINT','MANIFESTMEANS'))) paste0(',',obj$pars$col[ri]),']'),
      #   1]
      # 
      # pnames[indvaryingcount]<-paste0(obj$pars$matrix[ri],'[',obj$pars$row[ri],',',obj$pars$col[ri],']')
      
      
      if(wait==TRUE & ri != utils::tail(rows,1)){
        message("Press [enter] to display next plot")
        readline()
      }
    }
  }
  
  # if(length(rows)>1){
  #   require(lattice)
  #   colnames(pmeans)<-pnames
  #   splom(pmeans,
  #     upper.panel=function(x,y) panel.loess(x, y),
  #     diag.panel = function(x,...){
  #       yrng <- current.panel.limits()$ylim
  #       d <- density(x, na.rm=TRUE)
  #       d$y <- with(d, yrng[1] + 0.95 * diff(yrng) * y / max(y) )
  #       panel.lines(d)
  #       diag.panel.splom(x,...)
  #     },
  #     lower.panel = function(x, y, i,j){
  #       panel.splom(x,y,col=rgb(0,0,1,alpha=.2),pch=16)
  #       
  #       if( j==1)  panel.axis(side=c('left'),outside=T,
  #         at=round(seq(max(y),min(y),length.out=5)[c(-1,-5)],digits=3),tck=1,
  #         labels=round(seq(max(y),min(y),length.out=5)[c(-1,-5)],digits=3))
  #       
  #       if( i==ncol(pmeans))  panel.axis(side=c('bottom'),outside=T,
  #         at=round(seq(max(x),min(x),length.out=5)[c(-1,-5)],digits=3),tck=1,
  #         labels=round(seq(max(y),min(y),length.out=5)[c(-1,-5)],digits=3))
  #     },
  #     pscales=0,
  #     as.matrix = TRUE,
  #     varname.cex=.4,
  #     strip=T,
  #     main='Subject level parameter plots',
  #     xlab=NULL,ylab=NULL,
  #     col=rgb(0,0,1,alpha=.2),pch=16
  #   )
  # }
  
  do.call(graphics::par,paroriginal)
  
}

