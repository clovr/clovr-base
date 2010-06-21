#! /usr/bin/perl

$temp;
$expected=`cat /tmp/expectedhosts.txt`;

open (MYFILE, '/tmp/hosts.txt');
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

