#!/usr/bin/perl

$temp;
$expected=`cat /tmp/expected.txt`;

open (MYFILE, '/tmp/queues.txt');
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

