#!/usr/bin/perl

use strict;
use File::Basename; 
my $error=0;
my $ergatisdocs="/opt/ergatis/docs";
while ( my $line = <> ) {
    chomp($line);

    my $filename = basename($line); 
    if($filename =~ /([^\.]+)/) {
	my $component = "$1".".config";
	if (! -e "$ergatisdocs/$component")
	{
	    print "$line cannot be found in $ergatisdocs/ \n";
	    $error=1;
	}
	my $first_file = `grep '\$;' $line | cut -f 1 -d '=' | grep -v -P '^\;' | grep -v SKIP_WF_COMMAND | grep -v STAGEDATA | grep -v PREPROC | grep -v POSTPROC | grep -v COMPONENT_TWIG_XML | perl -ne 's/\\\$\;//g;print' | sort -u | perl -ne 's/\s+//g;print' > /tmp/file1`;
	my $second_file = `grep '\$;' $ergatisdocs/$component | cut -f 1 -d '='  | grep -v -P '^\;' | grep -v SKIP_WF_COMMAND | grep -v STAGEDATA | grep -v PREPROC | grep -v POSTPROC | grep -v COMPONENT_TWIG_XML | perl -ne 's/\\\$\;//g;print' | perl -ne 's/\s+//g;print' | sort -u > /tmp/file2`;
	my $diff = `diff --ignore-all-space --side-by-side /tmp/file2 /tmp/file1`;
	if( $? eq 0) { 
		print "OK. Component $ergatisdocs/$component MATCHES pipeline $line\n";
	}
	else  
	{
	    print "ERROR component $ergatisdocs/$component DOES NOT MATCH pipeline $line\n";
		print "$diff\n";
	    $error=1;
	}
	
    }
}
if($error){
	exit 1;
} 
         
