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
my ($wrapper_id, $wrapper_cluster, $worker_name) = run_conf_command( $$params{$PIPELINE_NAME} );
my ($worker_id, $worker_cluster, $dont_want_it) = run_conf_command( $worker_name );

run_JSON_tasklet( $wrapper_id, "local" );
run_JSON_tasklet( $worker_id, $worker_cluster );

exit $?;

sub run_conf_command {

	my ($pipeline_name) = @_;
	my $command = "vp-describe-task --show-all --block --no-print-polling `vp-run-metrics -t \"get-pipeline-conf $pipeline_name\"`";

	open(COMMAND, "$command |") or die "Error in executing the command, $command, $!\n";

	my ($id, $cluster, $name);

	while(my $line = <COMMAND>) {
		if( $line =~ /PIPELINE_ID=(.+?)\\n/ ) {
			$id = $1;
		}
		if( $line =~ /CLUSTER_NAME=(.+?)\\n/ ) {
			$cluster = $1;
		}
		if( $line =~ /input\.PIPELINE_NAME=(.+?)\\n/ ) {
			$name = $1;
		}
	}

	close COMMAND;
	die "Error in executing the command, $command, $!\n" if( $? );
	return ($id, $cluster, $name);

}

sub run_JSON_tasklet {
	my ($id, $cluster) = @_;
	print `vp-describe-task --show-all --block --no-print-polling \`vp-run-metrics -t --name $cluster \"run-JSON-pipeline-summary $id\"\``;
}

