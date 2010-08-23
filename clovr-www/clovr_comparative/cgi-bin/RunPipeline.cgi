#!/usr/bin/perl
use strict;
use warnings;

sub read_and_write_temp_config_file ($);
sub invoke_pipeline ();
sub getRefSeqList ($);

my $refSeqFile = $ARGV[0];
my $mapFile = $ARGV[1];
my $genbankPath = $ARGV[3];
my $orgFilePath = $ARGV[4];
my $name = $ARGV[5];
my $pipeline = $ARGV[2];

my $CONFIG_FILE = "/opt/clovr_pipelines/workflow/project_saved_templates/".$pipeline."/".$pipeline.".config";
my $TEMP_CONFIG_FILE = $CONFIG_FILE."temp.config";

read_and_write_temp_config_file (getRefSeqList($refSeqFile));
invoke_pipeline();

exit(0);


sub read_and_write_temp_config_file ($) {
	my ($ref_seq_list) = @_;
	open(FH,"<$CONFIG_FILE") or die "Error in reading the config file, $CONFIG_FILE, $!\n";
	open(OFH,">$TEMP_CONFIG_FILE") or die "Error in writing to temp config file, $TEMP_CONFIG_FILE, $!\n";
	while(my $line = <FH>) {
		chomp $line;
		if($line =~ /^(INPUT_FILE=)/) {
			$line = $1.$ref_seq_list;
		}
		elsif($line =~ /^(ORGANISM_TO_DB_MAPPING=)/) {
			$line = $1.$mapFile;
		} 
		print OFH $line,"\n";
	}
	close FH;
	close OFH;
}

sub invoke_pipeline () {
	my $command = "runPipeline.py --name local --pipeline-name $name --pipeline clovr_wrapper -- --CONFIG_FILE $TEMP_CONFIG_FILE";
	system($command) == 0 or die "system $command failed, $?,\n";
}

sub getRefSeqList ($) {
	my ($file) = @_;
	my $refSeqInfo = '';
	open(FH,"<$file") or die "Error in opening the file, $file, $!\n";
	while(my $line = <FH>) {
		$refSeqInfo .= $line;
	}
	close FH;
	return $refSeqInfo;
}











