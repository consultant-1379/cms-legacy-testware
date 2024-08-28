#!/usr/bin/perl  
use strict;
use CGI qw(:standard escapeHTML);
#use warnings;

##########################################
#               Setup vars               #
##########################################

my $home_dir     = "/opt/ericsson/atoss/tas/WR_CMS/results";
my $raw_pass_log = "/opt/ericsson/atoss/tas/WR_CMS/results/pass.txt";
my $pass_log     = "/opt/ericsson/atoss/tas/WR_CMS/results/pass1.txt";

my $logs_path    = $ARGV[0];
my $mailid       = $ARGV[1];
my $type         = "$ARGV[2]"."$ARGV[3]";

my $server       = `cat /etc/HOSTNAME`;
my $TIME         = `date +%Y%m%d%H%M`;
my $package      = "com.ericsson.cms.legacy";

chomp($server);
chomp($TIME);

my $file         = "$home_dir/Report_${server}_${type}_${TIME}.xml";
$file =~ s/[\n\s]+//g;

##########################################
#           Check params & env           #
##########################################

if ($#ARGV < 2) {
	die "usage $0: <log-dir-path> <user-id> <batch-type> [batch-id]";
}

if( !-d "$logs_path" ) {
	die "Given log files directory path $logs_path does not exist!";
}

if( !-w "$home_dir" ) {
	die "No write access to directory $home_dir!";
}

##########################################
#               Parse Logs               #
##########################################

`grep "PASSED"      $logs_path/* | grep "Test Case" >  $raw_pass_log`;
`grep "FAILED"      $logs_path/* | grep "Test Case" >> $raw_pass_log`;
`grep "DIE Message" $logs_path/*                    >> $raw_pass_log`;

`cat -tv $raw_pass_log | sed 's/\\^\\[\\[..m//g; s/\\^\\[\\[0m//g;' > $pass_log`;

my $passcount  = `cat $pass_log | grep "PASSED" | wc -l`;
my $failcount  = `cat $pass_log | grep "FAILED" | wc -l`;
my $nrcount    = `cat $pass_log | grep "DIE"    | wc -l`;
$passcount =~ s/[\n\s]+//g;
$failcount =~ s/[\n\s]+//g;
$nrcount   =~ s/[\n\s]+//g;
my $totalcount = $passcount + $failcount + $nrcount;

##########################################
#            Create JUnit XML            #
##########################################

open(DATAF, "<$pass_log") or die "cannot open file pass1.txt";
open(my $FILE, ">$file")   or die "Cannot open $file: $!";
print $FILE "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
print $FILE "<testsuites>\n";
print $FILE "<testsuite name=\"$type\" id=\"1\" tests=\"$totalcount\" time=\"0.0\" failures=\"$failcount\" timestamp=\"$TIME\" hostname=\"$server\" errors=\"$nrcount\" package=\"$package\">\n";
print $FILE "<properties>\n";
print $FILE "<property name=\"server\" value=\"$server\" />\n";
print $FILE "<property name=\"log.dir\" value=\"$logs_path\" />\n";
print $FILE "<property name=\"home\" value=\"$home_dir\" />\n";
print $FILE "<property name=\"mailid\" value=\"$mailid\" />\n";
print $FILE "</properties>\n";

my %failed_log_files = ();
my @tc_names = ();

while(<DATAF>) {
	my $test_case = $_;
	$test_case =~ s/\n+//g;
	my $tc_details = $test_case;
	$tc_details =~ s/.*\:\://g;
	$tc_details =~ m/(Test Case [\d\.A-Z]+)/i;
	my $tc_name = $1;
	$tc_details =~ m/(PASSED|FAILED|DIE)/;
	my $tc_status = $1;
	my $tc_time = $test_case;
	$tc_time =~ s/.*\.log\://g;
	$tc_time =~ s/\:\:.*//g;
	my $tc_log_file = $test_case;
	$tc_log_file =~ s/\:.*//g;
	$tc_log_file =~ s/\s+//g;

	push(@tc_names, $tc_details);
	print $FILE "<testcase name=\"$tc_name\" time=\"$tc_time\" classname=\"$package.$type\">\n";
	if ($tc_status ne "PASSED") {
		$failed_log_files{$tc_log_file} = $tc_log_file;
		print $FILE "<failure type=\"$tc_status\" message=\"$tc_details\">\n";
		print $FILE "Server: $server\n";
		print $FILE "\n";
		print $FILE "See log file for details.\n";
		print $FILE "$tc_log_file\n";
		print $FILE "\n";
		print $FILE "scp -oPort=2205 nmsadm\@$server.athtem.eei.ericsson.se:$tc_log_file .\n";
		print $FILE "</failure>\n";
	}
	print $FILE "</testcase>\n";
}

# Print name of each TC that was executed
print $FILE "<system-out>\n";
print $FILE join("\n", @tc_names);;
print $FILE "</system-out>\n";

# Print contents of Log files to JUnit XML file
if ($totalcount != $passcount) {
	print $FILE "<system-err>\n";
	for my $key ( keys %failed_log_files ) {
		print $FILE "Log File Location: $key\n";
		my $log_contents = `cat -v $key | sed 's/\\^\\[\\[..m//g; s/\\^\\[\\[0m//g;'`;
		print $FILE escapeHTML($log_contents);
		print $FILE "\n\n";
 	}
	print $FILE "</system-err>\n";
}

print $FILE "</testsuite>\n";
print $FILE "</testsuites>\n";

close($FILE); 
close(DATAF);

`rm $raw_pass_log $pass_log`;

print "Your JUnit XML report has been created $file \n"; 
