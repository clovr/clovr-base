#!/usr/bin/perl
use strict;
use warnings;

#*********************************************************************
#  Metastats.pl*
#  *This program is designed to act as the interface on the front
#  of an R program.  The user inputs several options including a 
#  taxa abundance matrix file and a threshold for signficance 
#  testing. 

#  Author: james robert white, whitej@umd.edu  
#  Last modified: June 28, 2010 
#*********************************************************************
use Getopt::Std;
use warnings;

use vars qw/$opt_m $opt_p $opt_t $opt_b $opt_o/;

getopts("m:p:t:b:o:");

my $usage = "Usage:  $0 \
                -m matrix file in tab-delimited format\
                -p use pvalues if TRUE, use qvalues if FALSE\
                -t threshold level 0 < t < 1 (default 0.05)\
                -b number of bootstrap permutations used to estimate\
                   the null distribution (default 1000)\
                -o output prefix
                \n";

die $usage unless defined $opt_m
              and defined $opt_o;

# default parameter values
my $matrixfile = $opt_m;
my $thresh     = 0.05;
my $p          = "TRUE";
my $b          = 1000;
my $prefix     = $opt_o; 

#********************************************************************
#  split the prefix to get the counts
#********************************************************************
#$prefix -> ____________.$level.$g1\_vs_$g2.$g1count-$g2count.2tsv
my @prefsplit = split /\./, $prefix;
my @countstr = split "-", $prefsplit[$#prefsplit-1];
my $g = $countstr[0];

#********************************************************************
#  change parameters to user-defined and check to sanity
#********************************************************************
if (defined($opt_b)){
  $b = $opt_b;
}

if (defined($opt_t)){
  $thresh = $opt_t;
}

if (defined($opt_p)){
  $p = $opt_p;
}

if ($thresh <= 0 or $thresh >= 1){
  die "-t threshold must be between 0 and 1\n";
}


# first sanity check the file, make sure 
# 1. the names are good
# 2. the tab delimited format works
# 3. there aren't too many features for the visualization
# 4. there aren't too many samples for the visualization
# 5. the elements are integers and not something else

my $numsamples    = 0;
my $numfeatures   = 0;
my $numheadtitles = 0;
print "Performing sanity check of matrix file...\n";
open IN, "$matrixfile" or die "Cannot open your matrix file: $matrixfile!!\nGoodbye.\n";
my $ck = 0;
my $row = 1;
while(<IN>){
  chomp($_);
  my @A = split "\t", $_;
  if ($ck == 0){
    if ($A[0] ne ""){
      die "In your matrix file, the first element of the header row must be blank.\nGoodbye.\n";
    }
    $numheadtitles = $#A;
    for my $i (1 .. $#A){
      if (length($A[$i]) > 20){
        print "*Warning* Column $i has an oftly long header title...\n";
      }
    }
    $ck++; # done with the header line
    next;
  }else{
    if ($#A != $numheadtitles){
      die "*Warning* Matrix is inconsistent @ row $row ...\nGoodbye.\n";
    }
    if (length($A[0]) > 30){
      print "*Warning* Row $row has an oftly long feature name...\n";
    }
    for my $i (1 .. $#A){ # for each element in this row
      if ($A[$i] !~ /^\s*[\+\-]?\d+\s*$/){
        die "*Warning* Matrix is inconsistent @ row $row ...\nGoodbye.\n";
      }
      if ($A[$i] < 0){
        die "*Warning* Row $row has a negative number in it...\nGoodbye.\n";
      }
      if ($A[$i] < 0){
        die "*Warning* Row $row has a negative number in it...\nGoodbye.\n";
      }
    }
    $row++;
  }  
}
close IN;

$numfeatures = $row-1;
$numsamples  = $numheadtitles;
print 
"\n**Sanity check passed:
Filename: $matrixfile
Total number of features (rows): $numfeatures 
Total number of samples (columns): $numsamples
\n";

print "\n**Calling R to create figure...\n";
my $RPATH = "R";
my $gp1 = $g+1;
#********************************************************************
#  generate R batch template
#********************************************************************
open OUT, ">$prefix.in" or die "Can't open $prefix.in!\n";
print OUT 
#"source(\"/home/jwhite/Desktop/CloVR/Statistical/Metastats/Metastats1.0/detect_DA_features4_14_09.r\")
"detect_differentially_abundant_features <- function(jobj,g, pflag = NULL, threshold = NULL, B = NULL, outfile){

#*************************************
qflag = FALSE;
if (is.null(B)){
  B = 1000;
}
if (is.null(threshold)){
  threshold = 0.05;
}
if (is.null(pflag)){
  pflag = TRUE;
  qflag = FALSE;
}
if (pflag == TRUE){
  qflag = FALSE;
}
if (pflag == FALSE){
  qflag = TRUE;
}

#********************************************************************************
# ************************ INITIALIZE PARAMETERS ********************************
#********************************************************************************

#*************************************
Fmatrix <- jobj\$matrix;                   # the feature abundance matrix
taxa <- jobj\$taxa;                        # the taxa/(feature) labels of the TAM
nrows = nrow(Fmatrix);                   
ncols = ncol(Fmatrix);
Pmatrix <- array(0, dim=c(nrows,ncols));  # the relative proportion matrix
C1 <- array(0, dim=c(nrows,3));           # statistic profiles for class1 and class 2
C2 <- array(0, dim=c(nrows,3));           # mean[1], variance[2], standard error[3]   
T_statistics <- array(0, dim=c(nrows,1)); # a place to store the true t-statistics 
pvalues <- array(0, dim=c(nrows,1));      # place to store pvalues
qvalues <- array(0, dim=c(nrows,1));      # stores qvalues
#*************************************
#*************************************
#  convert to proportions
#  generate Pmatrix
#*************************************
totals <- array(0, dim=c(ncol(Fmatrix)));
for (i in 1:ncol(Fmatrix)) { 
  # sum the ith column 
  totals[i] = sum(Fmatrix[,i]);
}

for (i in 1:ncols) {   # for each subject
  for (j in 1:nrows) { # for each row
    Pmatrix[j,i] = Fmatrix[j,i]/totals[i];
  }
}


#********************************************************************************
# ************************** STATISTICAL TESTING ********************************
#********************************************************************************

if (ncols == 2){  # then we have a two sample comparison
  #************************************************************
  #  generate p values using chisquared or fisher's exact test
  #************************************************************
  for (i in 1:nrows){           # for each feature
    f11 = sum(Fmatrix[i,1]);
    f12 = sum(Fmatrix[i,2]);
    f21 = totals[1] - f11;
    f22 = totals[2] - f12;
    C1[i,1] = f11/totals[1];                       # proportion estimate
    C1[i,2] = (C1[i,1]*(1-C1[i,1]))/(totals[1]-1); # sample variance
    C1[i,3] = sqrt(C1[i,2]);                       # sample standard error
    C2[i,1] = f12/totals[2];
    C2[i,2] = (C2[i,1]*(1-C2[i,1]))/(totals[2]-1);
    C2[i,3] = sqrt(C2[i,2]); 

    #  f11  f12
    #  f21  f22  <- contigency table format
    contingencytable <- array(0, dim=c(2,2));
    contingencytable[1,1] = f11;
    contingencytable[1,2] = f12;
    contingencytable[2,1] = f21;
    contingencytable[2,2] = f22;

    if (f11 > 20 && f22 > 20){
      csqt <- chisq.test(contingencytable);
      pvalues[i] = csqt\$p.value;
    }else{
      ft <- fisher.test(contingencytable, workspace = 8e6, alternative = \"two.sided\", conf.int = FALSE);
      pvalues[i] = ft\$p.value;
    }
    
  }
  
  #*************************************
  #  calculate q values from p values
  #*************************************
  qvalues <- calc_qvalues(pvalues);

}else{ # we have multiple subjects per population

  #*************************************
  #  generate statistics mean, var, stderr    
  #*************************************
  for (i in 1:nrows){ # for each taxa
    # find the mean of each group
    C1[i,1] = mean(Pmatrix[i, 1:g-1]);  
    C1[i,2] = var(Pmatrix[i, 1:g-1]); # variance
    C1[i,3] = C1[i,2]/(g-1);    # std err^2 (will change to std err at end)
  
    C2[i,1] = mean(Pmatrix[i, g:ncols]);  
    C2[i,2] = var(Pmatrix[i, g:ncols]);  # variance
    C2[i,3] = C2[i,2]/(ncols-g+1); # std err^2 (will change to std err at end)
  }

  #*************************************
  #  two sample t-statistics
  #*************************************
  for (i in 1:nrows){                   # for each taxa
    xbar_diff = C1[i,1] - C2[i,1]; 
    denom = sqrt(C1[i,3] + C2[i,3]);
    T_statistics[i] = xbar_diff/denom;  # calculate two sample t-statistic
  }

  #*************************************
  # generate initial permuted p-values
  #*************************************
  pvalues <- permuted_pvalues(Pmatrix, T_statistics, B, g, Fmatrix);

  #*************************************
  #  generate p values for sparse data 
  #  using fisher's exact test
  #*************************************
  for (i in 1:nrows){                   # for each taxa
    if (sum(Fmatrix[i,1:(g-1)]) < (g-1) && sum(Fmatrix[i,g:ncols]) < (ncols-g+1)){
      # then this is a candidate for fisher's exact test
      f11 = sum(Fmatrix[i,1:(g-1)]);
      f12 = sum(Fmatrix[i,g:ncols]);
      f21 = sum(totals[1:(g-1)]) - f11;
      f22 = sum(totals[g:ncols]) - f12;
      #  f11  f12
      #  f21  f22  <- contigency table format
      contingencytable <- array(0, dim=c(2,2));
      contingencytable[1,1] = f11;
      contingencytable[1,2] = f12;
      contingencytable[2,1] = f21;
      contingencytable[2,2] = f22;
      ft <- fisher.test(contingencytable, workspace = 8e6, alternative = \"two.sided\", conf.int = FALSE);
      pvalues[i] = ft\$p.value; 
    }  
  }

  #*************************************
  #  calculate q values from p values
  #*************************************
  qvalues <- calc_qvalues(pvalues);

  #*************************************
  #  convert stderr^2 to std error
  #*************************************
  for (i in 1:nrows){
    C1[i,3] = sqrt(C1[i,3]);
    C2[i,3] = sqrt(C2[i,3]);
  }
}

#*****************************************************
# Use this code to print out results for all taxa
#*****************************************************
Total_matrix <- array(0, dim=c(nrows,9));
for (i in 1:nrows){
  Total_matrix[i,1]   = jobj\$taxa[i];
  Total_matrix[i,2:4] = C1[i,];
  Total_matrix[i,5:7] = C2[i,];
  Total_matrix[i,8]   = pvalues[i];
  Total_matrix[i,9]   = qvalues[i];
}

write(t(Total_matrix), outfile, ncolumns = 9, sep = \"\t\");

}

calc_twosample_ts <- function(Pmatrix, g, nrows, ncols)
{
C1 <- array(0, dim=c(nrows,3));  # statistic profiles
C2 <- array(0, dim=c(nrows,3)); 
Ts <- array(0, dim=c(nrows,1));

if (nrows == 1){
  C1[1,1] = mean(Pmatrix[1:g-1]);
  C1[1,2] = var(Pmatrix[1:g-1]); # variance
  C1[1,3] = C1[1,2]/(g-1);    # std err^2

  C2[1,1] = mean(Pmatrix[g:ncols]);
  C2[1,2] = var(Pmatrix[g:ncols]);  # variance
  C2[1,3] = C2[1,2]/(ncols-g+1); # std err^2
}else{
  # generate statistic profiles for both groups
  # mean, var, stderr
  for (i in 1:nrows){ # for each taxa
    # find the mean of each group
    C1[i,1] = mean(Pmatrix[i, 1:g-1]);  
    C1[i,2] = var(Pmatrix[i, 1:g-1]); # variance
    C1[i,3] = C1[i,2]/(g-1);    # std err^2

    C2[i,1] = mean(Pmatrix[i, g:ncols]);  
    C2[i,2] = var(Pmatrix[i, g:ncols]);  # variance
    C2[i,3] = C2[i,2]/(ncols-g+1); # std err^2
  }
}

# permutation based t-statistics
for (i in 1:nrows){ # for each taxa
  xbar_diff = C1[i,1] - C2[i,1]; 
  denom = sqrt(C1[i,3] + C2[i,3]);
  Ts[i] = xbar_diff/denom;  # calculate two sample t-statistic 
}

return (Ts);

}
calc_qvalues <- function(pvalues)
{
nrows = length(pvalues);

# create lambda vector
lambdas <- seq(0,0.95,0.01);
pi0_hat <- array(0, dim=c(length(lambdas)));

# calculate pi0_hat
for (l in 1:length(lambdas)){ # for each lambda value
  count = 0;
  for (i in 1:nrows){ # for each p-value in order
    if (pvalues[i] > lambdas[l]){
          count = count + 1;    
    }
    pi0_hat[l] = count/(nrows*(1-lambdas[l]));
  }
}

f <- unclass(smooth.spline(lambdas,pi0_hat,df=3));
f_spline <- f\$y;
pi0 = f_spline[length(lambdas)];   # this is the essential pi0_hat value

# order p-values
ordered_ps <- order(pvalues);
pvalues <- pvalues;
qvalues <- array(0, dim=c(nrows));
ordered_qs <- array(0, dim=c(nrows));

ordered_qs[nrows] <- min(pvalues[ordered_ps[nrows]]*pi0, 1);
for(i in (nrows-1):1) {
  p = pvalues[ordered_ps[i]];
  new = p*nrows*pi0/i;
  
  ordered_qs[i] <- min(new,ordered_qs[i+1],1);
}
# re-distribute calculated qvalues to appropriate rows
for (i in 1:nrows){
  qvalues[ordered_ps[i]] = ordered_qs[i];
}

################################
# plotting pi_hat vs. lambda
################################
# plot(lambdas,pi0_hat,xlab=expression(lambda),ylab=expression(hat(pi)[0](lambda)),type=\"p\");
# lines(f);

return (qvalues);
}
permuted_pvalues <- function(Imatrix, tstats, B, g, Fmatrix)
{
# B is the number of permutations were going to use!
# g is the first column of the second sample
# matrix stores tstats for each taxa(row) for each permuted trial(column)

M = nrow(Imatrix);
ps <- array(0, dim=c(M)); # to store the pvalues
if (is.null(M) || M == 0){
  return (ps);
}
permuted_ttests <- array(0, dim=c(M, B));
ncols = ncol(Fmatrix);
# calculate null version of tstats using B permutations.
for (j in 1:B){  
  trial_ts <- permute_and_calc_ts(Imatrix, sample(1:ncol(Imatrix)), g);
  permuted_ttests[,j] <- abs(trial_ts); 
}

# calculate each pvalue using the null ts
if ((g-1) < 8 || (ncols-g+1) < 8){
  # then pool the t's together!
  # count how many high freq taxa there are
  hfc = 0;
  for (i in 1:M){                   # for each taxa
    if (sum(Fmatrix[i,1:(g-1)]) >= (g-1) || sum(Fmatrix[i,g:ncols]) >= (ncols-g+1)){
      hfc = hfc + 1;
    }
  }
  # the array pooling just the frequently observed ts  
  cleanedpermuted_ttests <- array(0, dim=c(hfc,B));
  hfc = 1;
  for (i in 1:M){
    if (sum(Fmatrix[i,1:(g-1)]) >= (g-1) || sum(Fmatrix[i,g:ncols]) >= (ncols-g+1)){
      cleanedpermuted_ttests[hfc,] = permuted_ttests[i,];
      hfc = hfc + 1;
    }
  }

  #now for each taxa
  for (i in 1:M){  
    ps[i] = (1/(B*hfc))*sum(cleanedpermuted_ttests > abs(tstats[i]));
  }
}else{
  for (i in 1:M){
    ps[i] = (1/(B+1))*(sum(permuted_ttests[i,] > abs(tstats[i]))+1);
  }
}

return (ps);
}


#*****************************************************************************************************
# takes a matrix, a permutation vector, and a group division g.
# returns a set of ts based on the permutation.
#*****************************************************************************************************
permute_and_calc_ts <- function(Imatrix, y, g)
{
nr = nrow(Imatrix);
nc = ncol(Imatrix);
# first permute the rows in the matrix
Pmatrix <- Imatrix[,y[1:length(y)]];
Ts <- calc_twosample_ts(Pmatrix, g, nr, nc);

return (Ts);
}

load_frequency_matrix <- function(file)
{
  dat2 <- read.table(file,header=FALSE,sep=\"\t\");
  # load names 
  subjects <- array(0,dim=c(ncol(dat2)-1));
  for(i in 1:length(subjects)) {
    subjects[i] <- as.character(dat2[1,i+1]);
  }
  # load taxa
  taxa <- array(0,dim=c(nrow(dat2)-1));
  for(i in 1:length(taxa)) {
    taxa[i] <- as.character(dat2[i+1,1]);
  }

  dat2 <- read.table(file,header=TRUE,sep=\"\t\");
  # load remaining counts
  matrix <- array(0, dim=c(length(taxa),length(subjects)));
  for(i in 1:length(taxa)){
    for(j in 1:length(subjects)){ 
      matrix[i,j] <- as.numeric(dat2[i,j+1]);
    }
  }    
  
  jobj <- list(matrix=matrix, taxa=taxa)
        
  return(jobj);
}

jobj <- load_frequency_matrix(\"$matrixfile\")
detect_differentially_abundant_features(jobj, $gp1, pflag = \"$p\", threshold = $thresh, B = $b, outfile = \"$prefix.Rbatch.out.all\")\n";
close OUT;

#********************************************************************
#  run R batch template
#********************************************************************
system("$RPATH CMD BATCH $prefix.in $prefix.out"); 
	# creates $prefix.Rbatch.out.all
#********************************************************************
#  parse R batch output and report results
#********************************************************************
open OUT, ">$prefix.all.csv" or die "Can't open $prefix.all.csv!\n";
print OUT "Name\tmean(group1)\tvariance(group1)\tstd.err(group1)\tmean(group2)\tvariance(group2)\tstd.err(group2)\tpvalue\tqvalue\n";
close OUT;
`cat $prefix.Rbatch.out.all >>$prefix.all.csv`;

#Clean up!
`rm -f $prefix.Rbatch.out.*`;

