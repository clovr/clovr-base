#! /usr/bin/perl

$temp;
$expected=`cat /var/lib/hudson/qhosttest/expected`;

open (MYFILE, '/var/lib/hudson/qhosttest/queues');
while (<MYFILE>) {
    chomp;
    $temp=substr "$_",6; 
    $temp=~ tr/"//d;
    if ($expected =~ m/$temp/){
	print "match\n";
    }
    else{
	exit 1;
    }
   # print "$temp \n";
}
close (MYFILE); 

