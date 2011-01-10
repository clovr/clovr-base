#!/usr/bin/perl
# Takes the wrapper pipeline name from the client
# runs another tasklet that runs JSON pipeline summary metric
# returns the task id to the client
# @author: Mahesh Vangala
###########################################################

use strict;
use warnings;
use CGI;

my $PIPELINE_NAME = 'pipeline_name';

print "Content-type: text/html \n\n";

my $q = new CGI;
my $params = $q -> Vars;

my $command = "vp-describe-task --show-all --block --no-print-polling `vp-run-metrics -t \"get-pipeline-conf $$params{$PIPELINE_NAME}\"`";

open(COMMAND, "$command |") or die "Error in executing the command, $command, $!\n";

my ($id, $cluster);

while(my $line = <COMMAND>) {
	if( $line =~ /PIPELINE_ID=(.+?)\\n/ ) {
		$id = $1;
	}
	if( $line =~ /CLUSTER_NAME=(.+?)\\n/ ) {
		$cluster = $1;
	}
}

close COMMAND;
die "Error in executing the command, $command, $!\n" if( $? );

print `vp-describe-task --show-all --block --no-print-polling \`vp-run-metrics -t --name $cluster \"run-JSON-pipeline-summary $id\"\``;

exit $?;
