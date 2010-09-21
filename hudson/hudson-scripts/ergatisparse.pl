#!/usr/bin/perl

use strict;
use File::Basename; 
my $error=0;
while ( my $line = <> ) {
    chomp($line);

    my $filename = basename($line); 
    if($filename =~ /([^\.]+)/) {
	my $component = "$1".".config";
	if (! -e "/opt/ergatis/docs/$component")
	{
	    print "$line cannot be found in /opt/ergatis/docs/ \n";
	    $error=1;
	}
	my $first_file = `grep '\$;' $line | cut -f 1 -d '=' | grep -v SKIP_WF_COMMAND | perl -ne 's/\\\$\;//g;print' | sort -u | perl -ne 's/\s+//g;print' > /tmp/file1`;
	my $second_file = `grep '\$;' /opt/ergatis/docs/$component | cut -f 1 -d '='  | grep -v SKIP_WF_COMMAND | perl -ne 's/\\\$\;//g;print' | perl -ne 's/\s+//g;print' | sort -u > /tmp/file2`;
	my $diff = `diff --ignore-all-space --side-by-side /tmp/file1 /tmp/file2`;
	if( $? eq 0) { 
		print "$component OK in $filename\n";
	}
	else  
	{
	    print "ERROR $component NOT OK in $line\n";
		print "$diff\n";
	    $error=1;
	}
	
    }
}
if($error){
	exit 1;
} 
         
