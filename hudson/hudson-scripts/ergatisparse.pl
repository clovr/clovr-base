#! /usr/bin/perl

use strict;
use File::Basename; 

while ( my $line = <> ) {
    chomp($line);

    my $filename = basename($line); 
    if($filename =~ /([^\.]+)/) {
	my $component = "$1".".config";
	if (! -e `/opt/ergatis/docs/$component`)
	{
	    print "$line cannot be found in /opt/ergatis/docs/ \n";
	    exit 1;
	}
	my $first_file = `grep '\$;' $line | cut -f 1 -d '=' | sort`;
	my $second_file = `grep '\$;' /opt/ergatis/docs/$component | cut -f 1 -d '=' | sort`;
	print "$line\n";
	if( $first_file == $second_file) { 
	    exit 0;
	}
	else  
	{
	    exit 1;
	}
	
    }
}
 
         
