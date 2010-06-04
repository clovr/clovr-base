#! /usr/bin/perl

$temp;
$expected=`cat /var/lib/hudson/qhosttest/expectedhosts`;

open (MYFILE, '/var/lib/hudson/qhosttest/hosts');
while (<MYFILE>) {
    chomp;
    $temp=substr "$_",6; 
    $temp=~ tr/"//d;
    if ($expected =~ m/$temp/){
	print "match\n";
    }
    elsif($temp == "global"){}
    else{
	exit 1;
    }
   # print "$temp \n";
}
close (MYFILE); 

