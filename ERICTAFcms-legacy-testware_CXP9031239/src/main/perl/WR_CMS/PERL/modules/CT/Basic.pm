#!/usr/bin/perl

#########################################################
#
# To check precondition and select TestCase Sub Routine
#
#########################################################

sub do_test_master
{
   my $test = shift;
      $test_time = get_time_string();# Test Start Time
      $smlog_time = sleep_start_time();
   my $s_time = substr($test_time,11,5)."  "."on"."  ".substr($start_time,8,2).substr($start_time,4,4).substr($start_time,0,4);
   log_registry("$test Started at $s_time");

   preconditions_OK() or die "Preconditions not valid\n";

   my $test_slogan = $test;     # save the test_slogan
   $test_slogan =~ s/.*_//;     # Test case id only
   $test_slogan = "Test Case"." "."$test_slogan ";
   $test =~ s/_.*//;            # remove numerical suffix to get test subroutine name
   no strict qw(refs);          # turn off strict refs checking so that next line can call subroutine with test name
   $test->($test_slogan);       # call the subroutine to do the actual test
   sybase_event_log();
}

sub do_test_proxy
{
   my $test = shift;
   my $TC = shift;
      $test_time = get_time_string();# Test Start Time
      $smlog_time = sleep_start_time();
   my $s_time = substr($test_time,11,5)."  "."on"."  ".substr($start_time,8,2).substr($start_time,4,4).substr($start_time,0,4
);
   log_registry("$test Started at $s_time");

   preconditions_OK() or die "Preconditions not valid\n";

   cli_proxy_handle("start") if ($TC eq "SINGLE");   # To start the CLI Proxy for single TCs always
   cli_proxy_handle("start") if (($TC =~ /\d+/) and ($TC == "0")); # To start the CLI Proxy for all TCs only once
   sleep 60;
   my $test_slogan = $test;     # save the test_slogan
   $test_slogan =~ s/.*_//;     # Test case id only
   $test_slogan = "Test Case"." "."$test_slogan ";
   $test =~ s/_.*//;            # remove numerical suffix to get test subroutine name
   no strict qw(refs);          # turn off strict refs checking so that next line can call subroutine with test name
   $test->($test_slogan);       # call the subroutine to do the actual test
   sybase_event_log();
   cli_proxy_handle("stop") if ($TC eq "SINGLE");    # To stop the CLI Proxy for single TCs always
}

##################################################################################################
#
# It is used to get current time in sybase Time format. 
# Any integer value passed to sub routine would cause those number of mins added to current time
#
###################################################################################################
sub sleep_start_time
{
	my ($sec,$min, $hour, $day, $month, $year) = (localtime)[0..5];
   	my $cur_time = sprintf("%4d-%02d-%02dT%02d:%02d:%02d",$year+1900 , $month+1 , $day , $hour , $min , $sec);
      	return $cur_time;
}

######################################################
#
# To know FDN of MOs
#
######################################################

sub get_fdn
{
  my $MO_TYPE = $_[0];
  my $cfg_type = $_[1];
  my $key_line = 0;
  my @MO = ();
  my @base_fdn = ();
  my @attr    = ();

  if ( $cfg_type =~ /create/ )
  {
    open(CFGCMFILE,"$cfg_cm_file") or die "Unable to read the configuration file $cfg_cm_file";
  }
  elsif ( $cfg_type =~ /delete/ )
  {
    open(CFGCMFILE,"$cfg_dm_file") or die "Unable to read the configuration file $cfg_dm_file";
  } 
  elsif ( $cfg_type =~ /set/ )
  {
    open(CFGCMFILE,"$cfg_set_file") or die "Unable to read the configuration file $cfg_set_file";
  }
  else
  {
    die "Unable to read the configuration file";
  }

  while( <CFGCMFILE> )
  {
      s/#.*//;            # ignore comments by erasing them
      next if /^(\s)*$/;  # skip blank lines
      if ($_ =~ /^(\s)Begin $MO_TYPE$/)
      {
         $key_line = 1;
      }
      if ($_ =~ /^(\s)End $MO_TYPE$/)
      {
         $key_line = 0;
      }
      if ( $key_line == 1)
      {
         push @MO, $_; # push the data line onto the array
      }
  }
  
  my $FDN_MO = $MO[1];

  shift(@MO); # Removing Begin line from Array MO
  
  my @temp_array = split(";",$FDN_MO);

  push @base_fdn ,$top_one;

  if($freqmanagement and ($MO_TYPE =~ /Freq/ and !($MO_TYPE =~ /^UtranFrequency/ or $MO_TYPE =~ /^Cdma2000Freq/ or $MO_TYPE =~ /^Gera/ or $MO_TYPE =~ /^EutranFreq/ or $MO_TYPE =~ /GeranFrequency/ or $MO_TYPE =~ /^EUtranFreq/)))
  {
    push @base_fdn,$freqmanagement;
  }

  foreach ( @temp_array )
  {
     my $temp_value = $_;
     if ($temp_value =~ /.*=/ and !($temp_value =~ /\+/) )
     {
       push @base_fdn ,$temp_value;
     }
     else
     {
       push @attr ,$temp_value;
     }
  }
   my $fdn_base = join(',',@base_fdn);
   my $fdn_attr = join(' ',@attr);
   close(CFGCMFILE);
   return ("$fdn_base","$fdn_attr"); 
}

########################################################################
#
# To Read the Cache for final Verfication
#
########################################################################

sub cache_file
{
  my $review_log = "/tmp/review_cache_$$.log";
  `$review_cache > $review_log`;
  my $file_name = `grep SNAD_C $review_log`;
  log_registry("It seems there is no entry of SNAD_C in $review_log file...") if not $file_name;
  return "0" if not $file_name;
  chomp($file_name);
  `mv $file_name $review_log`;
  return $review_log;  
}

######################################################################
#
# To check "wait for long sleep"
#
######################################################################

sub long_sleep_found
{
  my $time  = $_[0];
  if(!$time)
  {
	$time = $smlog_time;  
  }
  my $long_sleep = wait_for_long_sleep_sybase($time);
  my $count_wait = 0;
  if($long_sleep)
  {
	log_registry("wait for long sleep found -> $long_sleep");
	print "wait for long sleep found....\n";
  }
  else
  {
  	until($long_sleep)
  	{
     		log_registry("Waiting for Long sleep.......");
     		sleep 120;
     		$count_wait++;
     		if( $count_wait == 31 )
     		{
        		$long_sleep = "wait for long sleep is not found since last 2 hours......, Script is leaving to search wait for long sleep\n";
        		log_registry("$long_sleep");
        		print "$long_sleep....., please consult the Log... \n";
     		}
     		else
     		{
        		$long_sleep = wait_for_long_sleep_sybase($time);
        		if($long_sleep)
        		{
	            		log_registry("wait for long sleep found -> $long_sleep");
            			print "wait for long sleep found....\n";
        		}
     		}
  	}
   }
}

######################################################################
#
# To check ERRORS in sybase log 
#
######################################################################

sub sybase_event_log
{
  my $time  = $_[0];
  if(!$time)
  {
        $time = $smlog_time;
  }
  my $error_log = log_check_sybase($time);

  if($error_log)
  {
      log_registry("===========================================================================================");
      log_registry("Following ERROR found in the event log, please analyze them.... \n $error_log");
      log_registry("===========================================================================================");
  }
  else
  {
      log_registry("No ERROR found in the sybase event log");
  }
} 

#######################################################################
#
# Decision making to create MO
#
#######################################################################

sub mo_create_decision
{
 my ($test_slogan,$base_fdn, $attr,$plan_name,$wait) = ($_[0], $_[1], $_[2],$_[3],$_[4]);
 if ($base_fdn)
 {
   log_registry("Master Mo -> FDN mentioned in config file for test case is $base_fdn");
 }
 else
 {
   log_registry("FDN is not defined in config file");
   if($test_slogan)
   {
      test_failed($test_slogan);
   }
   return;
 }
 my $time = sleep_start_time();
 my $status = get_master($base_fdn); 
 my $master_cr = "";
 my $activ_pl = "";
 my $delete_pl = "";
 if( $status == 0 )
     {
        log_registry("Master Mo Does not exist");
        if($plan_name)
	{
	  my $plan_exist = plan_area_exist($plan_name);
          if($plan_exist == 0)
          {
  	     my $plan = create_plan_area($plan_name); 
   	     if($plan)
	     {
               $master_cr = create_master($base_fdn,$attr,$plan);
               $activ_pl = activate_plan_area($plan_name);
	       log_registry("Wait for some time <2 Mins> to get plan activated....");
  	       sleep 120;
	       $delete_pl = delete_plan_area($plan_name);
	     }
	     else
	     {
 		test_failed($test_slogan) if $test_slogan;
	     }
          }
	  else
          {
             log_registry("Plan already exist, so please run the test case again to avoid confilcts of existing plan");
             test_failed($test_slogan) if $test_slogan; 
          }   	
        }     
        else
	{
            $master_cr = create_master($base_fdn,$attr);
	}
        if($master_cr or $activ_pl or $delete_pl)
        {
           test_failed($test_slogan) if $test_slogan;
        }
        else
        {
	  if($test_slogan)
          {
          	log_registry("Wait for some time to get Master Consistent");
          	long_sleep_found($time);
	  }
	  else
	  {
		log_registry("Wait for 2 mins.....") if not $wait;
		sleep 120 if not $wait;
		long_sleep_found($time) if $wait;
    	  }
          get_master($base_fdn);
          get_proxies_master($base_fdn);
          my $review_cache_log = cache_file();
          my $rev_log = rev_find(file => $review_cache_log,mo => $base_fdn);
          if($rev_log)
          {
             log_registry("Review_Log -> Master Mo $FDN Exist in Review Cache");
             test_passed($test_slogan) if $test_slogan;
	     return OK;
          }
          else
          {
             log_registry("Review_Log -> Master Mo $FDN does not Exist in Review Cache");
             test_failed($test_slogan) if $test_slogan;
          }
        }
     }
     elsif ($status == 1)
     {
        log_registry("Master Mo already exist and Consistent");
        if($test_slogan)
        {
           get_proxies_master($base_fdn);
           test_failed($test_slogan);
        }
  	return "KO";
     }
     elsif ($status == 2)
     {
        log_registry("Master Mo already exist but Not Consistent");
        if($test_slogan)
        {
           get_proxies_master($base_fdn);
           test_failed($test_slogan);
        }
  	return "KO";
     }
     elsif ($status == 3)
     {
        log_registry("Master Mo already exist");
        if($test_slogan)
        {
           test_failed($test_slogan);
        }
  	return "KO";
     }
     else
     {
        log_registry("Anonymus State");
        if($test_slogan)
        {
           test_failed($test_slogan);
        }
  	return "KO";
     }
}

#######################################################################
#
# Decision making to delete MO
#
#######################################################################

sub mo_delete_decision
{
 my ($test_slogan,$base_fdn, $attr,$plan_name,$nowait) = ($_[0], $_[1], $_[2],$_[3],$_[4]);
 if ($base_fdn)
 {
   log_registry("Master Mo -> FDN mentioned is $base_fdn");
 }
 else
 {
   log_registry("FDN is not defined for test case");
   test_failed($test_slogan) if $test_slogan;;
   return;
 }
 my $time = sleep_start_time();
 my $status = get_master($base_fdn);
 my $master_de = "";
 my $activ_pl = "";
 my $delete_pl = "";
 if( $status == 1 || $status == 2 || $status == 3 )
     {
        log_registry("Master Mo exist");
        if($plan_name)
	{
		my $plan_exist = plan_area_exist($plan_name);
          	if($plan_exist == 0)
         	 {
             		my $plan = create_plan_area($plan_name);
             		if($plan)
             		{
               			$master_de = delete_master($base_fdn,$attr,$plan);
               			$activ_pl = activate_plan_area($plan_name);
 				log_registry("Wait for some time <2 Mins> to get plan activated");
				sleep 120;
               			$delete_pl = delete_plan_area($plan_name);
             		}
             		else
             		{
				if($test_slogan) { test_failed($test_slogan); }
             		}
		  }
		else
		{
			log_registry("Plan already exist,so please re run test case to avoid confilcts of existing plan");
                	if($test_slogan) { test_failed($test_slogan); }
		}
	}
	else
	{
           $master_de = delete_master($base_fdn);
	}
	if($master_de or $activ_pl or $delete_pl)
	{
		if($test_slogan) { test_failed($test_slogan); }
	}
	else
	{
   	        log_registry("Wait for some time..........");
		long_sleep_found($time) if not $nowait;
		sleep 120 if $nowait;
       		get_master($base_fdn);
        	my $review_cache_log = cache_file();
        	my $rev_log = rev_find(file => $review_cache_log,mo => $base_fdn);
        	if ($rev_log)
        	{
       		      log_registry("Review_Log -> Master Mo $FDN Exist in Review Cache");
       		      if($test_slogan) { test_failed($test_slogan); }
        	}
        	else
        	{
             		log_registry("Review_Log -> Master Mo $FDN does not Exist in Review Cache");
             		if($test_slogan) { test_passed($test_slogan); }
			return "OK";
        	}
	}
     }
     elsif ($status == 0)
     {
        log_registry("Master Mo does not exist");
        if($test_slogan) { test_failed($test_slogan); }
     }
     else
     {
        log_registry("Anonymous State");
        if($test_slogan) { test_failed($test_slogan); }
     }
}

#######################################################################
#
# Decision making to set attributes of  MO
#
#######################################################################

sub mo_set_decision
{
 my ($test_slogan,$base_fdn, $attr,$plan_name,$long_sleep) = ($_[0], $_[1], $_[2],$_[3],$_[4]);
 if ($base_fdn)
 {
   log_registry("Master Mo -> FDN mentioned in config file for test case is $base_fdn");
 }
 else
 {
   log_registry("FDN is not defined in config file");
   test_failed($test_slogan) if $test_slogan;
   return;
 }
 my $time = sleep_start_time();
 my $status = get_master($base_fdn); 
 my $master_set = "";
 my $activ_pl = "";
 my $delete_pl = "";
 my $count_attr = "";
 if( $status == 1 or $status == 2 )
     {
        log_registry("Master Mo exist... ");
        if($plan_name)
	{
	  my $plan_exist = plan_area_exist($plan_name);
          if($plan_exist == 0)
          {
  	     my $plan = create_plan_area($plan_name); 
   	     if($plan)
	     {
	       log_registry("========= Attributes of MO Before =========");
               $count_attr = get_mo_attr($base_fdn,$attr);
	       log_registry("===========================================");
               $master_set = set_attr_master($base_fdn,$attr,$plan);
               $activ_pl = activate_plan_area($plan_name);
	       log_registry("Wait for some time <2 Mins> to get plan activated....");
	       sleep 120;
	       $delete_pl = delete_plan_area($plan_name);
	     }
	     else
	     {
 		test_failed($test_slogan) if $test_slogan;
		return;
	     }
          }
	  else
          {
             log_registry("Plan already exist, so please run the test case again to avoid confilcts of existing plan");
             test_failed($test_slogan) if $test_slogan;
	     return;
          }   	
        }     
        else
	{
	    log_registry("========= Attributes of MO Before =========");
            $count_attr = get_mo_attr($base_fdn,$attr);
	    log_registry("===========================================");
            $master_set = set_attr_master($base_fdn,$attr);
	}
        if($master_set or $activ_pl or $delete_pl)
        {
           test_failed($test_slogan) if $test_slogan;
	   return;
        }
        else
        {
          log_registry("Wait for some time to get Master Consistent");
	  if(!($long_sleep) and ($count_attr == 1))
	  {
		log_registry("Waiting for 2 mins only");
		sleep 120;
          }
          elsif($long_sleep and ($long_sleep eq "NOWAIT"))
	  {
		log_registry("Waiting for 2 mins only");
		sleep 120;
	  }
	  else	
	  { 
           	long_sleep_found($time);
	  }
	  log_registry("========= Attributes of MO After =========");
	  get_mo_attr($base_fdn,$attr);
	  log_registry("===========================================");
          get_master($base_fdn);
	  my $stat = attr_value_comp($base_fdn,$attr);
          get_proxies_master($base_fdn);
          my $review_cache_log = cache_file();
          my ($rev_log,$rev_state) = rev_find(file => $review_cache_log,mo => $base_fdn);
          if ($rev_log and $stat)
          {
             log_registry("Review_Log -> Master Mo $FDN Exist in Review Cache and attributes has been modified");
             test_passed($test_slogan) if $test_slogan;
	     return OK;
          }
	  elsif($rev_log and !($stat))
	  {
	    log_registry("Review_Log -> Master Mo $FDN Exist in Review Cache but attributes does not get modified");
            test_failed($test_slogan) if $test_slogan;
          }
          else
          {
             log_registry("Review_Log -> Master Mo $FDN does not Exist in Review Cache");
             test_failed($test_slogan) if $test_slogan;
          }
        }
     }
     elsif ($status == 0)
     {
        log_registry("Master Mo does not exist");
        test_failed($test_slogan) if $test_slogan;
     }
     elsif ($status == 3)
     {
        log_registry("Master Mo exists and already modified once");
        test_failed($test_slogan) if $test_slogan;
     }
     else
     {
        log_registry("Anonymus State");
        test_failed($test_slogan) if $test_slogan;
     }
}


####################################################
#
# Attributes checking for MO
#
####################################################

sub attrs_chk
{
   my $attributes = shift;
   my @attrs = ();
   $attributes =~ s/^\s+//;  # remove leading whitespace
   my @values = (); 
   if ($attributes)
   {
      @attrs_t = split /\s+/, $attributes;
      for( my $i = 0; $i < ($#attrs_t+1) ; $i = $i + 2 )
      {
         push @attrs, $attrs_t[$i] ;
      }
      for( my $j = 1; $j < ($#attrs_t+1) ; $j = $j + 2 )
      {
	 push @values, $attrs_t[$j] ;
      }
   }
   my $count_attr = $#attrs + 1; 
   my $attr = join(' ',@attrs);
   return ($attr,$count_attr,\@attrs,\@values);
}

#########################################################
#
# To compare attributes values after set 
#
#########################################################
sub attr_value_comp
{
    my $mo = $_[0];
    my $attrs = $_[1];
    my $alert = 0;
    my $count = 0;
    my ($attributes,$count_attr,$attr,$values) = attrs_chk($attrs);
    log_registry("To compare attributes given MO is: $mo"); 
    log_registry(" Attributes are => $attributes \n number of attributes are => $count_attr ");
    my %rezzy = get_mo_attributes_CS( mo => $mo, attributes => $attributes);
    foreach (@{$attr})
    {
	my $att = $_;
	my $value_cs = $rezzy{$att};
	log_registry("Current value of attribute $att in cstest is => $value_cs");
	my $value_cfg = $$values[$count];
	log_registry("Value of attribute $att in configuration file is => $value_cfg");
	if($value_cfg =~ /\w+/)
	{
		if(!($value_cfg =~ /\+/))
		{
			if($value_cfg ne $value_cs) {  $alert = 1; }
		}
	}
	else
	{
		if($value_cfg != $value_cs) {  $alert = 1; }
	}
	$count++;
    }
    if($alert)
    {
	log_registry("Attributes have not modified for the MO: $mo");
	return;
    }
    return OK;
}

#########################################################
#
# To compare attributes values of CS and NE
#
#########################################################
sub attr_value_comp_NE_CS
{
    my $mo = $_[0];
    my $attrs = $_[1];
    my $alert = 0;
    my $count = 0;
    my %rezzy = get_mo_attributes_CS( mo => $mo);
    my %nezzy = get_mo_attributes_NE( mo => $mo);
    my ($attributes,$count_attr,$attr,$values) = attrs_chk($attrs);
    log_registry(" Attributes are => $attributes \n number of attributes are => $count_attr ");
    foreach (@{$attr})
    {
        my $att = $_;
        my $value_cs = $rezzy{$att};
        log_registry("Current value of attribute $att in CS is => $value_cs");
        my $value_cfg = $$values[$count];
        log_registry("Value of attribute $att in configuration file is => $value_cfg");
	my $value_ne = $nezzy{$att};
	log_registry("Value of attribute $att in NE is => $value_ne");
        if($value_cs =~ /\w+/)
        {
                if($value_ne ne $value_cs) {  $alert = 1; }
        }
        else
        {
                if($value_ne != $value_cs) {  $alert = 1; }
        }
        $count++;
    }
    if($alert)
    {
        log_registry("Attributes is not matching for the MO: $mo in CS and NE");
        return;
    }
    return OK;
}

###########################################################
#
# To write STDERR output in log file with die messages
#
###########################################################

sub error_writer
{
  my $file = shift;
  my $die = shift;
  log_registry("===================================================================================================");
  log_registry("======= FOLLOWING DATA IS DISPLAYED DURING EXECUTION OF SCRIPT ON STDERR/STDOUT CONSOLE ========");
  log_registry("===================================================================================================");
  open ERROR_FILE, "$file";
  my @error = <ERROR_FILE>;
  log_registry("@error");
  log_registry("DIE Message: $die") if $die;
  log_registry("===================================================================================================");
  close ERROR_FILE;
  `rm -f $file`;
   @error = "";
}

############################################################
#
# TO handle start and stop proxy of CLI utility
#
############################################################

sub cli_proxy_handle
{
  my $action = shift;
  my $proxy = $key_proxy;
  log_registry("Checking for Process: $proxy");
  my $status = `ps -edf | grep $proxy | grep -v grep`;
  log_registry("Process matching criteria: $status") if $status;
  log_registry("Process matching criteria: No running Proxy found") if not $status;
  my $len_test = `ps -edf | grep $proxy | grep -v grep | wc -l` if $status;
  if( $action eq "start" )
  {
  	log_registry("Proxy for CLI utility is already running, so CLI utility will use it no need to start it again....") if $status; 
	log_registry("WARNING => It seems multiple proxies are running of CLI utility.....") if ($len_test > 1) ;
	system("$cli_proxy &")  if not $status;
	log_registry("CLI proxy has been started ....") if not $status; 
  }
  if( $action eq "stop" )
  {
	log_registry("Proxy is not running, so can not do the STOP proxy action....") if not $status;
 	log_registry("Proxy of CLI is running... \n Number of CLI proxies are: $len_test") if $status ;	
  	if($status and ($len_test == 1))
	{
		my @temp = split (" ",$status);
	 	my $ppid = $temp[1];
		my $pid = `pgrep -P $ppid`;
		if( $pid !=1 and $ppid != 1 )
		{
			log_registry("Killing PPID = $ppid and PID = $pid");
			my $killed = `kill -9 $pid `;
			log_registry("Proxy process of CLI has killed...") if not $killed;
			log_registry("Proxy process of CLI has not killed...") if $killed;
		}	
		else
		{
			log_registry("WARNING => Proxy process of CLI has not killed because of PID selected is 1, KILL PID 1 may be harmful to server......");
		}
	}	
	else
	{
		log_registry("WARNING => It seems either no Proxy for CLI utility is running or more than 1 Proxies are running.....");
	}
  }
}

#########################################################################
#
# Basic condition check for the Proxy mo creation
#
#########################################################################

sub proxy_mo_create_decision
{
   my $base = shift;
   my $base_fdn = shift;
   my $attr = shift;
   my $nowait = shift;
   my $time = sleep_start_time();
   my $status = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attr);
   if($status eq OK) {
       log_registry("It seems MO get created..."); }
   else {
       log_registry("Problem in creation of MO...");
       return (0,0); }
   my $nudge_state;
   $nudge_state = nudge_cc_sybase($time);
   log_registry("It seems CC has not nudged...") if not $nudge_state;
   log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
   long_sleep_found($time) if not $nowait;
   log_registry("wait for 1 mins to get system stabilized...") if $nowait;
   sleep 60 if $nowait;
   my $review_cache_log = cache_file();
   my ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
   get_proxy($base_fdn);
   get_mo_attr($base_fdn) if $rev_log;
   return (0,0) if not $rev_id;
   return (OK,$rev_id);
}

#########################################################################
#
# Basic condition check for the Proxy mo attributes modifcation 
#
#########################################################################

sub proxy_mo_set_decision
{
   my $base = shift;
   my $base_fdn = shift;
   my $attr = shift;
   my $cc_nudge = shift;
   log_registry("========= Attributes of MO Before =========");
   my $count_attr = get_mo_attr($base_fdn,$attr);
   log_registry("===========================================");
   log_registry("Checking given mo is a master or proxy..");
   my $does_master = get_master("$base_fdn");
   my $master_mo;
   $master_mo = get_master_for_proxy($base_fdn) if not $does_master;
   log_registry("Master Mo for the Given Proxy is: \n $master_mo") if $master_mo;
   log_registry("There is no Master MO exist for the proxy $base_fdn") if not ($master_mo or $does_master);
   my @master_temp = split("\n",$master_mo) if $master_mo;
   my $no_master = scalar(@master_temp) if $master_mo;
   log_registry("It seems Proxy has multiple master...") if ($master_mo and ($no_master > 1));
   my $status = set_attributes_mo_CLI(mo => $base_fdn, base => $base, attributes => $attr);
   my $time = sleep_start_time();
   if($status eq OK) {
      log_registry("It seems attributes of MO get set..."); }
   else {
      log_registry("Problem in setting attributes of MO...");
      return (0,0); }
   my $nudge_state;
   $nudge_state = nudge_cc_sybase($time);
   log_registry("It seems CC has not nudged...") if not $nudge_state;
   log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
   my $force_nudge;
   $force_nudge = forceCC($base_fdn) if (!($nudge_state) and $cc_nudge and ($cc_nudge eq "FN"));
   $count_attr = 1 if ($cc_nudge and ($cc_nudge ne "FN"));
   $count_attr = 0 if ($cc_nudge and ($cc_nudge eq "NW"));
   $time = $force_nudge if $force_nudge;
   long_sleep_found($time) if ($count_attr > 1 or $force_nudge);
   log_registry("Wait for <2 mins> to get system stabilized...") if ($count_attr == 1);
   sleep 120 if ($count_attr == 1);
   my $stat = attr_value_comp($base_fdn,$attr);
   log_registry("========= Attributes of MO After =========");
   get_mo_attr($base_fdn,$attr);
   log_registry("===========================================");
   my $master_stat = 0;
   $master_stat = 1 if ($master_mo and ($no_master == 1));
   $master_mo =~ s/\n+//g if $master_mo;
   $master_stat = attr_value_comp($master_mo,$attr) if ($master_mo and ($no_master == 1));
   log_registry("It seems master mo is unaffected with the change in Proxy mo") if (!($master_stat) and $master_mo);
   my $review_cache_log = cache_file();
   my ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn);
   get_proxy($base_fdn);
   return (OK,$rev_id) if ($stat and !($master_stat));
   return (0,$rev_id) if not $stat;
}

#########################################################################
#
# Basic condition check for the Proxy mo deletion 
#
#########################################################################

sub proxy_mo_delete_decision
{
   my $test_slogan = shift;
   my $base = shift;
   my $base_fdn = shift;
   my $is_rel = shift; #cheking whether a relation, if so then no need to do review cache
   my $status = delete_mo_CLI(mo => $base_fdn, base => $base);
   if($status eq OK)
   {
      log_registry("It seems MO get deleted...");
   }
   else
   {
      log_registry("Problem in deletion of MO...");
      test_failed($test_slogan) if $test_slogan;
      return "0";
   }
   log_registry("Wait for <2> mins to get system stabilized....");
   sleep 120;
   my $rev_id,$rev_log;
   if(!($is_rel)) {
   	my $review_cache_log = cache_file();
   	($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $base_fdn); }
   else {
	my $status = does_mo_exist_CLI( base => $base, mo => $base_fdn);
	$rev_id = 0 if ($status eq "NO");
	$rev_id = 1 if ($status eq "YES");  }
   log_registry("Proxy Mo : $base_fdn no more exist....") if ($rev_id == 0);
   test_passed($test_slogan) if($test_slogan and ($rev_id == 0));
   test_failed($test_slogan) if($test_slogan and ($rev_id != 0));
   return "0" if($rev_id != 0);
   return "1" if($rev_id == 0);
}

##############################################################################
#
# It is used to change root name for MO fdn and make it usable for script
#
##############################################################################

sub base_fdn_modify
{
    my $node  = shift;
    my $base_fdn = shift;
    $base_fdn =~ s/$top_one//g;
    $base_fdn = "$node"."$base_fdn";
    $base_fdn =~ s/\n+//g ;
    return "$base_fdn";
}

#############################################################################
#
# To create UtranRelation
#
#############################################################################
sub create_UtranRelation
{
	my %param = (F_UtranCell => "" ,S_UtranCell => "",base =>"CSCLI",EUC => "",RNC => "SAME",FREQ => "SAME",uCR=>"",@_ );
	my $utran_cell_1 = $param{F_UtranCell};
	my $utran_cell_2 = $param{S_UtranCell};	
	$utran_cell_2 = $param{EUC} if $param{EUC};
 	my $base = $param{base};
        my $uCR = $param{uCR} if $param{uCR};
        log_registry("Selected UtranCell for UtranRelation is: $utran_cell_1");
	my $rrr = int(rand(80));
        my $base_fdn = "$utran_cell_1".","."UtranRelation=$mo_proxy_cms"."$rrr";
		my $status_temp = does_mo_exist_CLI( base => "CSCLI", mo => $base_fdn);
		$base_fdn = "$base_fdn"."1" if ($status_temp eq "YES");
		
        log_registry("Utran Relation fdn will be : $base_fdn");
        log_registry("Other Cell selected for UtranRelation is $utran_cell_2");
        my $attr = "adjacentCell"." "."$utran_cell_2";
	$attr = "utranCellRef"." "."$uCR" if ($param{uCR} and !($utran_cell_2));
        my $time = sleep_start_time();
        my $status = create_mo_CLI(mo => $base_fdn, base => "$base", attributes => $attr);
        log_registry("It seems there is some problem during creation of UtranRelation...") if ($status ne "OK");
        return "0" if ($status ne "OK");
        long_sleep_found($time);
        my $status_NE = does_mo_exist_CLI( base => "CLI", mo => $base_fdn);
	my $status_CS = does_mo_exist_CLI( base => "CSCLI", mo => $base_fdn);
        log_registry("Specified MO => $base_fdn exist in node side...") if ($status_NE eq "YES");
        log_registry("Specified MO => $base_fdn does not exist in node side........") if ($status_NE ne "YES");
	log_registry("Specified MO => $base_fdn exist in CS...") if ($status_CS eq "YES");
        log_registry("Specified MO => $base_fdn does not exist in CS........") if ($status_CS ne "YES");
	$status = "YES" if ($status_CS eq "YES" and $status_NE eq "YES");
	$status = "NO"  if ($status_CS ne "YES" or $status_NE ne "YES");
        return "0" if ($status ne "YES");
        my %attrs = get_mo_attributes_CS( mo => $base_fdn, attributes => "adjacentCell utranCellRef nodeRelationType frequencyRelationType");
        log_registry("Attribute utranCellRef value for UtranRelation $base_fdn is: \n $attrs{utranCellRef}");
        log_registry("Attribute nodeRelationType value for UtranRelation $base_fdn is: \n $attrs{nodeRelationType}");
	log_registry("Attribute frequencyRelationType value for UtranRelation $base_fdn is: \n $attrs{frequencyRelationType}");
	log_registry("Attribute adjacentCell value for UtranRelation $base_fdn is: \n $attrs{adjacentCell}");
	return("$base_fdn","$attrs{adjacentCell}") if ($param{uCR} and !($utran_cell_2));
	return("$base_fdn","$attrs{utranCellRef}") if ($param{FREQ} eq "NOCHECK");
	my $nodeRelationType;
	my $utranCellRef;
   	my $frequencyRelationType;
	$nodeRelationType = "0" if ($param{RNC} eq "SAME"); #Intra based on RNC
	$nodeRelationType = "1" if ($param{RNC} ne "SAME"); #Inter based on RNC
	if($param{EUC})
	{
		$utranCellRef = "ExternalUtranCell"; 
	}
	else
	{
		$utranCellRef = "$utran_cell_2" if ($param{RNC} eq "SAME");
		$utranCellRef = "ExternalUtranCell" if ($param{RNC} ne "SAME");
	}
	$frequencyRelationType = "1" if ($param{FREQ} ne "SAME"); #Inter based on uplink/downlink freq
	$frequencyRelationType = "0" if ($param{FREQ} eq "SAME"); #Intra based on uplink/downlink freq
        my $flag = 0;
        $flag = 1 if ($attrs{utranCellRef} !~ /$utranCellRef/);
        $flag = 1 if ($attrs{nodeRelationType} != $nodeRelationType);
	$flag = 1 if ($attrs{frequencyRelationType} != $frequencyRelationType);
        log_registry("It seems utranCellRef,frequencyRelationType or nodeRelationType attributes value are not set properly....") if $flag;
        return "0" if $flag;
        log_registry("Checking reserveBy attribute of $utranCellRef .....");
	my $match;
        $match = is_resby("$utran_cell_2",$base_fdn) if ($param{RNC} eq "SAME" and !($param{EUC}));
	$match = is_resby("$attrs{utranCellRef}",$base_fdn) if ($param{RNC} ne "SAME" or $param{EUC});
        log_registry("It seems $utranCellRef reserve by match with the fdn of UtranRelation $base_fdn") if $match;
        log_registry("It seems $utranCellRef reserve by does not match with fdn of UtranRelation $base_fdn") if not $match;
	return "0" if not $match;
	return ("$base_fdn","$attrs{utranCellRef}"); # If successful then return UtranRelation fdn and utranCellRef FDN
}

#############################################################################
#
# To create UtranFreqRelation
#
#############################################################################
sub create_UtranFreqRelation
{
	my %param = (EUCTDD => "",EUCFDD => "",EUF => "",X_UFR =>"",base=>"CSCLI", UF=> "",@_);
        my $EUCxDD;
	$EUCxDD = $param{EUCTDD} if $param{EUCTDD};
	$EUCxDD = $param{EUCFDD} if $param{EUCFDD};
	my $EUF_fdn = $param{EUF};
	my $exist_UFR_fdn = $param{X_UFR};
	my $base = $param{base};
	my $UF_fdn = $param{UF};
	my $UFR_fdn = "$EUCxDD".","."UtranFreqRelation=$mo_proxy_cms";
	my $UFR_attr;
        $UFR_attr = "adjacentFreq"." "."$EUF_fdn" if $EUF_fdn;
	$UFR_attr = "utranFrequencyRef"." "."$UF_fdn" if $UF_fdn;
	my $time = sleep_start_time();
        my $result = create_mo_CLI(mo => $UFR_fdn, base => $base, attributes => $UFR_attr);
        log_registry("Problem in creation of of UtranFreqRelation MO.....") if ($result ne OK);
        return "0" if ($result ne OK);
	log_registry("Wait for 2 Mins to get system stabilized....") if not $UF_fdn;
	sleep 120 if not $UF_fdn;
	long_sleep_found($time) if $UF_fdn;
        my $status = does_mo_exist_CLI( base => "$base", mo => $UFR_fdn);
        log_registry("Specified MO => $UFR_fdn exist ...") if ($status eq "YES");
        log_registry("Specified MO => $UFR_fdn does not exist .......") if ($status ne "YES");
        return "0" if ($status ne "YES");
	get_mo_attr($UFR_fdn);
        my %attrs = get_mo_attributes_CS( mo => $UFR_fdn, attributes => "utranFrequencyRef adjacentFreq");
        log_registry("Attribute utranFrequencyRef value for UtranFreqRelation is : \n $attrs{utranFrequencyRef}");
        my $flag = 0;
        $flag = 1 if($attrs{utranFrequencyRef} !~ /UtranFrequency/);
        log_registry("It seems utranFrequencyRef attribute is not set for a proxy UtranFrequency MO...") if $flag;
        return "0" if $flag;
	if($UF_fdn)
	{
		$flag = 1 if ($attrs{adjacentFreq} !~ /ExternalUtranFreq/);
		$EUF_fdn = $attrs{adjacentFreq};
		log_registry("It seems adjacentFreq attribute is not set for a master ExternalUtranFreq MO....") if $flag;
		return "0" if $flag;
	}
        my $master_mo = get_master_for_proxy($attrs{utranFrequencyRef});
        $flag = 1 if ($master_mo !~ /$EUF_fdn/);
        log_registry("Master of Proxy MO $attrs{utranFrequencyRef} is: \n $master_mo");
        return "0" if $flag;
        log_registry("Checking reserveBy attribute of $attrs{utranFrequencyRef} .....");
        my $match;
        $match = is_resby("$attrs{utranFrequencyRef}",$UFR_fdn);
        log_registry("It seems reserveBy of proxy UtranFrequency has UtranFreqRelation MO....") if $match;
        log_registry("It seems reserveBy of proxy UtranFrequency do not have UtranFreqRelation MO....") if not $match;
        return "0" if not $match;
	if ($exist_UFR_fdn)
	{
		log_registry("Checking reserve by attribute of UtranFrequency for UtranFreqRelation $exist_UFR_fdn");
		my $match = is_resby("$attrs{utranFrequencyRef}",$exist_UFR_fdn);
		log_registry("It seems reserveBy of proxy UtranFrequency has UtranFreqRelation MO....") if $match;
		log_registry("It seems reserveBy of proxy UtranFrequency do not have UtranFreqRelation MO...") if not $match;
		return "0" if not $match;
	}
	return ($UFR_fdn,$attrs{utranFrequencyRef},$attrs{adjacentFreq});
}

#############################################################################
#
# To create EutranFreqRelation  # under an RNC
#
#############################################################################

sub create_EutranFreqRelation
{
        my %param = (UC => "",EEF => "",base=>"CSCLI",X_EFR => "",EF => "",@_);
        my $UtranCell = $param{UC};
        my $EEF_fdn = $param{EEF};
        my $base = $param{base};
        my $exist_EFR = $param{X_EFR};
        my $EF_fdn = $param{EF};
        my $EFR_fdn = "$UtranCell".","."EutranFreqRelation=$mo_proxy_cms";
        my $EFR_attr;
        $EFR_attr = "externalEutranFreq"." "."$EEF_fdn" if $EEF_fdn;
	$EFR_attr = "eutranFrequencyRef"." "."$EF_fdn" if $EF_fdn;
	my $time = sleep_start_time();
        my $result = create_mo_CLI(mo => $EFR_fdn, base => $base, attributes => $EFR_attr);
        log_registry("Problem in creation of of EutranFreqRelation MO.....") if ($result ne OK);
        return "0" if ($result ne OK);
	long_sleep_found($time) if ($EF_fdn and !($EEF_fdn));
        log_registry("Wait for 2 Mins to get system stabilized....");
        sleep 120;
        my $status = does_mo_exist_CLI( base => "$base", mo => $EFR_fdn);
        log_registry("Specified MO => $EFR_fdn exist ...") if ($status eq "YES");
        log_registry("Specified MO => $EFR_fdn does not exist .......") if ($status ne "YES");
        return "0" if ($status ne "YES");
        get_mo_attr($EFR_fdn);
        my %attrs = get_mo_attributes_CS( mo => $EFR_fdn, attributes => "eutranFrequencyRef externalEutranFreq");
        log_registry("Attribute eutranFrequencyRef value for EutranFreqRelation is : \n $attrs{eutranFrequencyRef}");
        my $flag = 0;
        $flag = 1 if(!($attrs{eutranFrequencyRef}) or $attrs{eutranFrequencyRef} !~ /EutranFrequency/);
        log_registry("It seems eutranFrequencyRef attribute is not set for a proxy EutranFrequency MO...") if $flag;
        return "0" if $flag;
        my $master_mo = get_master_for_proxy($attrs{eutranFrequencyRef});
	$EEF_fdn = $attrs{externalEutranFreq} if $EF_fdn;
        $flag = 1 if ($master_mo !~ /$EEF_fdn/);
	$flag = 1 if not ($master_mo and $EEF_fdn);
	log_registry("It seems externalEutranFreq attribute of Relation is not set to master ExternalEutranFrequency mo") if not $EEF_fdn;
	log_registry("No Master Mo exist for the EutranFrequency mo") if not $master_mo;
        return "0" if $flag;
        log_registry("Master of Proxy MO $attrs{eutranFrequencyRef} is: \n $master_mo");
        log_registry("Checking reserveBy attribute of $attrs{eutranFrequencyRef} .....");
        my $match;
        $match = is_resby("$attrs{eutranFrequencyRef}",$EFR_fdn);
        log_registry("It seems reserveBy of proxy EutranFrequency has EutranFreqRelation MO $EFR_fdn....") if $match;
        log_registry("It seems reserveBy of proxy EutranFrequency do not have EutranFreqRelation MO $EFR_fdn....") if not $match;
	return "0" if not $match;
	if($exist_EFR) {
		my $match1 = is_resby("$attrs{eutranFrequencyRef}",$exist_EFR);
		log_registry("It seems reserveBy of proxy EutranFrequency has EutranFreqRelation MO $exist_EFR....") if $match1;
		log_registry("It seems reserveBy of proxy EutranFrequency do not have EutranFreqRelation MO $exist_EFR ....") if not $match1;
       		return "0" if not $match1; }
        return ($EFR_fdn,$attrs{eutranFrequencyRef});
}

#############################################################################
#
# To create UtranCellRelation  
#
#############################################################################
sub create_UtranCellRelation
{
	my %param = ( UFR => "", EUC => "",UC =>"",base=>"CSCLI",EUCFDD => "",@_);
	my $UFR_FDN = $param{UFR};
	my $EUC = $param{EUC};
	my $base = $param{base};
	my $UtranCell = $param{UC};
	my $EUCFDD = $param{EUCFDD};
	my $UCR_attrs;
	$UCR_attrs = "adjacentCell"." "."$EUC" if $EUC;
	$UCR_attrs = "adjacentCell"." "."$UtranCell" if $UtranCell;
	$UCR_attrs = "externalUtranCellFDDRef"." "."$EUCFDD" if $EUCFDD;
	$UCR_attrs = "adjacentCell"." "."$EUC"." "."externalUtranCellFDDRef"." "."$EUCFDD" if ($EUCFDD and $EUC);
	$UCR_attrs = "adjacentCell"." "."$UtranCell"." "."externalUtranCellFDDRef"." "."$EUCFDD" if ($EUCFDD and $UtranCell);
	my $UCR_FDN = "$UFR_FDN".","."UtranCellRelation=$mo_proxy_cms";
	my $result = create_mo_CLI(mo => $UCR_FDN, base => $base, attributes => $UCR_attrs);
	log_registry("Problem in creation of UtranCellRelation .....") if ($result ne OK);
	return "0" if ($result ne OK);
	log_registry("It seems UtranCellRelation has been created..");
	my $time = sleep_start_time();
	my $flag = 0;
	long_sleep_found($time) if ($base eq "CLI");
	
	log_registry("It seems UtranCellRelation gets A second nudge ... wait for it...");         # EEITJN not needed TR HQ69669 
   	sleep(90);
#   	$time = sleep_start_time();
#   	my $nudge_state = nudge_cc_sybase($time);
#   	log_registry("It seems CC has not nudged...") if not $nudge_state;
#   	log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
#	my $force_nudge;
#   	$force_nudge = forceCC($EUCFDD) if (!($nudge_state));
#   	$time = $force_nudge if $force_nudge;
#	long_sleep_found($time); 


	
	log_registry("=============================================================");
	get_mo_attr($UCR_FDN);
	log_registry("=============================================================");
	my %UCR_attr = get_mo_attributes_CS(mo =>$UCR_FDN, attributes => "adjacentCell externalUtranCellFDDRef");
        if($base eq "CSCLI"){
        	my $flag = 1 if not $UCR_attr{externalUtranCellFDDRef};
        	log_registry("It seems Proxy ExternalUtranCellFDD mos are not getting created after UtranCellCreation...") if $flag;
        	return "0" if $flag;
        	my $master_mo = get_master_for_proxy($UCR_attr{externalUtranCellFDDRef});
        	log_registry("Master of Proxy mo is: $master_mo") if $master_mo;
        	$flag = 1 if ($master_mo !~ /$EUC/ and $EUC);
		$flag = 1 if ($master_mo !~ /$UtranCell/ and $UtranCell);
        	log_registry("It seems master for Proxies ExternalUtranCellFDD is differnet from $EUC...") if ($flag and $EUC);
		log_registry("It seems master for Proxies ExternalUtranCellFDD is differnet from $UtranCell..") if ($flag and $UtranCell);
        	return "0" if $flag;
		get_mo_attr($UCR_attr{externalUtranCellFDDRef});
		my $state = get_proxy($UCR_attr{externalUtranCellFDDRef});
		log_registry("It seems ExternalUtranCellFDD is consistent...") if ($state == 1);
		log_registry("Warning: ExternalUtranCellFDD does not seems to be consistent...") if ($state != 1);
		return ($UCR_FDN,$UCR_attr{externalUtranCellFDDRef}); }
	if($base eq "CLI"){
		my $flag = 1 if not $UCR_attr{adjacentCell};
		log_registry("It seems no master mo is created automatically after creation of UtranCellRelation...") if $flag;
		return "0" if $flag;
		log_registry("A new Master Mo created for proxy is: $UCR_attr{adjacentCell}");
		$flag = 1 if ($UCR_attr{adjacentCell} !~ /ExternalUtranCell/);	
		log_registry("It seems master for Proxy is not a ExternalUtranCell master mo..") if $flag;
		return "0" if $flag;
		my $state = get_master("$UCR_attr{adjacentCell}");
		$flag = 1 if ($state != 1);
		log_registry("Master Mo does not seems to consistent...") if $flag;
		return "0" if $flag;
		my $proxies = get_proxies_master($UCR_attr{adjacentCell});
		log_registry("It seems ExternalUtranCell is not master of given ExternalUtranCellFDD proxy..") if not $proxies;
		return "0" if not $proxies;
		$flag = 1 if ($proxies !~ /$EUCFDD/);	
		log_registry("Proxies of Master ExternalUtranCell is: \n $proxies");
		log_registry("It seems ExternalUtranCell is not master of given ExternalUtranCellFDD proxy..") if $flag;
		return "0" if $flag;
		my %EUC_attrs = get_mo_attributes_CS(mo =>$UCR_attr{adjacentCell}, attributes => "uarfcnUl lac rac"); 
		$flag = 1 if not ($EUC_attrs{lac} and $EUC_attrs{rac} and $EUC_attrs{uarfcnUl});
		log_registry("It seems value of lac,rac and uarfcnUl attribute is null for master ExternalUtranCell...") if $flag;
		return "0" if $flag;
		log_registry("attributes of master ExternalUtranCell $UCR_attr{adjacentCell} are: \n lac =>$EUC_attrs{lac} \n rac => $EUC_attrs{rac} \n uarfcnUl=> $EUC_attrs{uarfcnUl}");
		$flag=1 if($EUC_attrs{uarfcnUl} !~ /Undefined/ or $EUC_attrs{rac} !~ /Undefined/ or $EUC_attrs{lac} !~ /Undefined/);
		log_registry("It seems value of autocreated master ExternalUtranCell has been set to some vale that is not desirable...") if $flag;
		return "0" if $flag;
		return ($UCR_FDN,$UCR_attr{adjacentCell});	}
}

#############################################################################
#
# To create Cdma2000FreqBandRelation
#
#############################################################################
sub create_Cdma2000FreqBandRelation
{
        my %param = ( base=>"CSCLI",EUCFDD => "", EC2FB => "",C2FB =>"",@_);
	my $base = $param{base};
	my $EUCFDD = $param{EUCFDD};
	my $EC2FB = $param{EC2FB};
   	my $C2FB = $param{C2FB};
	my $attrs,$base_fdn;
	$base_fdn = "$EUCFDD".",Cdma2000FreqBandRelation=$mo_proxy_cms";
	$attrs = "adjacentFreqBand"." "."$EC2FB" if $EC2FB;
	$attrs = "cdma2000FreqBandRef"." "."$C2FB" if $C2FB;
	my $time = sleep_start_time();
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of Cdma2000FreqBandRelation.....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems Cdma2000FreqBandRelation has been created..");
   	my $nudge_state = nudge_cc_sybase($time);
   	log_registry("It seems CC has not nudged...") if not $nudge_state;
   	log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
	my $force_nudge;
   	$force_nudge = forceCC($C2FB) if (!($nudge_state) and $C2FB);
	$force_nudge = forceCC($EC2FB) if (!($nudge_state) and $EC2FB);
   	$time = $force_nudge if $force_nudge;
	long_sleep_found($time); 
        my $flag = 0;
        my %C2FBR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "cdma2000FreqBandRef adjacentFreqBand");
	get_mo_attr("$base_fdn");
	$flag = 1 if (!($C2FBR_attr{adjacentFreqBand}) or !($C2FBR_attr{cdma2000FreqBandRef}) or $C2FBR_attr{cdma2000FreqBandRef} !~ /Cdma2000FreqBand/ or $C2FBR_attr{adjacentFreqBand} !~ /ExternalCdma2000FreqBand/); 
	log_registry("It seems no proxy Cdma2000FreqBand is set for the Cdma2000FreqBandRelation or there is no master ExternalCdma2000FreqBand set for adjacentFreqBand attribute..") if $flag;
	return "0" if $flag;
	log_registry("Proxy Cdma2000FreqBand set for Cdma2000FreqBandRelation is: $C2FBR_attr{cdma2000FreqBandRef}");
	my %C2FB_attr = get_mo_attributes_CS(mo => $C2FBR_attr{cdma2000FreqBandRef}, attributes => "reservedBy");
	get_mo_attr("$C2FBR_attr{cdma2000FreqBandRef}","reservedBy");
	$flag = 1 if (!($C2FB_attr{reservedBy}) or $C2FB_attr{reservedBy} !~ /$base_fdn/);
	log_registry("It seems proxy Cdma2000FreqBand is not resered by Cdma2000FreqBandRelation ..") if $flag;
	return "0" if $flag;
	return($base_fdn,$C2FBR_attr{cdma2000FreqBandRef});
}

#############################################################################
#
# To create Cdma2000CellRelation
#
#############################################################################
sub create_Cdma2000CellRelation
{
        my %param = ( base=>"CSCLI",C2FBR => "", MEC2C => "",PEC2C =>"",@_);
        my $base = $param{base};
        my $C2FBR = $param{C2FBR};
        my $MEC2C = $param{MEC2C};
        my $PEC2C = $param{PEC2C};
        my $attrs,$base_fdn;
        $base_fdn = "$C2FBR".",Cdma2000CellRelation=$mo_proxy_cms";
        $attrs = "adjacentCell"." "."$MEC2C" if $MEC2C;
        $attrs = "externalCdma2000CellRef"." "."$PEC2C" if $PEC2C;
	my $time = sleep_start_time();
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of Cdma2000CellRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems Cdma2000CellRelation has been created..");
	long_sleep_found($time);
        my $flag = 0;
        my %C2CR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "externalCdma2000CellRef adjacentCell");
        get_mo_attr("$base_fdn");
        $flag = 1 if(!($C2CR_attr{adjacentCell}) or !($C2CR_attr{externalCdma2000CellRef}) or $C2CR_attr{externalCdma2000CellRef} !~ /ExternalCdma2000Cell/ or $C2CR_attr{adjacentCell} !~ /ExternalCdma2000Cell/);
        log_registry("It seems no proxy ExternalCdma2000Cell is set for the Cdma2000CellRelation or adjacentCell attribute is not set to a master ExternalUtranCell..") if $flag;
        return "0" if $flag;
        log_registry("Proxy ExternalCdma2000Cell set for Cdma2000CellRelation is: $C2CR_attr{externalCdma2000CellRef}");
        my %PEC2C_attr = get_mo_attributes_CS(mo => $C2CR_attr{externalCdma2000CellRef}, attributes => "reservedBy");
        get_mo_attr("$C2CR_attr{externalCdma2000CellRef}","reservedBy");
        $flag = 1 if (!($PEC2C_attr{reservedBy}) or $PEC2C_attr{reservedBy} !~ /$base_fdn/);
        log_registry("It seems proxy ExternalCdma2000Cell is not resered by Cdma2000CellRelation ..") if $flag;
        return "0" if $flag;
        return($base_fdn,$C2CR_attr{externalCdma2000CellRef});
}

#############################################################################
#
# To create Cdma2000FreqRelation
#
#############################################################################
sub create_Cdma2000FreqRelation
{
        my %param = ( base=>"CSCLI",C2FBR => "", EC2F => "",C2F => "",@_);
        my $base = $param{base};
        my $C2FBR = $param{C2FBR};
        my $C2F = $param{C2F};
    	my $EC2F = $param{EC2F};
        my $attrs,$base_fdn;
        $base_fdn = "$C2FBR".",Cdma2000FreqRelation=$mo_proxy_cms";
        $attrs = "cdma2000FreqRef"." "."$C2F" if $C2F;
	$attrs = "adjacentFreq"." "."$EC2F" if $EC2F;
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of Cdma2000FreqRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems Cdma2000FreqRelation has been created..");
	log_registry("wait for 2 mins to get system stabilized...");
	sleep 120;
        my $flag = 0;
        my %C2FR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreq cdma2000FreqRef");
	my $nudge = forceCC($base_fdn)if(!($C2FR_attr{adjacentFreq}) or $C2FR_attr{adjacentFreq} !~ /ExternalCdma2000Freq\=/);
	long_sleep_found($nudge) if(!($C2FR_attr{adjacentFreq}) or $C2FR_attr{adjacentFreq} !~ /ExternalCdma2000Freq\=/);
        %C2FR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreq cdma2000FreqRef") if(!($C2FR_attr{adjacentFreq}) or $C2FR_attr{adjacentFreq} !~ /ExternalCdma2000Freq\=/);
        get_mo_attr("$base_fdn");
	$flag = 1 if not ($C2FR_attr{cdma2000FreqRef} and $C2FR_attr{adjacentFreq});
	log_registry("It seems adjacentFreq or cdma2000FreqRef attributes of Cdma2000FreqRelation are not set ..") if $flag;
	return "0" if $flag;
	$flag = 1 if ($C2F and $C2FR_attr{cdma2000FreqRef} !~ /$C2F/);
	my %C2F_attr = get_mo_attributes_CS(mo => $C2FR_attr{cdma2000FreqRef}, attributes => "reservedBy");
	$flag = 1 if ($C2F_attr{reservedBy} !~ /$base_fdn/);	
	log_registry("It seems Cdma2000Freq Mo is not reserved by $base_fdn Cdma2000FreqRelation ") if $flag;
	return "0" if $flag;
	$flag = 1 if (!($C2FR_attr{adjacentFreq}) or $C2FR_attr{adjacentFreq} !~ /ExternalCdma2000Freq/);
	$flag = 1 if ($EC2F and $C2FR_attr{adjacentFreq} !~ /$EC2F/);
	log_registry("It seems adjacentFreq attribute of Cdma2000FreqRelation is not set to desired ExternalCdma2000Freq MO..") if $flag;
	return "0" if $flag;
	return($base_fdn,$C2FR_attr{cdma2000FreqRef}) if ($base eq "CSCLI");
	return($base_fdn,$C2FR_attr{adjacentFreq}) if ($base eq "CLI");
}

#############################################################################
#
# To create EUtranCellRelation
#
#############################################################################
sub create_EUtranCellRelation
{
        my %param = ( base=>"CSCLI",EUFR => "", EEUCXDD => "",@_);
        my $base = $param{base};
        my $EUFR = $param{EUFR};
        my $EEUCXDD = $param{EEUCXDD};
        my $attrs,$base_fdn;
        $base_fdn = "$EUFR".",EUtranCellRelation=$mo_proxy_cms";
        $attrs = "neighborCellRef"." "."$EEUCXDD";
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Warning => Problem in creation of EUtranCellRelation :\n $base_fdn") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems EUtranCellRelation has been created..");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $flag = 0;
	log_registry("=============================================================================");
        get_mo_attr("$base_fdn");
	log_registry("=============================================================================");
        my %EUCR_attrs = get_mo_attributes_CS(mo =>$base_fdn, attributes => "neighborCellRef adjacentCell");
        $flag = 1 if (!($EUCR_attrs{neighborCellRef}) or $EUCR_attrs{neighborCellRef} !~ /$EEUCXDD/ );
        log_registry("It seems EUtranCellRelation: $base_fdn is not pointing for given ExternalEUtranCellFDD/ExternalEUtranCellTDD ..") if $flag;
        return "0" if $flag;
	my %EEUCXDD_attrs = get_mo_attributes_CS(mo =>$EEUCXDD, attributes => "reservedBy");
	log_registry("=============================================================================");
	get_mo_attr("$EEUCXDD","reservedBy");
	log_registry("=============================================================================");
	$flag = 1 if (!($EEUCXDD_attrs{reservedBy}) or $EEUCXDD_attrs{reservedBy} !~ /$base_fdn/);
	log_registry("It seems proxy ExternalEUtranCellFDD/TDD $EEUCXDD does not have reservedBy relation with created EUtranCellRelation : $base_fdn") if $flag;
	return "0" if $flag;
        return($base_fdn);
}

#############################################################################
#
# To create GeranCellRelation 
#
#############################################################################
sub create_GeranCellRelation
{
        my %param = ( base=>"CSCLI",GFGR => "", MEGC => "",EGeC => "",@_);
        my $base = $param{base};
        my $GFGR = $param{GFGR};
        my $MEGC = $param{MEGC};
 	my $EGeC = $param{EGeC};
        my $attrs,$base_fdn;
	my $rand = int(rand(40));
        $base_fdn = "$GFGR".",GeranCellRelation=$mo_proxy_cms";
	$base_fdn = "$base_fdn"."$rand";
        $attrs = "adjacentCell"." "."$MEGC" if $MEGC;
  	$attrs = "externalGeranCellRef"." "."$EGeC" if $EGeC;
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of GeranCellRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems GeranCellRelation has been created..");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $flag = 0;
        my %GCR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentCell externalGeranCellRef");

# eeitjn: 30/4/2013 we are nudging a relation mo which is not correct.

#        my $nudge = forceCC($base_fdn)if(!($GCR_attr{adjacentCell}) or $GCR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
#        long_sleep_found($nudge) if(!($GCR_attr{adjacentCell}) or $GCR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
#        %GCR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentCell externalGeranCellRef") if(!($GCR_attr{adjacentCell}) or $GCR_attr{adjacentCell} !~ /ExternalGsmCell\=/);

        get_mo_attr("$base_fdn");
        $flag = 1 if not ($GCR_attr{adjacentCell} and $GCR_attr{externalGeranCellRef});
        log_registry("It seems adjacentCell or externalGeranCellRef attributes of GeranCellRelation are not set ..")if $flag;
        return "0" if $flag;
        my %EGeC_attr = get_mo_attributes_CS(mo => $GCR_attr{externalGeranCellRef}, attributes => "reservedBy");
        $flag = 1 if ($EGeC_attr{reservedBy} !~ /$base_fdn/);
        log_registry("It seems ExternalGeranCell Mo is not reserved by $base_fdn GeranCellRelation") if $flag;
        return "0" if $flag;
        $flag = 1 if (!($GCR_attr{adjacentCell}) or $GCR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
        $flag = 1 if ($MEGC and $GCR_attr{adjacentCell} !~ /$MEGC/);
        log_registry("It seems adjacentCell attribute of GeranCellRelation is not set to desired ExternalGsmCell MO..  ") if $flag;
	my $flag2 = 0;
	$flag2 = 1 if ($EGeC and $GCR_attr{externalGeranCellRef} !~ /$EGeC/);
	log_registry("It seems externalGeranCellRef attribute of GeranCellRelation is not set to desired ExternalGeranCell mo..") if $flag2;
        return "0" if ($flag or $flag2);
        return($base_fdn,$GCR_attr{externalGeranCellRef}) if ($base eq "CSCLI");
	return($base_fdn,$GCR_attr{adjacentCell}) if ($base eq "CLI");
}

#############################################################################
#
# To create GeranFreqGroupRelation
#
#############################################################################
sub create_GeranFreqGroupRelation
{
        my %param = ( base=>"CSCLI",EUCXDD => "", EGFG => "",@_);
        my $base = $param{base};
        my $EUCXDD = $param{EUCXDD};
        my $EGFG = $param{EGFG};
        my $attrs,$base_fdn;
        $base_fdn = "$EUCXDD".",GeranFreqGroupRelation=$mo_proxy_cms";
        $attrs = "adjacentFreqGroup"." "."$EGFG" if $EGFG;
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of GeranFreqGroupRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems GeranFreqGroupRelation has been created..");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $flag = 0;
        my %GFGR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreqGroup geranFreqGroupRef");
        my $nudge = forceCC($base_fdn)if(!($GFGR_attr{adjacentFreqGroup}) or $GFGR_attr{adjacentFreqGroup} !~ /ExternalGsmFreqGroup\=/);
        long_sleep_found($nudge) if(!($GFGR_attr{adjacentFreqGroup}) or $GFGR_attr{adjacentFreqGroup} !~ /ExternalGsmFreqGroup\=/);
	%GFGR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreqGroup geranFreqGroupRef");
        get_mo_attr("$base_fdn");
        $flag = 1 if not ($GFGR_attr{adjacentFreqGroup} and $GFGR_attr{geranFreqGroupRef});
        log_registry("It seems adjacentFreqGroup or geranFreqGroupRef attributes of GeranFreqGroupRelation are not set ..")if $flag;
        return "0" if $flag;
        my %GeFG_attr = get_mo_attributes_CS(mo => $GFGR_attr{geranFreqGroupRef}, attributes => "reservedBy");
        $flag = 1 if ($GeFG_attr{reservedBy} !~ /$base_fdn/);
        log_registry("It seems GeranFreqGroup Mo is not reserved by $base_fdn GeranFreqGroupRelation") if $flag;
        return "0" if $flag;
        $flag = 1 if (!($GFGR_attr{adjacentFreqGroup}) or $GFGR_attr{adjacentFreqGroup} !~ /ExternalGsmFreqGroup\=/);
        $flag = 1 if ($EGFG and $GFGR_attr{adjacentFreqGroup} !~ /$EGFG/);
        log_registry("It seems adjacentFreqGroup attribute of GeranFreqGroupRelation is not set to desired ExternalGsmFreqGroup MO..  ") if $flag;
        return "0" if $flag;
        return($base_fdn,$GFGR_attr{geranFreqGroupRef}) if ($base eq "CSCLI");
}

#############################################################################
#
# To create GsmRelation 
#
#############################################################################
sub create_GsmRelation
{
        my %param = ( base=>"CSCLI",UC => "", MEGC => "",PEGC => "",@_);
        my $base = $param{base};
        my $UC = $param{UC};
        my $PEGC= $param{PEGC};
	my $MEGC = $param{MEGC};
        my $attrs,$base_fdn;
        $base_fdn = "$UC".",GsmRelation=$mo_proxy_cms";
        $attrs = "adjacentCell"." "."$MEGC" if $MEGC;
	$attrs = "externalGsmCellRef"." "."$param{PEGC}" if $PEGC;
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of GsmRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems GsmRelation has been created..");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $flag = 0;
        my %GR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentCell externalGsmCellRef");
        my $nudge = forceCC($base_fdn)if(!($GR_attr{adjacentCell}) or $GR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
        long_sleep_found($nudge) if(!($GR_attr{adjacentCell}) or $GR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
        %GR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentCell externalGsmCellRef");
        get_mo_attr("$base_fdn");
        $flag = 1 if not ($GR_attr{adjacentCell} and $GR_attr{externalGsmCellRef});
        log_registry("It seems externalGsmCellRef or adjacentCell attributes of GsmRelation are not set ..")if $flag;
        return "0" if $flag;
        my %PEGC_attr = get_mo_attributes_CS(mo => $GR_attr{externalGsmCellRef}, attributes => "reservedBy");
        $flag = 1 if ($PEGC_attr{reservedBy} !~ /$base_fdn/);
        log_registry("It seems proxy ExternalGsmCell Mo is not reserved by $base_fdn GsmRelation") if $flag;
        return "0" if $flag;
        $flag = 1 if (!($GR_attr{adjacentCell}) or $GR_attr{adjacentCell} !~ /ExternalGsmCell\=/);
        $flag = 1 if ($MEGC and $GR_attr{adjacentCell} !~ /$MEGC/);
        log_registry("It seems adjacentCell attribute of GsmRelation is not set to desired master ExternalGsmCell MO..  ") if $flag;
        $flag = 1 if ($PEGC and $GR_attr{externalGsmCellRef} !~ /$PEGC/);
        log_registry("It seems externalGsmCellRef attribute of GsmRelation is not set to desired proxy ExternalGsmCell MO..  ") if $flag;
        return "0" if $flag;
        return($base_fdn,$GR_attr{externalGsmCellRef}) if ($base eq "CSCLI");
	return($base_fdn,$GR_attr{adjacentCell}) if ($base eq "CLI");
}


#############################################################################
#
# To create EUtranFreqRelation
#
#############################################################################
sub create_EUtranFreqRelation
{
        my %param = ( base=>"CSCLI", EUCXDD => "", PEUF => "", MEUF =>"",@_);
        my $base = $param{base};
        my $EUCXDD = $param{EUCXDD};
        my $PEUF = $param{PEUF};
	my $MEUF = $param{MEUF};
        my $attrs,$base_fdn;
        $base_fdn = "$EUCXDD".",EUtranFreqRelation=$mo_proxy_cms";
        $attrs = "eutranFrequencyRef"." "."$PEUF" if $PEUF;
	$attrs = "adjacentFreq"." "."$MEUF" if $MEUF;
        my $result = create_mo_CLI(mo => $base_fdn, base => $base, attributes => $attrs);
        log_registry("Problem in creation of EUtranFreqRelation .....") if ($result ne OK);
        return "0" if ($result ne OK);
        log_registry("It seems EUtranFreqRelation has been created..");
        log_registry("wait for 2 mins to get system stabilized...");
        sleep 120;
        my $flag = 0;
        my %EUFR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreq eutranFrequencyRef");
        my $nudge = forceCC($base_fdn)if(!($EUFR_attr{adjacentFreq}) or $EUFR_attr{adjacentFreq} !~ /EUtranFrequency\=/);
        long_sleep_found($nudge) if(!($EUFR_attr{adjacentFreq}) or $EUFR_attr{adjacentFreq} !~ /EUtranFrequency\=/);
        %EUFR_attr = get_mo_attributes_CS(mo =>$base_fdn, attributes => "adjacentFreq eutranFrequencyRef");
	log_registry("============================================================================");
        get_mo_attr("$base_fdn");
	log_registry("============================================================================");
        $flag = 1 if not ($EUFR_attr{adjacentFreq} and $EUFR_attr{eutranFrequencyRef});
        log_registry("It seems adjacentFreq or eutranFrequencyRef attributes of EUtranFreqRelation are not set ..")if $flag;
        return "0" if $flag;
        my %PEUF_attr = get_mo_attributes_CS(mo => $EUFR_attr{eutranFrequencyRef}, attributes => "reservedBy");
        $flag = 1 if ($PEUF_attr{reservedBy} !~ /$base_fdn/);
        log_registry("It seems proxy EUtranFrequency Mo is not reserved by $base_fdn EUtranFreqRelation") if $flag;
        return "0" if $flag;
        $flag = 1 if (!($EUFR_attr{adjacentFreq}) or $EUFR_attr{adjacentFreq} !~ /EUtranFrequency\=/);
        $flag = 1 if ($MEUF and $EUFR_attr{adjacentFreq} !~ /$MEUF/);
        log_registry("It seems adjacentFreq attribute of EUtranFreqRelation is not set to desired EUtranFrequency MO..  ") if $flag;
        return "0" if $flag;
	$flag = 1 if ($PEUF and $EUFR_attr{eutranFrequencyRef} !~ /$PEUF/);
	log_registry("It seems eutranFrequencyRef attribute of EUtranFreqRelation is not set to desired proxy EUtranFrequency mo..") if $flag;
	return "0" if $flag;
        return($base_fdn,$EUFR_attr{eutranFrequencyRef}) if ($base eq "CSCLI");
	return($base_fdn,$EUFR_attr{adjacentFreq}) if ($base eq "CLI");
}




sub create_EutranFreqRelation_noWait  # Done for new nead TC's no wait around 
{

        my %param = (UC => "",EEF => "",base=>"CSCLI",X_EFR => "",EF => "", number => "", @_);
        my $UtranCell = $param{UC};
        my $EEF_fdn = $param{EEF};
        my $base = $param{base};
        my $exist_EFR = $param{X_EFR};
        my $EF_fdn = $param{EF};
        my $relNumber = $param{number};

        my $EFR_fdn = "$UtranCell".","."EutranFreqRelation=CMSAUTOPROXY_$relNumber";
        my $EFR_attr;
        $EFR_attr = "externalEutranFreq"." "."$EEF_fdn" if $EEF_fdn;
        $EFR_attr = "eutranFrequencyRef"." "."$EF_fdn" if $EF_fdn;

        my $result = create_mo_CLI(mo => $EFR_fdn, base => $base, attributes => $EFR_attr);
        log_registry("Problem in creation of of EutranFreqRelation MO.....") if ($result ne OK);
        return "0" if ($result ne OK);
        sleep 12;
        my $status = does_mo_exist_CLI( base => "$base", mo => $EFR_fdn);
        log_registry("Specified MO => $EFR_fdn exist ...") if ($status eq "YES");
        log_registry("Specified MO => $EFR_fdn does not exist .......") if ($status ne "YES");
        return "0" if ($status ne "YES");
        get_mo_attr($EFR_fdn);
        my %attrs = get_mo_attributes_CS( mo => $EFR_fdn, attributes => "eutranFrequencyRef externalEutranFreq");
        log_registry("Attribute eutranFrequencyRef value for EutranFreqRelation is : \n $attrs{eutranFrequencyRef}");
        my $flag = 0;
        $flag = 1 if(!($attrs{eutranFrequencyRef}) or $attrs{eutranFrequencyRef} !~ /EutranFrequency/);
        log_registry("It seems eutranFrequencyRef attribute is not set for a proxy EutranFrequency MO...") if $flag;
        return "0" if $flag;
#        my $master_mo = get_master_for_proxy($attrs{eutranFrequencyRef});
        
	$EEF_fdn = $attrs{externalEutranFreq} if $EF_fdn;

#        log_registry("Checking reserveBy attribute of $attrs{eutranFrequencyRef} .....");

        my $match;
        $match = is_resby("$attrs{eutranFrequencyRef}",$EFR_fdn);
        log_registry("It seems reserveBy of proxy EutranFrequency has EutranFreqRelation MO $EFR_fdn....") if $match;
        log_registry("It seems reserveBy of proxy EutranFrequency do not have EutranFreqRelation MO $EFR_fdn....") if not $match;
        return "0" if not $match;
        if($exist_EFR) {
                my $match1 = is_resby("$attrs{eutranFrequencyRef}",$exist_EFR);
                log_registry("It seems reserveBy of proxy EutranFrequency has EutranFreqRelation MO $exist_EFR....") if $match1;
                log_registry("It seems reserveBy of proxy EutranFrequency do not have EutranFreqRelation MO $exist_EFR ....") if not $match1;
                return "0" if not $match1; }
        return ($EFR_fdn,$attrs{eutranFrequencyRef});

}


sub master_for_proxy_handle
{
	my $attr_1 = shift;	my $attr_2 = shift;	my $attr_3 = shift;	my $attr_4 = shift;	my $attr_5 = shift;
	log_registry("Deleting Existing master mo: $attr_2");
	my $status = delete_mo_CS(mo => $attr_2);
	log_registry("Problem in deletion of master mo $attr_2") if $status;
	my $result = does_mo_exist_CS( mo =>$attr_2 );
	log_registry("After delete attempt of master mo it seems mo still exist") if ($result == $result_code_CS{MO_ALREADY_EXISTS});
	return "0" if ($result == $result_code_CS{MO_ALREADY_EXISTS});
	log_registry("Retrying to create master mo $attr_2 ");
	$status = mo_create_decision($attr_1,$attr_2,$attr_3,$attr_4,$attr_5);
	return "$status" if ($status and $status ne "KO");
	return "0";
}

sub get_attrs_ExternalENodeBFunction
{
	my $ERBS = shift;
        my %param = get_mo_attributes_CS(mo => $ERBS, attributes => "eNodeBPlmnId eNBId");
        my $value = $param{eNBId};
        my $eNBId = $value + 20 if ($value < 40);
        $eNBId = $value - 20 if ($value < 70 and $value > 40);
        $eNBId = $value - 40 if ($value > 70);
        my $oth_attrs = $param{eNodeBPlmnId};
        $oth_attrs =~ s/\n+//g; $oth_attrs =~ s/\;/\+/g;
        $oth_attrs = "eNodeBPlmnId $oth_attrs eNBId $eNBId";
	return "$oth_attrs";
}

1;
