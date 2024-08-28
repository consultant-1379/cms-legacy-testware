#!/usr/bin/perl

use warnings;



#### erbstype is used for test cases to select macro erbs's, pico erbs's or both
#### This is needed due to the fact that both pico and macro erbs's both contain the EnodeBFunction mo
#### To change from MACRO to PICO or BOTH uncomment the line below 

####my $erbstype = "PICO";
my $erbstype = "MACRO";
####my $erbstype = "BOTH";

#####################################
#
# Log Entry Sub Routine
#
#####################################

sub log_registry
{
   my $log_t= $_[0];
   my @log_content = split ('\n',$log_t);
   my $entry_time = get_time_string();
   print LOGFILE ("\n$entry_time :: $log_content[0]");
   for(my $count = 1; $count <= $#log_content ; $count++)
   {
      print LOGFILE ("\n\t\t       $log_content[$count]");
   }
}

sub check_areas
{
  my ($mo) = @_;
  my @fdns = ("SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=2",
    "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=2,ServiceArea=398",
    "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,LocationArea=2,RoutingArea=102"
    );
  my @attributes = ("locationAreaRef","serviceAreaRef","routingAreaRef");
  for(my $idx = 0; $idx < 3; $idx++)
  {
    my %result = get_mo_attributes_CS( mo => $mo, attributes => $attributes[$idx]);
    my $refer = $result{$attributes[$idx]};
    if ($refer and ($refer eq $fdns[$idx]))
    { 
      log_registry("this is working ");
}
  }
}


sub check_snad_log
{
  my ($testcase_logfile_snad, $test_slogan, $expected_error) = @_;
  my @all_snad_errors = `egrep \"$errors_to_find\" $snad_log`;             # find ERROR strings in SNAD log
  return "OK" if $expected_error and expected_error_OK($expected_error, @all_snad_errors); # found at least one wanted error, and all errors are as expected

   log_registry("Before call is made $testcase_logfile_snad ");

   $testcase_logfile_snad = get_logfile_name("snad", $test_slogan);

   log_registry("After call is made $testcase_logfile_snad ");

  if (@all_snad_errors)  # one or more errors was found
  {
# save a copy of the current SNAD log
    $testcase_logfile_snad = get_logfile_name("snad", $test_slogan);
    system("cp $snad_log $testcase_logfile");
    return;
  }
  else
  {     unlink $testcase_logfile_snad; # remove logfile
        return "OK"; }
}


sub expected_error_OK    ### needs a rehash.... some times errors MAY be present, but their absence is NOT a fault...
{
   my ($expected_error, @error_list) = @_;

   my @wanted_errors = grep { /$expected_error/ } @error_list;  # find errors that are expected
   if (@wanted_errors and @wanted_errors == @error_list)        # found at least one wanted error, and all errors are as expected
   {
      return "OK";
   }
   else
   {
      return;
   }
}


sub continuous_restart_rnc_netsim
{
  my $RNC01 = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01";
  my ($result, $sim, $node) = get_sim_info("SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");
  if ($result)
  {
    log_registry("Error code is $result, error message is $result_code_NE{$result}");
    return;
  }
  else
  {
    log_registry("Sim is $sim\nNode is $node");
  }
  my $result_command = do_netsim_command('.stop', $RNC01,$sim, $node);
  if ($result_command)  {
        log_registry("result = $result_command");
}
  check_status_for_5_minutes();

#do check here
  my ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
  log_registry("Warning => It seems count of Dead/Unsynched nodes are not available...") if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes") if ($dead_nodes ne "NONE");
  do_netsim_command(".start",$RNC01,$sim,$node);
}


sub path_to_managed_component
{
  my $mc = shift;
  my $boot_path = `grep BOOTPATH= /opt/ericsson/nms_umts_$mc/bin/start*.sh` or return;
  log_registry(" It seems no BOOTPATH variable set in /opt/ericsson/nms_umts_$mc/bin/start*.sh file...") if not $boot_path;
  return "" if not $boot_path;
  chomp($boot_path);
  $boot_path =~ s/BOOTPATH=//;
  my $trace_path = `grep TRACEPATH= $boot_path/cxc.env` or return;
  log_registry(" It seems no TRACEPATH variable set in $boot_path/cxc.env file...") if not $trace_path;
  return "" if not $trace_path;
  chomp($trace_path);
  $trace_path =~ s/TRACEPATH=//;
  return $trace_path;
}



sub create_cell_next_rnc_valid
{
my $external_mo;
my $max_cells = 1;
my $cell_prefix = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC02,MeContext=RNC02,ManagedElement=1,RncFunction=1,UtranCell=cc_valid";
my ($lac, $rac, $sac) = (2, 102, 398);
my $iubLinkRef = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC02,MeContext=RNC02,ManagedElement=1,RncFunction=1,IubLink=10";
my ($ul, $dl) = (112, 437);
my @cells;
my $first_cell = 2007;
for my $cell ($first_cell...($first_cell + $max_cells - 1))
{
   push @cells, "$cell_prefix-$cell";
   $external_mo = "$cell_prefix-$cell";
   log_registry("$cstest  cm $cell_prefix-$cell -attr cId $cell userLabel cc-$cell localCellId 0 tCell 0 uarfcnUl $ul uarfcnDl $dl primaryScramblingCode 0 lac 2 sac 127 sib1PlmnScopeValueTag 0 utranCellIubLink $iubLinkRef");
    my $create_result = create_mo_CS( mo =>"$cell_prefix-$cell", attributes =>"cId $cell userLabel cell-$cell uarfcnUl $ul uarfcnDl $dl  lac $lac sac $sac utranCellIubLink $iubLinkRef");
    if ($create_result)
    {
        log_registry("TC1.20 has failed, could not create utran cells on next rnc");
	test_failed($test_slogan);
	return;
    }
}
# verify the cells have been updated in the vaild if the activate was successful, test fails if not..
#should delete planned area after activation

 foreach (@cells)
   {
#create_external relation

     my $check_res =  does_mo_exist($_);
    if (!$check_res == $result_code_CS{MO_ALREADY_EXISTS})
    {      test_failed($test_slogan);

    return;
    }
}
return $external_mo;
}


sub delete_onecell_valid
{

my $mo = shift;
my  $result = delete_mo_CS( mo => $mo);
return if $result;
my $mo_result = does_mo_not_exist($mo);
return $mo_result;
}

sub does_mo_exist
{
   my $mo = shift;
    my $attempts      = 0;
   my $max_attempts  = 10;
   my $time_to_sleep = 6;
   my $result;
do {
      return $result if $attempts++ > $max_attempts;
      $result =  does_mo_exist_CS( mo => $mo );
      sleep $time_to_sleep if $time_to_sleep;
      log_registry("checking mo exist or not ");
   } until $result = $result_code_CS{MO_ALREADY_EXISTS};
  return $result; 
}

sub does_mo_not_exist
{
    my $mo = shift;
    my $attempts      = 0;
   my $max_attempts  = 10;
   my $time_to_sleep =6;
   my $result;
do {
      return $result if $attempts++ > $max_attempts;
      $result =  does_mo_exist_CS( mo => $mo );
      sleep $time_to_sleep if $time_to_sleep;
      log_registry("checking mo doesn't exist ");
   } until $result =$result_code_CS{MO_DOESNT_EXIST};

  return $result;
}

sub get_mec
{
   my $element = $_[0];
   my @temp_arr = split("\,",$element);
   my $mec = "";
   my $alert = 0;
   my $comma = 0;
   my $mm;
   foreach $mm (@temp_arr)
   { 
	if($alert == 0)
  	{
		if($comma > 0){ $mec = "$mec"."," ; }
		$mec = "$mec"."$mm";
	}
	if($mm =~ /MeContext/) { $alert = 1;  }
	$comma++;
   }
   return $mec;
}

sub get_logfile_name
{
   my ($snad_or_nead, $test_slogan) = @_;
   my $test_sl = $test_slogan;
   $test_sl =~ s/\s/\_/g;
   my ($min, $hour, $day, $month, $year) = (localtime)[1..5];
   my $output_log = sprintf "$log_dir/$snad_or_nead-%d%02d%02d-%02d%02d-$test_sl.log", $year+1900, $month+1, $day, $hour, $min;
   return $output_log;
}

sub get_review_cache_MOs
{
  my $review_log = "/tmp/review_cache_$$.log";
  my $rand = int (rand (65534)); # hope not to collide with others 

  `$review_cache > $review_log`;

  my $file_name = `grep SNAD_C $review_log`;
  log_registry("There is no SNAD entry in $review_log ...") if not $file_name;
  return "NONE" if not $file_name;
  chomp($file_name);
  `mv $file_name $review_log`;
  my $review_cache_result = `head -8 $review_log`;
  log_registry("$review_cache_result ");
  my ($master_MOs, $proxy_MOs, $unmanaged_MOs) = $review_cache_result =~ m/MASTER MOs : (\d+)\nPROXY MOs : (\d+)\nUNMANAGED MOs : (\d+)/;
  log_registry("master_MOs=$master_MOs, proxy_MOs=$proxy_MOs, unmanaged_MOs=$unmanaged_MOs");
#  unlink $review_log;
   my $test_sl = $test_slogan;
   $test_sl =~ s/\W+//g;
   $test_sl =~ s/[a-zA-Z]//g;
   $test_sl =~ s/\_+/\_/g;
   $test_sl = "_review_cache_"."$test_sl";
  `mv $review_log /var/tmp/RC$test_sl.$rand`;
  return ($master_MOs,$proxy_MOs,$unmanaged_MOs);
}

sub get_time_string
{
   my ($sec,$min, $hour, $day, $month, $year) = (localtime)[0..5];
   my $cur_time = sprintf("%4d-%02d-%02d %02d:%02d:%02d",$year+1900 , $month+1 , $day , $hour , $min , $sec);
   return $cur_time;
}

sub online_and_stop_rnc
{
my $RNC01 = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01";
# online cms don't wait for result
 my $mc = "cms_nead_seg";
my $operation = "online"; 

my $time_to_sleep = 2;
   log_registry("Turning $mc $operation");
   system("$smtool $operation $mc");
   my ($result, $sim, $node) = get_sim_info("SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");
if ($result)
{
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
#testcase failed
return;
}
else
{
   log_registry("Sim is $sim");
   log_registry("Node is $node");
}

#stoping rnc in netsim while function onlines 
 $result = do_netsim_command('.stop', $RNC01);
   my %status = ( offline => "offline",
		  online  => "started");
   my $attempts      = 0;
   my $max_attempts  = 10;

   do {
      return if $attempts++ > $max_attempts;
      $result = `$smtool -l | egrep $mc`;
      sleep $time_to_sleep if $time_to_sleep;
      log_registry("Trying to $operation:     $result");
   } until $result =~ m/$mc\s+$status{$operation}/;

  # return "OK";
log_registry("Waiting for 6 minutes");
sleep(360);
my  ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
log_registry("It seems count of Dead/Unsynched nodes are not available...") if ($dead_nodes eq "NONE");
log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes") if ($dead_nodes ne "NONE");
log_registry("doing start  node");
do_netsim_command(".start", $RNC01, $sim, $node);
return;
}

sub pick_a_MasterMO
{
  my $motype = shift;
  my $result = `$cstest -s $region_CS lt $motype'`;
  my @mos = split /\012/, $result;
  my $pick = "$mos[int (rand ($#mos + 1))]"; 
  my $count = ($#mos + 1);
  log_registry("$count found");
  log_registry("Selecting: $pick");
  return ($pick);
}




sub pick_an_LA  # NOT READY
{
  my $rnc = shift;
  my  $result = `$cstest -s $segment_CS lm $rnc -l 1 -f '\$type_name==LocationArea'`;
  my @cells = split /\012/, $result;
  my $pick = "$cells[int (rand ($#cells + 1))]"; 
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count LA(s) found in $rnc");
  log_registry("Selecting LA: $pick");
  return ($pick);
}


sub pick_an_SA    # UNDER AN LA NOT READY
{
  my $la = shift;
  my  $result = `$cstest -s $segment_CS lm $la -l 1 -f '\$type_name==ServiceArea'`;
  my @cells = split /\012/, $result;
  my $cell_count = ($#cells + 1);
  if ($cell_count == 0)
  { 
    return();
  }
  else
  {
    my $pick = "$cells[int (rand ($#cells + 1))]";
    log_registry("$cell_count SA(s) found in $la");
    log_registry("Selecting SA: $pick");
    return ($pick);
  }
}

sub pick_an_RA    # UNDER AN LA NOT READY
{
  my $la = shift;
  my  $result = `$cstest -s $segment_CS lm $la -l 1 -f '\$type_name==RoutingArea'`;
  my @cells = split /\012/, $result;
  my $cell_count = ($#cells + 1);
  if ($cell_count == 0)
  { 
    return();
  }
  else
  {
    my $pick = "$cells[int (rand ($#cells + 1))]";
    log_registry("$cell_count RA(s) found in $la");
    log_registry("Selecting RA: $pick");
    return ($pick);
  }
}

sub pick_an_rnc()
{
  my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  my $version = shift; # To select a OLD RNC/NEW RNC (Optional Choice)
  my $mec; 
  for my $rrr (@rncs)
  {  
    my $num = int(rand($#rncs + 1));
    $mec = "$rncs[$num]"; 
    my $mecontext = get_mec($mec);
    my %result = get_mo_attributes_CS( mo => $mecontext, attributes => "neType");
    my $neType = $result{neType};
    if (($neType ne "5") and ($mec !~ /CMSAuto/))#Don't pick a TDRNC for now stay we want RNC that are connected and synched 
    {
	my $sync = get_synch_status($mec);
   	if ($sync == 3 )
   	{      
                my $ick = $mec;
                my $ip = real_node_check($ick);
                log_registry("$ick is a real node so would not be selected..") if ($ip =~ /^159/);
                log_registry("Selecting NE: $ick") if ( $ip and !($ip =~ /^159/) );
		my $ver = node_version($mecontext) if $version;	
                return ($ick) if ( $ip and !($ip =~ /^159/) and !($version));
		return ($ick) if ( $ip and !($ip =~ /^159/) and $version and ($ver eq $version));
   	} 
    }
  } 
  return; # no syncd node found 
}


sub get_newer_nodes
{
  	my @all_nodes = @_;
	log_registry("number of nodes... $#all_nodes");

	@all_nodes = grep { $_ =~ "LTE05" } @all_nodes;
	@all_nodes = grep { $_ =~ "LTE06" } @all_nodes;

	log_registry("here $#all_nodes");
	return @all_nodes;
}


sub pick_a_ne
{
  my $ne = $_[0];
  my $mo = $_[1];
  my $ver = $_[2];
  
  my @nes;

  $ver = $mo if (!($ver) and $mo and (($mo eq "NEW") or ($mo eq "OLD") or ($mo =~ /\w\w\.\d+\.\d+/)));
  $mo = "" if ($ver and $mo and (($mo eq "NEW") or ($mo eq "OLD") or ($mo =~ /\w\w\.\d+\.\d+/)));
  
  @nes = get_mo_list_for_class_CS ( mo  => "$ne");

 # log_registry("here @nes ");

  # New function to help speed things up
  #log_registry("going to new nodes...") if ($ver eq "NEW");
  #@nes = get_newer_nodes(@nes) if ($ver eq "NEW");
  #log_registry("out ...$#nes ; @nes ");

  my $mec;
  my $flag = 0;
  my @NE;
  push (@NE, @nes);

  for my $rrr (@nes)
  {
    my $random_index = int (rand ($#NE + 1));
    $mec = splice(@NE, $random_index, 1);
    my $mecontext = get_mec($mec);

    if (!(grep {$_ =~ $mecontext}@NE))
    {
    	my %result = get_mo_attributes_CS( mo => $mecontext, attributes => "neType");
    	my $neType = $result{neType};
    	
    	return "0" if not $neType;

    	if (($neType ne "5") and ($mec !~ /CMSAuto/))      # Don't pick a NE which type is equal to 5
    	{
           ##### If erbstype is set to PICO then ne type cannot be 4 (MACRO erbs type) 
           ##### If erbstype is set to MACRO then ne type cannot be either 32 (PICO erbs type) or 42(DG2 erbs type)
           ##### All other ne types are let through 
           if ((($neType ne "4") and ($erbstype eq "PICO")) or ((($neType ne "32") and ($neType ne "42") and ($neType ne "45")) and ($erbstype eq "MACRO")) or ($erbstype eq "BOTH"))
           {
                log_registry("STARTING here : ne type is $neType (MACRO erbs type) ");
   	   	my $sync = get_synch_status($mec);
   	   	if ($sync == 3 )
   	   	{
                	my $ick = $mec;
			my $ip = real_node_check($ick);
			log_registry("$ick is a real node so will not be selected for test case..") if ($ip =~ /^159/);
                	log_registry("1. Selecting NE: $mecontext") if ( $ip and !($ip =~ /^159/) );
			my $version = node_version($mecontext,$ver) if $ver;
			if($mo and $ip and !($ip =~ /^159/))
			{
	                	log_registry("1. $mo and $ip and !($ip =~ /^159/ ");
				my $mo_exist = pick_a_mo("$ick","$mo");	
				return $ick if ($mo_exist and !($ver));
				return $ick if ($mo_exist and $ver and ($version =~ /$ver/));
			}
	                #log_registry(" MO !($mo) and $ip and !($ip =~ /^159/) and !($ver) ");
	                #log_registry(" MO !($mo) and $ip and !($ip =~ /^159/) and $ver and ($version =~ /$ver/)");
                	return ($ick) if ( !($mo) and $ip and !($ip =~ /^159/) and !($ver));
			return ($ick) if ( !($mo) and $ip and !($ip =~ /^159/) and $ver and ($version =~ /$ver/));
	                log_registry("1. help. $version : $ver : $mo : $ip ");
           	}
           }
    	}
     }
     $this++;
  }
  return; # no syncd node found
}

sub real_node_check
{
    my $ne = shift;
    my $meContext = get_mec($ne);
    my %meContext_data  =  get_mo_attributes_CS(mo => $meContext, attributes => "ipAddress");
    return "0" unless %meContext_data;
    
    # eeitjn patch to get automation to deal with ipV6 addresses.....

    if (exists $meContext_data{ipAddress} and $meContext_data{ipAddress} !~ m/^\d+\.\d+\.\d+\.\d+$/) 
	{
	  log_registry("Think its a ipv6 ip_address of $meContext is $meContext_data{ipAddress}\n");
          return "$meContext_data{ipAddress}";
	}

    if (exists $meContext_data{ipAddress} and $meContext_data{ipAddress} =~ m/^\d+\.\d+\.\d+\.\d+$/ or $meContext_data{ipAddress} =~ /a-zA-Z/)
    {
          log_registry("ip_address of $meContext is $meContext_data{ipAddress}\n");
          return "$meContext_data{ipAddress}";
    }
    else
    {
          log_registry("Error reading IP Address for $meContext in cstest TJN here as well\n");
          return 0;
    }
}

sub pick_a_different_rnc
{
  my $Notrnc1 = shift;
  my $Notrnc2 = shift;

  my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  my $mec;
  my $Notmec1 = get_mec($Notrnc1);
  my $Notmec2 = get_mec($Notrnc2) if $Notrnc2;

  for my $rrr (@rncs)
  {  
    $mec = "$rncs[int (rand ($#rncs + 1))]"; 
   
    my $mecontext = get_mec($mec);

    my %result = get_mo_attributes_CS( mo => $mecontext, attributes => "neType");
    my $neType = $result{neType};
  
    if (($neType ne "5") and ($mec !~ /CMSAuto/))#Don't pick a TDRNC for now stay we want RNC that are connected and synched 
    {
	 my $sync = get_synch_status($mec);
   	 if ($sync == 3 )
   	 {
		if ( $mec !~ m/$Notmec1/)
		{
			if($Notrnc2)
			{
				if ($mec !~ m/$Notmec2/)
				{
				        my $ick = $mec;
                                	my $ip = real_node_check($ick);
                                	log_registry("$ick is a real node so would not be selected..") if ($ip =~ /^159/);
                                	log_registry("Selecting NE: $ick") if ( $ip and !($ip =~ /^159/) );
                                	return ($ick) if ( $ip and !($ip =~ /^159/) );
				}	
			}
			else
			{
                		my $ick = $mec;
                		my $ip = real_node_check($ick);
                		log_registry("$ick is a real node so would not be selected..") if ($ip =~ /^159/);
                		log_registry("Selecting NE: $ick") if ( $ip and !($ip =~ /^159/) );
                		return ($ick) if ( $ip and !($ip =~ /^159/) );
			}
		}
   	} 
    }
  } 
  return; # no syncd node found 
}

#################################################################################################
#
# This subroutine is used to pick a different RNC/ERBS based on the given node fdn passed 
# In this manner we can select three different RNC
# NE refers to RNC or ERBS, e.g. for RNC NE value will be RncFunction and for ERBS ENodeBFunction
# NNE1 refers to first fdn of node which should not be selected means any other node should be selected 
# NNE2 refers to another fdn of node which should not be selected (Its optional attribute)
# CMO refers to child MO under the node should be present (Its optional attribute)
#
###################################################################################################
sub pick_a_different_node
{
  my %param = ( NE => "", NNE1 => "", NNE2 => "", CMO => "",@_);
  my $nodetype = $param{NE};
  my $Notnode1 = $param{NNE1};
  my $Notnode2 = $param{NNE2};
  my $mo = $param{CMO};
  my @nodes = get_mo_list_for_class_CS ( mo  => "$nodetype");
  my $mec;
  my $Notmec1 = get_mec($Notnode1);
  my $Notmec2 = get_mec($Notnode2) if $Notnode2;
  for my $rrr (@nodes)
  {
    $mec = "$nodes[int (rand ($#nodes + 1))]";
    my $mecontext = get_mec($mec);
    my %result = get_mo_attributes_CS( mo => $mecontext, attributes => "neType");
    my $neType = $result{neType};
    if (($neType ne "5") and ($mec !~ /CMSAuto/))
    {
         my $sync = get_synch_status($mec);
         if ($sync == 3 )
         {
                if ( $mec !~ m/$Notmec1/)
                {
                        if($Notnode2)
                        {
                                if ($mec !~ m/$Notmec2/)
                                {
                                        my $ick = $mec;
                                        my $ip = real_node_check($ick);
                                        log_registry("$ick is a real node so would not be selected..") if ($ip =~ /^159/);
                                        log_registry("Selecting NE: $ick") if ( $ip and ($ip !~ /^159/) );
               				if($mo and $ip and !($ip =~ /^159/))
                			{
                        			my $mo_exist = pick_a_mo("$ick","$mo");
                        			return $ick if $mo_exist;
                			}
			                return ($ick) if ( !($mo) and $ip and !($ip =~ /^159/) );
                                }
                        }
                        else
                        {
                                my $ick = $mec;
                                my $ip = real_node_check($ick);
                                log_registry("$ick is a real node so would not be selected..") if ($ip =~ /^159/);
                                log_registry("Selecting NE: $ick") if ( $ip and !($ip =~ /^159/) );
				if($mo and $ip and !($ip =~ /^159/))
				{	
					my $mo_exist = pick_a_mo("$ick","$mo");
					return $ick if $mo_exist;
				}
				return ($ick) if ( !($mo) and $ip and !($ip =~ /^159/) );
                        }
                }
        }
    }
  }
  return; # no syncd node found
}

sub check_status_for_5_minutes
{
  sleep 60;
  my ($dead_nodes, $unsynced_nodes, $ongo_rnc) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES", "SYNCHRONIZATION_ONGOING_RNC");
  log_registry("It seems count of Dead Nodes, Unsynched Nodes and Synch ongoing nodes are not available..") if ($dead_nodes eq "NONE");
  log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes, SYNCHRONIZATION_ONGOING_RNC = $ongo_rnc") if ($dead_nodes ne "NONE");
}

sub reset_all_genc
{
#for each mecontext in system, set generationcounter = 0

  my @mecs = get_mo_list_for_class_CS( mo  => "MeContext");
#  my $pick = "$rncs[int (rand ($#rncs + 1))]"; 
  my $node_count = ($#mecs + 1);
 
foreach my $nod(@mecs)
{
log_registry("Resetting generation counter for $nod ");
my  $result = set_mo_attributes_CS( mo => $nod, attributes => "generationCounter 0" );
log_registry("$result");
}
  log_registry("$node_count nodes found in the system.");

  return ($node_count);
}


sub preconditions_OK
{
  my $mc = shift;
  # Need to  add check here that we're not on being run from UAS, as it will fail if run from UAS
  my $result; 
  $result = `$smtool -l | egrep "cms_nead_seg|cms_snad_reg|ARNEServer|Region_CS|Seg_` if not $mc;
  $result = `$smtool -l | egrep "cms_nead_seg|cms_snad_reg|MAF|ARNEServer|Region_CS|Seg_` if ($mc and $mc eq "MAF");
  if($result)
  {
   	log_registry("Result:   $result");
	if($mc and $mc eq "MAF")
	{
	   	return unless $result =~ m/cms_nead_seg\s+started/m and
			 $result =~ m/cms_snad_reg\s+started/m and
			 $result =~ m/MAF\s+started/m          and
			 $result =~ m/ARNEServer\s+started/m   and
			 $result =~ m/Region_CS\s+started/m    and
			 $result =~ m/Seg_.*?\s+started/m;
	}
	else
	{
	         return unless $result =~ m/cms_nead_seg\s+started/m and
                         $result =~ m/cms_snad_reg\s+started/m and
                         $result =~ m/ARNEServer\s+started/m   and
                         $result =~ m/Region_CS\s+started/m    and
                         $result =~ m/Seg_.*?\s+started/m;
	}
   	my ($total_nodes, $alive_nodes, $dead_nodes, $synced_nodes, $never_nodes) = check_nead_status("TOTAL_NODES", "ALIVE_NODES", "DEAD_NODES" , "SYNCED_NODES" , "NEVERCONNECTED_NODES" );
        log_registry("It seems count of nodes are not available...") if ($total_nodes eq "NONE");
	return "0" if ($total_nodes eq "NONE");
   	log_registry("total_nodes=$total_nodes, alive_nodes=$alive_nodes, dead_nodes=$dead_nodes, synced_nodes=$synced_nodes, never_nodes=$never_nodes") if ($total_nodes ne "NONE");
   	log_registry("Preconditions valid");
   	return "OK"; # all CMS components were started, and all nodes synchcronised
  }
  log_registry("It seems $smtool is not able to check MC status or can say not able to check preconditions for Test Case."); 
}

sub recreate_plan
{
    my $old_plan = shift;
    log_registry("waiting 1 minute,deleting old plan");
     my $deleteplan_result= delete_plan($old_plan);
     if ($deleteplan_result)
{
 return
}
    sleep 60;
    my $new_plan_name = create_plan_name();
    my $create_plan_result = create_plan($new_plan_name);
    if($create_plan_result)
    {
 	log_registry("failed creating plan name");
	return;}
    return $new_plan_name;
    }


sub rev_bef    # review cache BEFORE (use TC id to id)
{
  my $test_slogan = shift;
   my $test_sl = $test_slogan;
   $test_sl =~ s/\W+//g;
   $test_sl =~ s/[a-zA-Z]//g;
   $test_sl =~ s/\_+/\_/g;
   $test_sl = "_review_cache_"."$test_sl";
  log_registry("Performing review cache to /var/tmp/RC$test_sl.before ");

  `/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py > /var/tmp/RC$test_sl.before`;
  my $file_name = `grep SNAD_C /var/tmp/RC$test_sl.before`;
   log_registry("There is no SNAD entry in /var/tmp/RC$test_sl.before ...") if not $file_name;
  return "" if not $file_name;
  chomp($file_name);
#  print "eeimacn: $file_name\n";
  `mv $file_name /var/tmp/RC$test_sl.before`;
   return "/var/tmp/RC$test_sl.before";
}

sub rev_aft    # review cache AFTER (use TC id to id)
{
  my $test_slogan = shift;
   my $test_sl = $test_slogan;
   $test_sl =~ s/\W+//g;
   $test_sl =~ s/[a-zA-Z]//g;
   $test_sl =~ s/\_+/\_/g;
   $test_sl = "_review_cache_"."$test_sl";
  log_registry("Performing review cache to /var/tmp/RC$test_sl.after ");
  `/opt/ericsson/nms_umts_cms_lib_com/bin/run_moscript /opt/ericsson/nms_umts_cms_lib_com/info/XReviewCache.py > /var/tmp/RC$test_sl.after`;
  my $file_name = `grep SNAD_C /var/tmp/RC$test_sl.after`;
  log_registry("There is no SNAD entry in /var/tmp/RC$test_sl.before ...") if not $file_name;
  return "" if not $file_name;
  chomp($file_name);
#  print "eeimacn: $file_name\n";
  `mv $file_name /var/tmp/RC$test_sl.after`;
  return "/var/tmp/RC$test_sl.after";
}

sub rev_comp_add    # compare BEFORE and AFTER result ADD INPUT: what result is a pass... i.e. if MO added or not...
{
   my $test_slogan = shift;
   my $test_sl = $test_slogan;
   $test_sl =~ s/\W+//g;
   $test_sl =~ s/[a-zA-Z]//g;
   $test_sl =~ s/\_+/\_/g;
   $test_sl = "_review_cache_"."$test_sl";
   my $review_cache_result = `head -5 /var/tmp/RC$test_sl.before`;

   my ($master_MOs ) = $review_cache_result =~ m/MASTER MOs : (\d+)/i;
   my ($proxy_MOs ) = $review_cache_result =~ m/PROXY MOs : (\d+)/i;
   my ($unmanaged_MOs ) = $review_cache_result =~ m/UNMANAGED MOs : (\d+)/i;
#  print "1 -> $master_MOs -> $proxy_MOs -> $unmanaged_MOs,  \n ";

   my $tota1 = $master_MOs+$proxy_MOs+$unmanaged_MOs;

   my $review_cache_result2 = `head -8 /var/tmp/RC$test_sl.after`;
   my ($master_MOs2 ) = $review_cache_result2 =~ m/MASTER MOs : (\d+)/i;
   my ($proxy_MOs2 ) = $review_cache_result2 =~ m/PROXY MOs : (\d+)/i;
   my ($unmanaged_MOs2 ) = $review_cache_result2 =~ m/UNMANAGED MOs : (\d+)/i;
   log_registry("master_MOs=$master_MOs2, proxy_MOs=$proxy_MOs2, unmanaged_MOs=$unmanaged_MOs2");

   my $tota2 = $master_MOs2+$proxy_MOs2+$unmanaged_MOs2;

# print before and after table
   log_registry("          Before         |              After  ");
   log_registry("-------------------------------------------------------------");
   log_registry("Masters	$master_MOs	|Masters	$master_MOs2");
   log_registry("Proxies	$proxy_MOs	|Proxies	$proxy_MOs2");
   log_registry("UnManaged	$unmanaged_MOs	|UnManaged	$unmanaged_MOs2");
   log_registry("==========================================================");
   log_registry("Total:	$tota1	|Total:	$tota2	");

}


sub rev_find  # look for "things" in the review_cache AFTER output...
{
   my %param = ( file       => "",
                    @_
                  );
   my $mo_fdn     = $param{mo};
   my $RCfile     = file_is_OK($param{file}) or return;
   my $Line = "";
   my $stat = 0;

   open(REVFILE, $RCfile) or return " $RCfile FILE_NOT_READ";
   while ($Line = <REVFILE> )					
   {	
	if ( $Line =~ /MO Name: / && $Line =~/$mo_fdn$/ )
	{
 		log_registry("$Line");
		$Line = <REVFILE>;
		$Line = <REVFILE>; # Read 2 lines to get consistency
 		log_registry("$Line");
		if($Line =~ /Redundant_Proxy/) { $stat = 7; }
		if($Line =~ /Unstable_Not_Consistent/) { $stat = 6; }
		if($Line =~ /MultipleMaster/) {  $stat = 4; }
		if($Line =~ /MissingMaster/)  {  $stat = 3; } 
		if($Line =~ /Inconsistent/)   {  $stat = 2; }
		if($Line =~ /Inconsistent_Relations/)  { $stat = 5; }
		if($Line =~ /Inconsistent_Topology/) { $stat = 8; }
		if($Line =~ /state\:\sConsistent/) { $stat = 1; }
        	return($stat,$Line);
	}
   }
   log_registry("It seems MO $mo_fdn does not exist in review cache file $RCfile  ....");
   return;
}

sub file_is_OK
{
   my $file = shift;
   if (-e $file)  # check file exits
   {
      if (-s $file)  # check file is not empty 
	{
	log_registry("File $file exists and is not empty");
        return $file;
      	}
   }
   else
   {
      log_registry("File $file is not found or is empty ");	
      $file = "FILE_NOT_FOUND";  # file not exist or empty, so set to a ""  to return a false value
      return $file
   }
}

sub stop_start_rnc_netsim
{
my $RNC01 = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01";
my ($result, $sim, $node) = get_sim_info("SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01");
if ($result)
{
   log_registry("Error code is $result, error message is $result_code_NE{$result}");
return;
}
else
{
   log_registry("Sim is $sim");
   log_registry("Node is $node");
}
my $result_command = do_netsim_command('.stop', $RNC01,$sim, $node);
if ($result_command)
{
	log_registry("result = $result_command");
}

log_registry("waiting for 6 minutes");
#sleep 360;
sleep 180;
#do check here
 my ($dead_nodes, $unsynced_nodes) = check_nead_status("DEAD_NODES", "UNSYNCED_NODES");
 log_registry("It seems count of dead or unsynched nodes are not available....") if ($dead_nodes eq "NONE");
 log_registry("dead_nodes=$dead_nodes, unsynced_nodes=$unsynced_nodes") if ($dead_nodes ne "NONE");
 do_netsim_command(".start",$RNC01,$sim,$node);
}

sub check_nead_log
{
  my ($testcase_logfile, $nead_restarted, $expected_error) = @_; 
  # stop the tail processes
  my $pid_data = `ps -ef | grep \"$tail_command\"`;             ### SEPERATE OUT THE SUPERVISION ---> DOESN'T BELONG HERE...
#  print "PID data is\n$pid_data\n" if $debug;
#  while ($pid_data =~ m/\w+\s+(\d+).*?$tail_command/g)
#  {
# print "Child PID is $1\n";
#      #kill INT => $1;
#  }

  system("cat $nead_log >> $testcase_logfile") if $nead_restarted;      # append the new NEAD logfile if cms_nead_seg was restarted

  log_registry("egrep = egrep \"$errors_to_find\" $testcase_logfile");

#  my @all_nead_errors = `egrep \"$errors_to_find\" $testcase_logfile`;  # find ERROR strings in log
  if ($expected_error and expected_error_OK($expected_error, @all_nead_errors)) # found at least one wanted error, and all errors are as expected
  {
    unlink $testcase_logfile; # remove logfile
    return "OK"; # no unexpected errors or exceptions in logs
  }
  if (@all_nead_errors)  # one or more errors was found
  {  
    foreach my $xxc (@all_nead_errors)
    {
     log_registry("ERRORs found in log: $xxc");
    }
    return;
  }
  else
  {
    unlink $testcase_logfile; # remove logfile
    return "OK"; # no errors or exceptions in logs
  }
}


sub nodes_synced

{
   sleep 30; # wait for a fresh NEAD status update
   my ($total_nodes, $alive_nodes, $dead_nodes, $synced_nodes, $never_nodes) = check_nead_status("TOTAL_NODES", "ALIVE_NODES", "DEAD_NODES" , "SYNCED_NODES" , "NEVERCONNECTED_NODES" );
   log_registry("It seems count of nodes are not available...") if ($total_nodes eq "NONE");
   return "NONE" if ($total_nodes eq "NONE");
   return $total_nodes, $alive_nodes, $dead_nodes, $synced_nodes, $never_nodes;
}

sub get_synch_status
{
    my $ne = shift;
    my $mec = get_mec($ne);
    log_registry("CHECKing CS mirrorMIBsynchStatus (3=>synched) for NE:  $mec ");
    
    my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
    my $sync = $rezzy{mirrorMIBsynchStatus};
    log_registry("synchstate = $sync") if $sync;
    log_registry("sunchstate is null") if not $sync;
    return "0" if not $sync;
    return $sync;
}

sub start_adjust_nes
{
  my $review_log = "/tmp/review_cache_$$.log";
  log_registry("Command is: $start_adjust");
  system("$start_adjust > $review_log");
  # tail_maf();
  log_registry("Waiting 10 minutes for adjust to be performed");
  sleep 600;
  my ($total_nodes, $synced_nodes) = check_nead_status("TOTAL_NODES", "SYNCED_NODES");
  log_registry("It seems count of nodes are not available...") if ($total_nodes eq "NONE");
  test_failed($test_slogan) if ($total_nodes eq "NONE");
  return "0" if ($total_nodes eq "NONE");
  log_registry("total_nodes=$total_nodes, synced_nodes=$synced_nodes");
  unless ($total_nodes == $synced_nodes)
  {
   test_failed($test_slogan);
  }
  my $review_cache_result = `tail -8 $review_log`;
  log_registry("$review_cache_result");
  unlink $review_log;
}

sub start_databases
{
   my $review_log = "/tmp/review_cache2_$$.log";
   my $exit_result = system("$start_databases > $review_log");
   my $review_cache_result = `tail -8 $review_log`;
   log_registry("$review_cache_result");
   unlink $review_log;
   return $exit_result;
 #  my ($master_MOs, $proxy_MOs, $unmanaged_MOs) = $review_cache_result =~ m/MASTER MOs\n(\d+)\nPROXY MOs\n(\d+)\nUNMANAGED MOs\n(\d+)/;

#   print "master_MOs=$master_MOs, proxy_MOs=$proxy_MOs, unmanaged_MOs=$unmanaged_MOs\n" if $debug;

 #  return $master_MOs, $proxy_MOs, $unmanaged_MOs;
}

sub create_cell
{
# MAKE A NEW CELL FDN HERE (random name $mo)  my $cell = pick_a_cell($rnc); 

# N.B. 192 cells max per module => 12x192 = 2304 cells MAX per RNC
# max. no. of LAs per RNC:    47
# max. no. of RAs per RNC:   154
# max. no. of SAs per RNC:  2304
# max. no. of URAs per RNC: 2304
# N.B. Officially (according to RNC MOM) we need appropriate (1) IubLink (2) LA (3) SA and refs filled in for each cell created.
# Actually, don't need (2) and (3) at the moment. But code is ready anyway.
# Need to create (1), (2), (3) if not present.
# find an LA by filtering on RNC
# find an IubLink - normally setup with 3 cells only - plenty room for one more reservation...

  my $rnc = pick_an_rnc(); 
  log_registry("It seems no synched RNC found ...") if not $rnc;
  return "0" if not $rnc;
  my $rand = int(rand(99));
  my $cell = "$rnc,UtranCell=CMSAUTO$rand";
  log_registry("cell about to be created is $cell");
  my $plan_name = create_plan_name();
  create_plan($plan_name);
  my $plan = "-p $plan_name";
  log_registry("PLAN is $plan...");
  my ($ul, $dl) = (112, 437);
  my ($rnc_name,$rest_attr) = cell_attr_fdn($cell,"",$rnc);
  return "0" if not $rest_attr;
  $rest_attr =~ s/\n+//g;
  my $create_result = create_mo_CS( mo => $cell, plan => $plan_name, attributes =>  "userLabel cell$rand tCell 0 uarfcnUl $ul uarfcnDl $dl primaryScramblingCode 1 sib1PlmnScopeValueTag 1 $rest_attr");

#existing lac and sac => no new masters created.
  if ($create_result)
  {      
    log_registry("Problem in creation of cell ... ");
    log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
    test_failed($test_slogan);
    delete_plan($plan_name);
    return;  
  }

  log_registry("Activating plan.... with MO $cell");
  my $Activate_result = activate_plan($plan_name);
  if ($Activate_result)
  {
    log_registry("Problem in activaton of plan area...");
    log_registry("Error code is $Activate_result, error message is $result_code_CS{$Activate_result}");
    test_failed($test_slogan);
    sleep 120;
    delete_plan($plan_name);
    return;
  }
  #wait here while mos are entered in the valid CS...
  log_registry("Waiting 90 seconds for MO to be brought into valid area.");
  sleep 90; # wait for 90 seconds 
  delete_plan($plan_name);
  # verify the cells have been updated in the vaild if the activate was successful, test fails if not..
  # print"This is delete \n";
  #check mo doesn't exist
  my $check_res =  does_mo_exist($cell);
  if (!$check_res == $result_code_CS{MO_ALREADY_EXISTS})
  {      
    test_failed($test_slogan);
    log_registry("Error code is $check_res, error message is $result_code_CS{$check_res}");
    return;
  }
  return $cell;
}

sub create_cell_valid
{
# Create a UtranCell in valid area
# if no sync'd rnc return

  my $rnc = pick_an_rnc(); 
  return if not $rnc;

# Generate random cell 
  my $rand = int(rand(99));
  my $cell = "$rnc,UtranCell=CMSAUTO$rand";
  log_registry("cell about to be created is $cell");
  my ($ul, $dl) = (112, 437);
  my ($rnc_name,$rest_attr) = cell_attr_fdn($cell,"",$rnc);
  return "0" if not $rest_attr;
  $rest_attr =~ s/\n+//g;
  my $create_result = create_mo_CS( mo => $cell, attributes =>  "userLabel cell$rand tCell 1 uarfcnUl $ul uarfcnDl $dl primaryScramblingCode 1 $rest_attr");

  if ($create_result)
  {      
    log_registry("Error code is $create_result, error message is $result_code_CS{$create_result}");
    return;  
  }
  # wait here while mos are entered in the valid CS...
  
  log_registry("Waiting 60 seconds for MO to be brought into valid area.");
  sleep 60; # wait for 1 minutes
  # verify the cells have been created in the vaild
  #check mo doesn't exist
  my $check_res = does_mo_exist($cell);
  if (!$check_res == $result_code_CS{MO_ALREADY_EXISTS})
  {    
    log_registry("Error code is $check_res, error message is $result_code_CS{$check_res}");
    return;
  }
  return $cell;
}


sub delete_cell
{
  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..

#for each reservedBy, remove MO
  my %xyz = get_mo_attributes_CS(mo => $cell, attributes => "reservedBy");
  my @zzz = split /\040/, $xyz{reservedBy};
  foreach my $resby(@zzz)
  { 
  log_registry("Deleting reserving MO: $resby ... ");
  delete_mo_CS(mo => $resby);
  }
 log_registry("Deleting Cell $cell ... ");
  my  $result = delete_mo_CS( mo => $cell);

  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 

  #verify that the delete was successful
  $result = does_mo_exist_CS( mo => $cell);
  
  if (($result == $result_code_CS{MO_DOESNT_EXIST}) && (wait_10_for_sync()))
  {
    test_passed($test_slogan);
    return;
  } 
  else
  {
    test_failed($test_slogan);
    return;
  }
}

sub delete_cell_valid
{
  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..

#for each reservedBy, remove MO
  my %xyz = get_mo_attributes_CS(mo => $cell, attributes => "reservedBy");
  my @zzz = split /\040/, $xyz{reservedBy};
  foreach my $resby(@zzz)
  { 
  log_registry("Deleting reserving MO: $resby ...");
  delete_mo_CS(mo => $resby);
  }
 log_registry("Deleting Cell $cell ...");
  my  $result = delete_mo_CS( mo => $cell);
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 
  #verify that the delete was successful
  $result = does_mo_exist_CS( mo => $cell);
  if (($result == $result_code_CS{MO_DOESNT_EXIST}) && (wait_10_for_sync()))
  {
    test_passed($test_slogan);
    return;
  } 
  else
  {
    test_failed($test_slogan);
    return;
  }
}

sub execute_del_master_script
{
    my $script = "/opt/ericsson/atoss/tas/WR_CMS/INPUT/delete-masters.sh";
    if(-x $script)
    {
	`$script valid > /tmp/delmasters.log`;
	my $result = $? ;
        return "1" if not $result;
	log_registry("There is a problem in execution of script $script...") if $result;
	return "0" if $result;
    }
    else
    {
        log_registry("File $script does not have execute permission....");
        return "0";
    }
}

sub execute_master_script
{
    my $script = "/opt/ericsson/atoss/tas/WR_CMS/INPUT/create-masters.sh";
    if(-x $script)
    { 
    	`$script valid > /tmp/masters.log`;
	my $result = $? ;
	return "1" if not $result;
	log_registry("There is a problem in execution of script $script...") if $result;
        return "0" if $result;
    }
    else
    {
	log_registry("File $script does not have execute permission....");
	return "0";
    }
}

sub update_cell 
{
  my $test_slogan = shift;

  my $rnc = pick_an_rnc(); 
  
  my $mo = pick_a_cell($rnc); 

  my $plan_name = create_plan_name();
  create_plan($plan_name);

  my ($ul, $dl) = (162, 662);
  log_registry("this is :$cstest $plan_name  $mo ");

  my %result = get_mo_attributes_CS( mo => $mo, attributes => "uarfcnUl uarfcnDl");
  my $uarfcnUl = $result{uarfcnUl};
  my $uarfcnDl = $result{uarfcnDl};
  log_registry("checking current values=> uarfcnUl: $uarfcnUl :: uarfcnDl: $uarfcnDl ");
  log_registry("Setting mo attributes=> uarfcnUl $ul :: uarfcnDl $dl");
  my  $result = set_mo_attributes_CS( mo => $mo, plan => $plan_name, attributes => "uarfcnUl $ul uarfcnDl $dl" );
  if(($result) and ($result == $result_code_CS{MO_DOESNT_EXIST}))
  {
    log_registry("must create mo first ");
# call sub create_cell for this
    my $create_result = create_onecell_valid($mo);
    if ($create_result = $result_code_CS{MO_ALREADY_EXISTS})
# mo does  exist
    {
      $plan_name =  recreate_plan($plan_name);
      $result = delete_mo_CS( mo => $mo, plan => $plan_name );
    }
    else
    { 
      test_failed($test_slogan);
      log_registry("Error code is $create_result, error message is $result_code_CS{$result}");
      delete_plan($plan_name);
      return; 
    }
  }
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    delete_plan($plan_name);
    return;
  }
# if activate fails finish test
  my $_activate_result = activate_plan($plan_name);
  if($_activate_result)
  {
    test_failed($test_slogan);
    log_registry("Error code is $_activate_result, error message is $result_code_CS{$_activate_result}");
    delete_plan($plan_name);
    return;
  }
# if the delete plan fails then need to raise this even though the testcase doesn't necessarly fail!!
 
# verify the cells have been updated in the vaild if the activate was successful, test fails if not..
#should delete planned area after activation
  sleep(60);
# if the delete plan fails then need to raise this even though the testcase doesn't necessarly fail!!
  delete_plan($plan_name);
  log_registry("checking the updates ");
  #verify that the update has been successful
  %result = get_mo_attributes_CS( mo => $mo, attributes => "uarfcnUl uarfcnDl");
  $uarfcnUl = $result{uarfcnUl};
  $uarfcnDl = $result{uarfcnDl};

log_registry("Getting mo attributes=> uarfcnUl: $uarfcnUl :: uarfcnDl: $uarfcnDl ");
  
  if (!($uarfcnUl ==$ul) or !($uarfcnDl == $dl))
  {
    log_registry("if statement failed");
    test_failed($test_slogan);
    return;
  }
  else
  {
    my $sync = get_synch_status($rnc); 
      
      if ($sync == 3)
        {  test_passed($test_slogan);   }
         else
        {  test_failed($test_slogan);   }
      return;

#if (wait_10_for_sync())
 # {  test_passed($test_slogan);   }
 # else
 # {  test_failed($test_slogan);   }
 # return;

  }
}

sub update_cell_valid
{
  my $rnc = pick_an_rnc();  
  my $cell = pick_a_cell($rnc);    # Bonus would be: create a cell if NONE exists. But sims come with cells, so OKEY DOKEY..
  my ($ul, $dl) = (162, 662);
  my  $result = set_mo_attributes_CS( mo => $cell, attributes => "uarfcnUl $ul uarfcnDl $dl" );
  if ($result)
  {      
    test_failed($test_slogan);
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  } 
  #verify that the update has been successful
  my %result = get_mo_attributes_CS( mo => $cell, attributes => "uarfcnUl uarfcnDl");
  my $uarfcnUl = $result{uarfcnUl};
  my $uarfcnDl = $result{uarfcnDl};
  if (!($uarfcnUl ==$ul) and !($uarfcnDl == $dl))
  {
    test_failed($test_slogan);
    return;
  } 
}


sub check_nead_status
{
  my @nead_values = @_;
#  log_registry("Check nead_values @nead_values");
  my %status_hash;
  my $line_count  = 100;
  my $count = 0;
  do 
  {
    my @log_files = `ls -1t $nead_dir/neadStatus.log.y*`;  # sort yin/yang by time, first in list is the most recent
    my $log_file = $log_files[0];   # get the latest yin/yang file
    log_registry("It seems yin/yang file does not exist at path $nead_dir .....") if not $log_file;
    return "NONE" if not $log_file;
    chomp($log_file) if $log_file;
    my $last_report = `tail -$line_count $log_file`;  # get the last line_count lines from the log file
    while ($last_report =~ /(\w+)\s+=\s+(\w+)/g)
    { $status_hash{$1} = $2; }
    $count = 0;
    for my $nead_value (@nead_values)
    { $count++ if exists $status_hash{$nead_value};}
  } until $count == @nead_values;
  
  if ($debug)
  {
    log_registry("NEAD status");
    log_registry("$_=$status_hash{$_}");
  }
  return @status_hash{@nead_values};
}

sub create_onecell_valid
{
my ($ul, $dl) = (162, 662);
my ($mo, $cell) = @_;
log_registry("...  ...");
# my $iubLinkRef = "SubNetwork=ONRM_RootMo_R,SubNetwork=RNC01,MeContext=RNC01,ManagedElement=1,RncFunction=1,IubLink=10";
my @temp = split /\054/, $mo;
my $iubLinkRef = "$temp[0],$temp[1],$temp[2],$temp[3],$temp[4],IubLink=10";
log_registry("iubLinkRef is $iubLinkRef");
my ($lac, $rac, $sac) = (2, 102, 398);
my $create_result = create_mo_CS( mo =>$mo, attributes =>  "cId $cell userLabel cell-$cell localCellId 0 tCell 0 uarfcnUl $ul uarfcnDl $dl primaryScramblingCode 0 lac 2 sac 127 sib1PlmnScopeValueTag 0 utranCellIubLink $iubLinkRef");
 return if $create_result;
my $mo_result = does_mo_exist($mo);
  return $mo_result;
} 

sub create_plan_name
{
  my ($min, $hour, $day, $month, $year) = (localtime)[1..5];
  my $plan_na = sprintf "CMSAUTOplan_%d%02d%02d_%02d%02d", $year+1900, $month+1, $day, $hour, $min;
  log_registry("Plan Name is -> $plan_na");
  return $plan_na;
}

sub managed_component
{
   my ($mc, $operation, $time_to_sleep) = @_;
   my $smtool_reason="";

   if ( $operation eq "offline" ) 
	{
   	$smtool_reason = "-reason=planned -reasontext=automation";
	}
   else
	{
        $smtool_reason="";
   	}

   log_registry("$smtool $operation $mc $smtool_reason");
   system("$smtool $operation $mc $smtool_reason");

   my %status = ( offline => "offline",
		  online  => "started");
   my $attempts      = 0;
   my $max_attempts  = 10;
   my $result;

   do {
      return if $attempts++ > $max_attempts;
      $result = `$smtool -l | egrep $mc`;
      sleep $time_to_sleep if $time_to_sleep;
      log_registry("Trying to $operation:     $result");
   } until $result =~ m/$mc\s+$status{$operation}/;

   return "OK";
}

sub pick_an_IubLink  #NOT READY
{
  my $rnc = shift;
  my  $result = `$cstest -s $segment_CS lm $rnc -l 1 -f '\$type_name==IubLink'`;
  my @cells = split /\012/, $result;
  my $pick = "$cells[int (rand ($#cells + 1))]"; 
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count IubLinks(s) found in $rnc  :: Selecting IubLink: $pick");
  return ($pick);
}

sub pick_a_cell
{
  my $rnc = shift;
  my  $result = `$cstest -s $segment_CS lm $rnc -l 1 -f '\$type_name==UtranCell'`;
  my @cells = split /\012/, $result;
  if ( $#cells < 5)   # Some times it returned something even when number of Cells on RNC was 0 so increase to 5
  {
	return;
  }
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count cell(s) found in $rnc ");
  my $pick;
  my $flag = 0;
  foreach (@cells)
  {
  	$pick = "$cells[int (rand ($#cells + 1))]";
	$flag = 1 if (($pick !~ /UtranCell\=HN/) and ($pick !~ /UtranCell\=CMS/));
	last if $flag;
  }
  return ($pick);
}

sub test_passed
{
  my $test_slogan = shift;
  my $e_time = get_time_string();
  my $end_time = substr($e_time,11,5)."  "."on"."  ".substr($e_time,8,2).substr($e_time,4,4).substr($e_time,0,4);
  log_registry("$bggreen$test_slogan PASSED  $off at $end_time");
#  print "\n$bggreen$test_slogan Passed  $off at $end_time","\n";
  stop_log_nead();
  stop_log_snad();
}

sub test_failed
{
  my $test_slogan = shift;
  my $e_time = get_time_string();
  my $end_time = substr($e_time,11,5)."  "."on"."  ".substr($e_time,8,2).substr($e_time,4,4).substr($e_time,0,4);
  log_registry("$bgred$test_slogan FAILED  $off at $end_time");
#  print "\n$bgred$test_slogan Failed  $off at $end_time","\n";
  stop_log_nead();
  stop_log_snad();
}

sub wait_for_rnc_sync #waiting for RNCs to synch again
{
  my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  my $waitfor =0;
  for my $rrr (@rncs)
  {  
    my $mec = get_mec($rrr);             # 
    log_registry("CHECKing CS mirrorMIBsynchStatus (3=>synched) for RNC:  $mec ");
    
    my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
    my $sync = $rezzy{mirrorMIBsynchStatus};
    log_registry("synchstate = $sync ");
    $waitfor = 0;
    if ($sync == 2)
    {
   	while($waitfor < 3600)    # Only wait an hour for one RNC anyway....
    	{
      		sleep 60;
      		$waitfor = $waitfor+60;               
      		%rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
      		$sync = $rezzy{mirrorMIBsynchStatus};
  		log_registry("RNC state => $sync");
		log_registry("RNC does not seems to be synchronized after 1 Hr so leaving the checks of This RNC") if ($waitfor == 3600 and $sync != 3);
		$waitfor = 3660 if ($sync == 3);
   	}
    }
  }
}

sub wait_for_long_sleep    # nice to add: start epoch seconds, end epoch seconds... subtract and show result
{
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime;
  my $ce = ($year + 1900);
  $mon = ($mon+1);

  if ($min > 55 && $min < 60 ) { $min = "55"; }
  elsif ($min < 5 ) { $min = "00"; }
  else { $min=$min-4; }

  log_registry("The time used in search is $start_time");

  log_registry("Waiting for NEW Long Sleep to be found in System Event Log:");


  my $result = `/opt/ericsson/nms_cif_sm/bin/log -type system -filter "event_type = 'COM.ERICSSON.NMS.UMTS.RANOS.FWK.CDLIB.RANOS_CMS_EVENTS_BASE' AND time_stamp > '$start_time'" | grep "going for long sleep 3600sec" | wc -l`; 
#  print "$result entries found\n\n...."; 
  my $comp = (0+$result);

  my $waitfor =0;

  while ((0+$result) == $comp || $waitfor > 3600)  
  {
    sleep 60;
    $waitfor = $waitfor+60;

    $result = `/opt/ericsson/nms_cif_sm/bin/log -type system -filter "event_type = 'COM.ERICSSON.NMS.UMTS.RANOS.FWK.CDLIB.RANOS_CMS_EVENTS_BASE' AND time_stamp > '$start_time'" | grep "going for long sleep 3600sec" | wc -l`;
  }
  if ($result > 0 )
  	{
        log_registry("$result");
        log_registry("Long sleep found in System Event Log: Snad finished");
	}
   else
	{
     	log_registry("No long sleep found but have wait an hour anyway !!!!!! ");
	}

}

sub start_log_nead
{
  my $testcase_logfile = shift;
#  if ( $pid_log_nead = fork ) {    sleep 1;}
#  else
#  {
#    die "cannot fork: $!" unless defined $pid_log_nead;    # Have stopped call to tail as log files are not useful at the minute
#  }
# my $pid_log_nead2 = $pid;
  log_registry("File will not exist for now : $tail_command > $testcase_logfile");

}

sub start_log_snad
{
  my $testcase_logfile_snad = shift;
#  if ( $pid_log_snad = fork ) {    sleep 1;}
#  else
#  {
#    die "cannot fork: $!" unless defined $pid_log_snad;    
#  }
# $pid_log_snad = $pid;
  log_registry("File will not exist for now  : $tail_command_snad > $testcase_logfile_snad");   # Have stopped call to tail as log files are not useful at the minute

}

sub stop_log_nead
{
# print "kill 9, $pid_log_nead  \n ";
  if ($pid_log_nead)  # if we find any pids 
  {
  my @pid = `pgrep -P $pid_log_nead`;
  foreach ( @pid)
	{
	$_ =~ s/\n+//g;
	kill 9, $_; 
	}
	kill 9, $pid_log_nead;
  }
}

sub stop_log_snad
{
# print "kill 9, $pid_log_snad  \n ";
 if ($pid_log_snad)  # if we find any pids 
  {
  my @pid = `pgrep -P $pid_log_snad`;
  foreach ( @pid)
	{
	$_ =~ s/\n+//g;
	kill 9, $_;
	}
	kill 9, $pid_log_snad;
  }
}

sub wait_10_for_sync
{
# eeitjn changed not it test if any sync are ongoing using ATTRIBUTE_SYNC_NODES.
# if so wait do not indefinately do check 

  for (my $i=1; $i < 11; $i++)
  {
    sleep 30; # wait for a fresh NEAD status update
    my ($attr_nodes,$topo_nodes,$synced_nodes) = check_nead_status("ATTRIBUTE_SYNC_NODES", "TOPOLOGY_SYNC_NODES" ,"SYNCED_NODES");
    log_registry("It seems count of nodes are not available....") if ($attr_nodes eq "NONE");
    return "0" if ($attr_nodes eq "NONE");
    log_registry("ATTRIBUTE_SYNC_NODES: $attr_nodes :: TOPOLOGY_SYNC_NODES: $topo_nodes :: Synched Nodes: $synced_nodes");
    if ($synced_nodes eq 0 && $attr_nodes eq "0" && $topo_nodes eq "0") 
    {
      return 1;    # On atoss server there are no nodes sometimes so return a value here to move on
    }
    if ($attr_nodes eq "0" && $topo_nodes eq "0") 
    {
      return $synced_nodes;
    }
  }
}

sub wait_for_all_conn_to_sync   # for each RNC, [future: RBS, RXI,] check MeContext: if connected then wait for synch to be complete.
                                # currently RNC only.
{
 my @rncs = get_mo_list_for_class_CS ( mo  => "RncFunction");
  for my $rrr (@rncs)
  {
    my $mec = get_mec($rrr);
    my %outp = get_mo_attributes_CS( mo => $mec, attributes => "connectionStatus");
    if (0+$outp{connectionStatus} == 2)
    {
      log_registry("CHECKing CS mirrorMIBsynchStatus (3=>synched) for RNC:  $mec ");
      my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
      my $sync = $rezzy{mirrorMIBsynchStatus};
      log_registry("synchstate = $sync ");
      while (0+$sync != 3)
      {
        sleep 15;
        %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
        $sync = $rezzy{mirrorMIBsynchStatus};
 	log_registry("$sync");
      }
    }
    else { 
		log_registry("$mec connectionStatus is $outp{connectionStatus}.");	
	  }
  }

}

sub wait_for_next_nesu_conn   # look at config value and stall
{
  my $conn = `smtool -config cms_nead_seg | grep nesuPollrateConnectedNE`;
  log_registry("$conn");
}

sub wait_for_next_nesu_disc   # look at config value and stall
{
  my $disc = `smtool -config cms_nead_seg | grep nesuPollrateDisconnectedNE`;
  log_registry("$disc");
  # sleep (0+
}

sub wait_for_sync_status
{
  my $rnc = shift;
  my $status = (0+shift);
  my $mec = get_mec($rnc);             #
  log_registry("CHECKing CS mirrorMIBsynchStatus (3=>synched) for RNC:  $mec ");
  my %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
  my $sync = $rezzy{mirrorMIBsynchStatus};
  log_registry("synchstate = $sync");
  for(my $i=1;$i<=120;$i++)
  {
    #sleep 1;
    %rezzy = get_mo_attributes_CS( mo => $mec, attributes => "mirrorMIBsynchStatus");
    $sync = $rezzy{mirrorMIBsynchStatus};
    log_registry("RNC synch state => $sync ");
    last if ($status == (0+$sync));
  }
  return "OK" if ($status == (0+$sync));
  return "0";
}

sub cell_attr_fdn
{
   my $base_fdn   = $_[0];
   my $attr_full  = $_[1];
   my $rest_attr  = "";
   my $rnc_name   = $_[2];
   if(!$rnc_name) {
	log_registry("No Synched RNC Found, so leaving the further processing of test case");
        return; }	
   log_registry("RNC NAME => $rnc_name");
   my $cell_name = pick_a_cell($rnc_name);
   log_registry("It seems no UtranCell exist under RNC $rnc_name ...") if not $cell_name;
   return "0" if not $cell_name;
   log_registry("Selected UtranCell to fetch the lac,sac,rac and utranCellIubLink attributes value for new UtranCell \n Selected UtranCell => $cell_name");
   my $attrs ="lac sac rac utranCellIubLink";
   my %attr = get_mo_attributes_CS( server =>$region_CS,attributes =>$attrs, mo => $cell_name);
   log_registry("LAC => $attr{lac}");
   log_registry("SAC => $attr{sac}");
   log_registry("RAC => $attr{rac}");
   log_registry("utranCellIubLink  => $attr{utranCellIubLink}");
   my $localCellId = int(rand(65000)); # To select randomly a localCellId cID and localCellId would be same
   log_registry("localCellId and cId => $localCellId");
   if($base_fdn)
   {
    	$rest_attr  = "lac"." "."$attr{lac}"." "."sac"." "."$attr{sac}"." "."rac"." "."$attr{rac}"." "."localCellId"." "."$localCellId"." "."cId"." "."$localCellId"." "."utranCellIubLink"." "."$attr{utranCellIubLink}";
	$rest_attr  =~ s/\n+//g ;
        return ($rnc_name,$rest_attr); 
   }
   return;
}

sub status_mc
{
  my $mc_name = $_[0];
  my $action = $_[1];
  my $time  = $_[2];
  my $stat_mc = managed_component("$mc_name", "$action", "$time");
  if(!$stat_mc)
  {
        log_registry("It seems MC $mc_name is not getting online, so try once more after 1 min....");
        sleep 60;
        $stat_mc = managed_component("$mc_name", "$action", "$time");
  }
  return $stat_mc;
}


sub plan_decision
{
   my $plan_name = shift;
   my $plan_exist = plan_area_exist($plan_name);
   if($plan_exist == 0)
   {
	 my $plan = create_plan_area($plan_name);
	 if($plan)
         {
		return $plan_name;
         } 
         else
         {
		log_registry("Unable to create Plan area...");
		return;
         }
   }
   else
   {
      	log_registry("Plan already exist, so please run the test case again to avoid confilcts of existing plan");
	return;
   }
}

sub highest_SA  # in:RncFunction, Location Area... out:highest SA number in that RNC.
{
  my $rnc = shift;
  my $la = shift;
  $la = "$rnc,LocationArea=$la";   #MO
  my  $result = `$cstest -s $segment_CS lm $la -l 1 -f '\$type_name==ServiceArea'`;
  my @cells = split /\012/, $result;
  #  my $pick = "$cells[int (rand ($#cells + 1))]";
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count SA(s) found in $la of $rnc.");
  if ($cell_count == 0)
  {
    return(0);
  }
  foreach my $iii(@cells)
  {
    my @ch = split /\054/, $iii;
    my $ll = "$ch[6]";
    my @hh = split /\75/, $ll;   # split on equals sign...
    $iii = "$hh[1]";
  }
  my @sorted = reverse sort numerical @cells;
  my $highest = (0+$sorted[0]);
  log_registry("highest value is $highest");
  return ($highest);
}

sub highest_RA  # in:RncFunction, Location Area... out:highest RA number in that RNC.
{
  my $rnc = shift;
  my $la = shift;
  $la = "$rnc,LocationArea=$la";   #MO
  my  $result = `$cstest -s $segment_CS lm $la -l 1 -f '\$type_name==RoutingArea'`;
  my @cells = split /\012/, $result;
  #  my $pick = "$cells[int (rand ($#cells + 1))]";
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count RA(s) found in $la of $rnc.");
  if ($cell_count == 0)
  {
    return(0);
  }
  foreach my $iii(@cells)
  {
    my @ch = split /\054/, $iii;
    my $ll = "$ch[6]";
    my @hh = split /\75/, $ll;   # split on equals sign...
    $iii = "$hh[1]";
  }
  my @sorted = reverse sort numerical @cells;
  my $highest = (0+$sorted[0]);
  log_registry("highest value is $highest");
  return ($highest);
}

sub numerical {$a <=> $b}

sub highest_LA  # in:RncFunction MO out:highest LA number in that RNC.
{
  my $rnc = shift;
  my  $result = `$cstest -s $segment_CS lm $rnc -l 1 -f '\$type_name==LocationArea'`;
  my @cells = split /\012/, $result;
  #  my $pick = "$cells[int (rand ($#cells + 1))]";
  my $cell_count = ($#cells + 1);
  log_registry("$cell_count LA(s) found in $rnc.");
  foreach my $iii(@cells)
  {
    my @ch = split /\054/, $iii;
    my $ll = "$ch[5]";
    my @hh = split /\75/, $ll;   # split on equals sign...
    $iii = "$hh[1]";
  }
  my @sorted = reverse sort numerical @cells;
  my $highest = $sorted[0];
  log_registry("highest value is $highest");
  return ($highest);
}

#####################################
#
# To create UtranCell of CMSAUTO
#
#####################################

sub create_UtranCell
{
        my $workingRNC = shift;
 	my $mandate_attrs = shift;  # lac <lac_value> sac <sac_vlaue> atleast else nothing
   	my $plan_name = shift;
	$plan_name = "" if not $plan_name;
        my $rand = int(rand(100));
        my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
	my $rnc_name = "";
	my $rest_attr = "";
	if ($mandate_attrs)
	{
		if ($mandate_attrs =~ /lac/)
		{
		        my $utranCellIubLink = pick_a_mo($workingRNC,IubLink);
       	        	log_registry("utranCellIubLink selected for UtranCell is: $utranCellIubLink") if $utranCellIubLink;
                	log_registry("No utranCellIubLink has been picked from RNC $rnc for UtranCell") if not $utranCellIubLink;
                	return "0" if not $utranCellIubLink;
			my $localCellId = int(rand(65000));
			$rest_attr  = "$mandate_attrs"." "."localCellId"." "."$localCellId"." "."cId"." "."$localCellId"." "."utranCellIubLink"." "."$utranCellIubLink";
			$rest_attr  =~ s/\n+//g ;
		}
		else
		{
			($rnc_name,$rest_attr) = cell_attr_fdn($base_fdn,$attr_full,$workingRNC);
			$rest_attr = "$rest_attr"." "."$mandate_attrs";
		}
	}
	else
	{
		($rnc_name,$rest_attr) = cell_attr_fdn($base_fdn,$attr_full,$workingRNC); 
	}
        $attr_full = "$attr_full"." "."$rest_attr";
	$attr_full =~ s/\n+//g ;
	$base_fdn = "$base_fdn"."$rand";
	my $status_CS = does_mo_exist_CLI( base => "CSCLI", mo => $base_fdn);
	$base_fdn = "$base_fdn"."1" if ($status_CS eq "YES");
	$base_fdn = base_fdn_modify("$workingRNC","$base_fdn");
        log_registry("Creating Cell => $base_fdn $attr_full");
        my $create_result = create_mo_CS(mo =>"$base_fdn",attributes =>"$attr_full",plan => $plan_name);
        if ($create_result)
        {
                log_registry("Problem in creation of UtranCell \n $create_result");
                return 0;
        }
 	if($plan_name =~ /\w+/)
	{
	       my $activ_pl = activate_plan_area($plan_name);
               log_registry("Wait for some time <3 Mins> to get plan activated....");
               sleep 180;
               my $delete_pl = delete_plan_area($plan_name);
	       return "0" if ($activ_pl or $delete_pl);	
	}
        my $check_res =  does_mo_exist($base_fdn);
        if (!($check_res == $result_code_CS{MO_ALREADY_EXISTS}))
        {
        	log_registry("Error code is $check_res");
        	return 0;
        }
	else
	{
		log_registry("UtranCell $base_fdn : EXIST");
	}
  	return($base_fdn);
}

############################################
#
#  Checking reserveBy attribute of a MO
#
###########################################

sub is_resby
{
  my ($mo1,$mo2,$nolog) = @_;

  my $found = 0; # i.e. false

  log_registry("It seems there is no mo fdn passed to match reserveBy ...") if not $mo2;
  return "0" if not $mo2;
  my %rezzy = get_mo_attributes_CS( mo => $mo1, attributes => "reservedBy");
  my $resby = $rezzy{reservedBy};
  log_registry("It seems there is no value set for reservedBy attribute of mo $mo1 ...") if not $resby;
  return "0" if not $resby;
  chop($resby);
  chomp($resby);
  chomp($mo2);                             # We need a exact match of full FDN

  $found = 1 if $resby =~ m/$mo2/;  # i.e. true
  log_registry("$mo2 is Found in reservedBy attribute of mo $mo1 ") if $found;
  log_registry("$mo2 is not Found in reservedBy attribute of mo $mo1 ") if not $found;
  log_registry("Didn't find it: $found ; $resby") if (!($found) and !($nolog));
  return $found;
}

##############################################
#
# Node version checking
#
#############################################
sub node_version
{
   my $mec = shift;
   my $ver = shift;
   my %result = get_mo_attributes_CS( mo => $mec, attributes => "neMIMversion neMIMName");
   my $nodetype = $result{neMIMName};
   my $version = $result{neMIMversion};
   if($nodetype =~ /^RNC/)
   {
   	#Additional checks for new RNC or old RNC
   	my $ver_newRNC = "vV";
   	my $flag = "OLD";
   	$version = substr($version,0,2);
   	$flag = "NEW" if ($version ge $ver_newRNC);
	log_registry("Version of given RNC is: $result{neMIMversion}");
   	return("$result{neMIMversion}",$flag);
   }
   elsif($nodetype =~ /^ERBS/)
   {
	#Additional checks for new ERBS or old ERBS
	my $ver_newERBS;
	$ver_newERBS = "vE_1_63" if(!($ver) or $ver eq "NEW" or $ver eq "OLD");
	$ver_newERBS = "$ver" if($ver and ($ver ne "NEW" and $ver ne "OLD"));
	$ver_newERBS =~ s/\s*//g; $ver_newERBS =~ s/\n+//g;
	log_registry("Demanded ERBS node version: $ver_newERBS or later") if($ver and ($ver ne "NEW" and $ver ne "OLD")); 
	my @arr1 = split(/\./,$version);
	my @arr2 = split(/\./,$ver_newERBS);
	my $flag = "OLD";
	log_registry("Compare $arr1[0] with $arr2[0] and $arr1[1] with $arr2[1]"); 
	if($arr1[0] eq $arr2[0])
	{
		$flag = "NEW" if (($arr1[1] >= $arr2[1]) and ($arr1[2] >= $arr2[2]));
		$flag = "$ver" if ($ver and ($ver ne "NEW" and $ver ne "OLD") and ($arr1[1] >= $arr2[1]) and ($arr1[2] >= $arr2[2]));
	}
	$flag = "NEW" if ($arr1[0] gt $arr2[0]);
	$flag = "$ver" if ($ver and ($ver ne "NEW" and $ver ne "OLD") and $arr1[0] gt $arr2[0]);
	log_registry("Version of given ERBS is: $version");
	return("$result{neMIMversion}",$flag);
   }
   return($result{neMIMversion});
}

sub pick_a_erbs_using_cell
{
    my %param = ( MO => "", CELL => "EUtranCellTDD", VER => "", @_);
    my $cell = $param{CELL};
    $cell = $param{MO} if $param{MO};
    my $version = $param{VER};
    log_registry("$cell,$version");

    my $selected_cell = pick_a_ne($cell,$version);
    log_registry("$selected_cell");
    my @temp_arr = split("\,",$selected_cell);
    my $erbs = "";
    my $alert = 0;
    my $comma = 0;
    foreach my $mm (@temp_arr)
    {
        if($alert == 0)
        {
                if($comma > 0){ $erbs = "$erbs"."," ; }
                $erbs = "$erbs"."$mm";
        }
        if($mm =~ /ENodeBFunction/) { $alert = 1;  }
        $comma++;
   }
   log_registry("***** Finished and selecting ERBS: $erbs");
   return $erbs;
}

####################################################
#  Applied for 11.2 OSSRC onwards
#  Based on OSSRC package MO FDN has one base changes
#
#####################################################

sub shipment_chk
{
	my $freq = shift;
        my @a = split(" ",$freq);
        my @b = split("\_",$a[1]);
        my @t = split(/\./,$b[$#b]);
        my $flag = 0;
        $flag = 1 if ($t[0] < "11");
        $flag = 1 if ($t[0] == "11" and $t[1] < "2");
	$freqmanagement = "FreqManagement=1" if not $flag;
	$freqmanagement = "" if $flag;
}


sub delete_mo_thats_reserved
{
  my $delMo = shift;

  # for each reservedBy, remove MO

  my %xyz = get_mo_attributes_CS(mo => $delMo, attributes => "reservedBy");
  my @zzz = split /\040/, $xyz{reservedBy};
  foreach my $resby(@zzz)
  {
  log_registry("Deleting reserving MO: $resby ... ");
  delete_mo_CS(mo => $resby);
  }
  log_registry("Deleting the Mo $cell ... ");
  my  $result = delete_mo_CS( mo => $delMo);

  if ($result)
  {
    log_registry("Error code is $result, error message is $result_code_CS{$result}");
    return;
  }


}

sub remove_rdn
{
   my $element = $_[0];
   my @temp_arr = split("\,",$element);
   my $rdn;
   for(my $count = 0; $count < $#temp_arr ; $count++)
   { 
	$rdn = $rdn."$temp_arr[$count]".",";
   }
   chop($rdn); # remove the last ,
   return $rdn;
}


1;
