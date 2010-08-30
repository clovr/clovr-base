
piechart <- function(infile, outprefix){

  MaxFeatures = 20;
  Counts <- read.table(infile, header = TRUE, sep = "\t");
  A <- Counts[2:ncol(Counts)];
  nrows = nrow(A);
  ncols = ncol(A);

  if (ncols > 13){
    return(0);
  }

  C <- array(0, dim=c(nrows,ncols));
  for (i in 1:nrows){
    for (j in 1:ncols){
          C[i,j] = A[i,j];
        }
  }
  samp_names <- names(Counts);
  colnames(C) <- samp_names[2:length(samp_names)];
  rownames(C) <- Counts[,1];
 
  fontsizethresh = 0.7; 
  COLORS = rainbow(nrows);
  for (i in 1:ncols){
    outname = paste(outprefix, samp_names[i+1],"pdf", sep="."); 
    pdf(outname, width=8, height=8);

    # if there are more than MAXfeatures, lets simplify it
    # take the most abundant features and create a final other feature
    R            <-rownames(C);
    SC           <- C[,i];
    B            <- cbind(R, SC);
    Correctedcol <- B;
    if (nrows > MaxFeatures){
      SB <- B[order(-SC),];      
      Correctedcol <- 0;
      Correctedcol <- SB[1:MaxFeatures-1,];
      othersum <- sum(as.numeric(SB[MaxFeatures:nrows, 2]));
      other <- c("Other", othersum);
      Correctedcol <- rbind(Correctedcol, other);     
      COLORS = rainbow(MaxFeatures);
    }

    pct <- round(as.numeric(Correctedcol[,2])/sum(as.numeric(Correctedcol[,2]))*100, digits=1);
    labls <- paste(Correctedcol[,1], pct, sep=":\n") # add percents to labels 
    labls <- paste(labls,"%", sep="");
    pie(as.numeric(Correctedcol[,2]), col=COLORS, labels=labls, main=samp_names[i+1], cex=fontsizethresh);
    dev.off()       
  }
}



