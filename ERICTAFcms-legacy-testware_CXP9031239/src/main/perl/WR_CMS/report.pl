#!/usr/bin/perl  
#use warnings; 
use Data::Dumper; 
use Sys::Hostname;

################################################
# File Location
###############################################

my $server = hostname;
my $home = "/opt/ericsson/atoss/tas/WR_CMS/results";
my $pass_log = "/opt/ericsson/atoss/tas/WR_CMS/results/pass.txt";
my $fail_log = "/opt/ericsson/atoss/tas/WR_CMS/results/fail.txt";
my $die_log = "/opt/ericsson/atoss/tas/WR_CMS/results/die.txt";
my $pass1_log = "/opt/ericsson/atoss/tas/WR_CMS/results/pass1.txt";
my $fail1_log = "/opt/ericsson/atoss/tas/WR_CMS/results/fail1.txt";
my $die1_log = "/opt/ericsson/atoss/tas/WR_CMS/results/die1.txt";
my $new_fail_log = "/opt/ericsson/atoss/tas/WR_CMS/results/failed_tests.sh";
my $failed_log = "/opt/ericsson/atoss/tas/WR_CMS/results/Tests_failed.sh";

my $logs_path = $ARGV[0];
my $mailid = $ARGV[1];
my $TIME = `date +%Y%m%d%H%M`;
my $type = "$ARGV[2]"."$ARGV[3]";
my $file = "Report_"."$server"."_"."$type"."_"."$TIME".".html";
my $fileBT = "Report_"."$server"."_"."$type".".html";

$file = "$home/"."$file";
$file =~ s/\n+//g;

###############################################
if ($#ARGV < 1) {
 	print "usage: pass the log files directory path as first argument and after that user to which report has to mail\n";
	print "usage: perl report.pl <log dir path> <user mail id> \n";
 	exit;
}


if( !-d "$logs_path" )
{
	die "Given log files directory path $logs_path does not exist...";
}
if( !-w "$home" )
{
	die "No write access to directory $home ..";
}

`grep "PASSED" $logs_path/* | grep "Test Case" >> $pass_log`;
`grep "FAILED" $logs_path/* | grep "Test Case" >> $fail_log`;
`grep "DIE Message" $logs_path/*  > $die_log`;

`cat -tv $pass_log | sed -e 's/\\^\\[\\[..m//g' |sed -e 's/\\^\\[\\[0m//g'  > $pass1_log`;
`cat -tv $fail_log | sed -e 's/\\^\\[\\[..m//g' |sed -e 's/\\^\\[\\[0m//g' > $fail1_log`;
`cat -tv $die_log | sed -e 's/\\^\\[\\[..m//g' |sed -e 's/\\^\\[\\[0m//g' > $die1_log`;

my $passcount = `cat $pass1_log | grep "Test Case" | wc -l`;
my $failcount = `cat $fail1_log | grep "Test Case" | wc -l`;
my $nrcount = `cat $die1_log | grep "DIE" | wc -l`;
$passcount =~ s/\n+//g; $failcount =~ s/\n+//g; $nrcount =~ s/\n+//g;

open(DATAF, "<$pass1_log") or die "cannot open file pass1.txt";
open(FAILF,"<$fail1_log") or die "cannot open file fail1.txt";
open(DIEF,"<$die1_log") or die "cannot open file die1.txt";
open(my $FILE, ">>$file") or die "Cannot open $file: $!"; ## >> means append to the end of file. 
print $FILE "<HTML>\n";
print $FILE "<table width=\"100%\">\n"; 
print $FILE "<tr><th colspan=\"1\" class=\"H25H\" BGCOLOR=\"#FFFF00\">Server : $server</th></tr> \n"; 
print $FILE "<tr><th colspan=\"1\" class=\"H25H\" BGCOLOR=\"#FFFF00\">LOG Directory: $logs_path</th></tr> \n"; 
print $FILE "</table>\n";
print $FILE "<br><br>\n"; 
print $FILE "<table width=\"100%\">\n"; 
print $FILE "<tr><th colspan=\"3\" class=\"H25H\" BGCOLOR=\"#FAF8CC\">Test Case Statistics</th></tr> \n"; 
print $FILE "<tr align=\"center\"><td width=\"33%\">PASS TC: $passcount</td><td width=\"33%\">FAIL TC: $failcount</td><td width=\"34%\">NO RESULT TC: $nrcount</td></tr>\n";
print $FILE "</table>\n";
print $FILE "<br><br>\n"; 
print $FILE "<table width=\"100%\">\n"; 
print $FILE "<tr><th colspan=\"3\" class=\"H25H\" BGCOLOR=\"#00C000\">PASSED TEST CASES</th></tr> \n"; 

while(<DATAF>) {
	my $dat = $_;
	$dat =~ s/\n+//g;
	my $col1 = $dat;
	$col1 =~ s/\:.*//g;
	$col1 =~ s/\s+//g;
  	$col1 =~ s/$logs_path\///g;
	my $col2 = $dat;
	$col2 =~ s/.*\.log\://g;
	$col2 =~ s/\:\:.*//g;
	my $col3 = $dat;
	$col3 =~ s/.*\:\://g;
	print $FILE "<tr><td width=\"70%\">$col3</td><td width=\"15%\">$col2</td><td width=\"15%\">$col1</td></tr>\n"; }
print $FILE "</table>\n";

print $FILE "<br><br>\n"; 

print $FILE "<table width=\"100%\">\n"; 
print $FILE "<tr><th colspan=\"3\" class=\"H25H\" BGCOLOR=\"#FF0000\">FAILED TEST CASES</th></tr> \n"; 
while(<FAILF>) {
	my $dat = $_;
	$dat =~ s/\n+//g;
	my $col1 = $dat;
	$col1 =~ s/\:.*//g;
	$col1 =~ s/\s+//g;
  	$col1 =~ s/$logs_path\///g;
	my $col2 = $dat;
	$col2 =~ s/.*\.log\://g;
	$col2 =~ s/\:\:.*//g;
	my $col3 = $dat;
	$col3 =~ s/.*\:\://g;
        `cut -f6 -d " " $fail_log > $new_fail_log`;
	print $FILE "<tr><td width=\"70%\">$col3</td><td width=\"15%\">$col2</td><td width=\"15%\">$col1</td></tr>\n"; }
print $FILE "</table>\n";

print $FILE "<br><br>\n"; 

print $FILE "<table width=\"100%\">\n";
print $FILE "<tr><th colspan=\"3\" class=\"H25H\" BGCOLOR=\"#0000FF\">NO RESULT TEST CASES</th></tr> \n";
while(<DIEF>) {
        my $dat = $_;
        $dat =~ s/\n+//g;
        my $col1 = $dat;
        $col1 =~ s/\:.*//g;
        $col1 =~ s/\s+//g;
  	$col1 =~ s/$logs_path\///g;
        my $col2 = $dat;
        $col2 =~ s/.*\.log\://g;
        $col2 =~ s/\:\:.*//g;
        my $col3 = $dat;
        $col3 =~ s/.*\:\://g;
	print $FILE "<tr><td width=\"70%\">$col3</td><td width=\"15%\">$col2</td><td width=\"15%\">$col1</td></tr>\n"; }
print $FILE "</table>\n";

print $FILE "<br><br>\n";

print $FILE "</html>\n";
close($FILE); 
close(DATAF);
close(FAILF);
close(DIEF);

##########################################
if (-f $new_fail_log) 
{
 open(NEW_FAIL, "<$new_fail_log") or die("Could not open log file"); 
 `rm $new_fail_log`;
 `echo "#!/bin/sh" > $failed_log`;
 if (@ARGV == 2)
 {
  foreach $line (<NEW_FAIL>)
  {
   chomp($line);
   if ($line =~ m/\d+\.\d+\.\d+\.\d+\.\d+$/)
   {
    `echo "/opt/ericsson/atoss/tas/WR_CMS/snad.pl -t $line " >> $failed_log`;
   }
   elsif ($line =~ m/\d+\.\d+\.\d+$/)
   {
    `echo "/opt/ericsson/atoss/tas/WR_CMS/nead.pl -t $line " >> $failed_log`;
   }
   else
   {
    `echo "Test case type can not be uniquely identified $line" >> $failed_log`;
   }
  }
 `mv $failed_log $logs_path`;
 }
 elsif (@ARGV == 4)
 {
  foreach $line (<NEW_FAIL>)
  {
   chomp($line);
   if ($ARGV[2] eq "CMS_PROXY_BATCH_")
   {
    `echo "/opt/ericsson/atoss/tas/WR_CMS/proxy.pl -t $line " >> $failed_log`; 
   }
   elsif ($ARGV[2] eq "CMS_MASTER_BATCH_")
   {
    `echo "/opt/ericsson/atoss/tas/WR_CMS/master.pl -t $line " >> $failed_log`;
   }
   else
   {
    `echo "Test case type can not be uniquely identified $line" >> $failed_log`;
   }
  }
 `mv $failed_log $logs_path`;
 }
close(NEW_FAIL);
}
else
{
 print "There are no failed test cases in this batch \n";
}
##########################################


if ($ARGV[2] =~ /BIT/)
   {
   print "Your $file -> $fileBT \n"; 

    `mv $file $fileBT`;
   }


`rm $pass_log $pass1_log $die1_log $fail1_log $die_log $fail_log`;
print "Your HTML report has been created $file \n"; 
