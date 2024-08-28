#!/usr/bin/perl

#################################################
#
# Get Master Info
#
#################################################

sub get_master
{
   my $param = $_[0] ;
   my $info_master = `$smtool -action cms_snad_reg getMaster MoFDN $param`;
   log_registry("Get_master -> $param");
   log_registry("Get_master -> $info_master");
   $info_master =~ s/Detail:.*//;
   if ($info_master =~ /TRAFFICAL ID CHANGED/)
   {
      return 3; #Master Mo attributes has been modified
   }
   elsif (($info_master =~ /INCONSISTENT/i) or ($info_master =~ /IN_CONSISTENT/i))
   {
      return 2; #Master Mo Exist but InConsistent
   }
   elsif ($info_master =~ /CONSISTENT/i)
   {
      return 1; #Master Mo Exist and consisitent
   }
   else
   {
      return 0; #Master Mo does not Exists 
   }
}

##############################################
#
# To create Master MO 
#
##############################################

sub create_master
{
  my ($fdn_base, $attr,$plan) = ($_[0], $_[1],$_[2]);
  log_registry("Create_master -> $fdn_base $attr");
  my $cm_master = `$cstest $plan -s $region_CS cm $fdn_base -attr $attr`;
 
  if ($cm_master)
  {
      log_registry("Problem in Creation of MasterMo $fdn_base --> $cm_master"); 
      print "Problem in creation of MatstreMO $fdn_base,consult log for details...\n";
      return $cm_master;
  }
  else
  {
      log_registry("Master Mo Created -> $fdn_base");
      print "Master Mo created $fdn_base \n";
      return;
  }
}

##############################################
#
# To set attributes of Master MO
#
##############################################

sub set_attr_master
{
  my ($fdn_base, $attr,$plan) = ($_[0], $_[1],$_[2]);
  log_registry("Set attributes of master Mo -> $fdn_base $attr");
  my $set_master = `$cstest $plan -s $region_CS sa $fdn_base $attr`;

  if($set_master)
  {
	log_registry("Problem in modifying attributes of MasterMO $fdn_base --> $set_master");
	print "Problem in modifying attributes of MasterMO $fdn_base,consult log for details... \n";
	return $set_master;
  }
  else
  {
	log_registry("Master Mo $fdn_base attributes has been modified --> $attr");
	print "Master Mo $fdn_base attributes has been modified \n";
	return;
  }
}

##############################################
# 
# To get the Proxy Mo exist
#
##############################################

sub get_proxy
{

  my $param = $_[0];
  my $nolog = $_[1];
  log_registry("Get_Proxy -> $param") if not $nolog;
  my $info_proxy = `$smtool -action cms_snad_reg getProxy MoFDN $param`; 
  log_registry("Get_Proxy -> $info_proxy") if not $nolog;
  $info_proxy =~ s/Detail:.*//;
  if ($info_proxy =~ /NODE_?UNSYNCHRONIZED/) 
  {
     return 5; #Node is not synched
  }
  elsif (($info_proxy =~ /INCONSISTENT/i)  or ($info_proxy =~ /IN_CONSISTENT/i) or ($info_proxy =~ /TRANSIENT_I?N?CONSISTENT/i))
  {
     return 2; #Proxy Mo Exist but InConsistent
  }
  elsif ($info_proxy =~ /CONSISTENT/i)
  {
     return 1; #Proxy Mo Exist and consisitent
  }
  elsif ($info_proxy =~ /MissingMaster/)
  {
     return 4; #Proxy Mo Exist but no master for that one
  }
  else
  {
     return 0; #Proxy Mo does not Exists
  }
#return 3 has been deleted because of not using by any TC for TRAFFICAL ID CHANGED
}

##############################################
#
# To get the Proxies linked to Master Mo 
#
##############################################

sub get_proxies_master
{
  my $param = $_[0];
  log_registry("getProxiesForMaster => $param");
  my $info_proxy = `$smtool -action cms_snad_reg getProxiesForMaster MoFDN $param 2>&1`;
  log_registry("GetProxiesForMaster result is: \n $info_proxy") if ($info_proxy =~ /Exception/);
  log_registry("GetProxiesForMaster => No Proxies Found") if not $info_proxy;
  return "0" if not $info_proxy;
  return "0" if ($info_proxy =~ /Exception/);
  return "$info_proxy";
}

##############################################
#
# To get the Master for the proxy
#
##############################################

sub get_master_for_proxy
{
    my $param = $_[0];
    my $nolog = $_[1];
    log_registry("getMasterForProxy => $param") if not $nolog;
    my $info_master = `$smtool -action cms_snad_reg getMasterForProxy MoFDN $param 2>&1`;
    $info_master =~ s/[\[\]]//g;
    log_registry("getMasterForProxy result is: \n $info_master") if ($info_master =~ /Exception/ and !($nolog));
    log_registry("No MasterFound for the Proxy") if (!($info_master) and !($nolog)) ;
    return "0" if not $info_master;
    return "0" if ($info_master =~ /Exception/);
    return "$info_master";
}

##############################################
#
# To delete Master MO
#
##############################################

sub delete_master
{
  my ($fdn_base, $attr,$plan) = ($_[0], $_[1],$_[2]);
  log_registry("Delete Master -> $fdn_base");
  my $dm_master = `$cstest $plan -s $region_CS dm $fdn_base`;
 
  if ($dm_master)
  {
     log_registry("Problem in deletion of MasterMo $fdn_base --> $dm_master");
     print "Problem in deletion of MatstreMO $fdn_base,consult log for details...\n";
     return $dm_master;
  }
  else
  {
     log_registry("Master Mo deleted -> $fdn_base");
     print "Master Mo deleted $fdn_base \n";
     return;
  }

}
 
################################################################
#
#  Sybase database checking for long sleep
#
################################################################

sub wait_for_long_sleep_sybase
{
  my $time = $_[0];

  log_registry("checking for long sleep in database after -> $time");
  my $isql_out=`$isql_cmd -Usa -Psybase11 -Dlvlogdb -w2240 -s#<< EOF
select convert(char(19),time_stamp,23),additional_info from Logs where compare(convert(char(19),time_stamp,23),"$time") > 0 and additional_info like 'Consistency Check going for long sleep 3600sec'
go
EOF`;

  if($isql_out =~ /Consistency Check going for long sleep 3600sec/)
  {
     return $isql_out;
  }
  else
  {
     return; 
  }
}

################################################################
#
#  Sybase database checking for nudge CC 
#
################################################################

sub nudge_cc_sybase
{
  my $time = $_[0];

  log_registry("checking for Consistency Checker has nudged in database after -> $time");
  my $isql_out=`$isql_cmd -Usa -Psybase11 -Dlvlogdb -w2240 -s#<< EOF
select convert(char(19),time_stamp,23),additional_info from Logs where compare(convert(char(19),time_stamp,23),"$time") > 0 and additional_info like 'SNAD Consistency Checker nudged while asleep'
go
EOF`;

  if($isql_out =~ /SNAD Consistency Checker nudged while asleep/)
  {
     return $isql_out;
  }
  else
  {
     log_registry("No CC nudge yet...");
     return;
  }
}

################################################################
#
#  Sybase database checking for event logs
#
################################################################

sub log_check_sybase
{
  my $time = $_[0];

  log_registry("checking for ERROR in log database after -> $time");

my $isql_out=`$isql_cmd -Usa -Psybase11 -Dlvlogdb -w2240 -s#<< EOF
select time_stamp,application_name,additional_info from Logs where compare(convert(char(19),time_stamp,23),"$time") > 0
go
EOF`;
#  my $isql_out=`$isql_cmd -Usa -Psybase11 -Dlvlogdb -w2240 -s#<< EOF
#select time_stamp,additional_info from Logs where time_stamp > '$time' and log_type = 1 and application_name like 'cms%'
#go
#EOF`;

  if($isql_out =~ /0 rows affected/)
  {
     return;
  }
  else
  {
     return $isql_out;
  }

}

########################################################
#
# Plan creation and pre checks
#
########################################################

sub create_plan_area
{
  my $plan_name = $_[0];

  my $plan_create = `$cstest -s $region_CS cp $plan_name`;

  if($plan_create)
  {
    log_registry("Unable to create Plan -> <$plan_name>");
    log_registry("Unable to create Plan -> $plan_create");
    return;
  }
  else
  {
    log_registry("Plan <$plan_name> created");
    my $plan = "-p $plan_name";
    return $plan;
  }
}

sub plan_area_exist
{
  my $plan_name = $_[0];

  my $plan_exist = `$cstest -s $region_CS lp`;

  if($plan_exist =~ /$plan_name/)
  {
     log_registry("Plan <$plan_name> exist");
     return 1;
  }
  else
  {
    log_registry("Plan <$plan_name> does not exist");
    return 0;
  }
}

sub activate_plan_area
{
   my $plan_name = $_[0];

   my $plan_activate = `$cstest -s $region_CS -p $plan_name update`;

   if($plan_activate)
   {
      log_registry("Plan <$plan_name> is not activated");
      log_registry("Plan activate problem -> $plan_activate");
      return ERROR;
   }
   else
   {
      log_registry("Plan <$plan_name> activated successfully");
      return;
   } 
}

sub delete_plan_area
{
   my $plan_name = $_[0];

   my $plan_delete = `$cstest -s $region_CS dp $plan_name`;

   if($plan_delete)
   {
	log_registry("Unable to delete Plan <$plan_name>");
	log_registry("Plan delete problem -> $plan_delete");
	return ERROR;
   }
   else
   {
	log_registry("Plan <$plan_name> deleted successfully");
	return;
   }
}

######################################################
#
# To list out attributes of a MO
#
######################################################

sub get_mo_attr
{
  my $mo_fdn = $_[0];
  my $attrs = $_[1];
  my $attributes;
  my $count_attr;
  if($attrs)
  {
  	($attributes,$count_attr) = attrs_chk($attrs) if( $attrs !~ /^\-o/); 
	$attributes = $attrs if ($attrs =~ /^\-o/);
	$attributes =~ s/\-o//g if ($attrs =~ /^\-o/);
	$count_attr = 1 if ($attrs =~ /^\-o/);
  }
  my $attrs_total = ($attributes) ? "-an $attributes" : "-a";
 
  my $result = `$cstest -s $region_CS lm $mo_fdn -l 0 $attrs_total`;

  log_registry("$result");

  $count_attr = 0 if not $count_attr;

  if(($count_attr == 1 and $attrs_total =~ /userLabel/) or $attrs_total =~ /aseDlAdm/ or $attrs_total =~ /physicalLayerSubCellId/)
  {
	return 1;
  }
  else
  {
	return $count_attr;
  }
}

##############################################################
#
# To get one UtranCell created by master.pl 
#
##############################################################

sub get_UtranCell
{
   my $UtranCell = $_[0];

   my $result = `$cstest -s $segment_CS lt UtranCell | grep $UtranCell`; 
      $result =~ s/^\s+//; # To remove leading space
      
   if($result)
   {
      my @UtranCellFDN = split /\n/,$result;
      my $count_FDN = scalar @UtranCellFDN;
      if($count_FDN==1)
      {
 	 return (1,@UtranCellFDN);
      }
      else
      {
 	 log_registry("<$count_FDN> UtranCell Exist for $UtranCell");
    	 foreach(@UtranCellFDN)
  	 {
		log_registry("UtranCell FDN => $_");
	 }
	 return ($count_FDN,@UtranCellFDN);
      }
   }
   else
   {
      return;	   	
   }
}

##############################################################
#
# To get one WcdmaCarrier 
#
##############################################################
sub get_WcdmaCarrier
{
   my $WcdmaCarrier = $_[0];

   my $result = `$cstest -s $segment_CS lt WcdmaCarrier | grep -v IurLink`;
      $result =~ s/^\s+//; # To remove leading space
   my @WcdmaCarrierFDN = split /\n/,$result;
   my @WcdmaCarrierFDN_CMS = ();
   foreach(@WcdmaCarrierFDN)
   {
	if($_ =~ /$WcdmaCarrier/)
	{
		push(@WcdmaCarrierFDN_CMS,$_); 
	}
   }
   my $count_FDN = scalar @WcdmaCarrierFDN_CMS;
   if($count_FDN)
   {
      if($count_FDN==1)
      {
         return (1,@WcdmaCarrierFDN_CMS);
      }
      else
      {
         log_registry("<$count_FDN> WcdmaCarrier Exist for $WcdmaCarrier");
         foreach(@WcdmaCarrierFDN_CMS)
         {
                log_registry("WcdmaCarrier FDN => $_");
         }
         return ($count_FDN,@WcdmaCarrierFDN_CMS);
      }
   }
   else
   {
      return;
   }
}

##############################################################
#
# To get mo created by CMSAUTO by using type and name of MO
# eeitjn: added 3rd search to help in getting tdd or fdd cells for 4.4.1.2.45
#
##############################################################

sub get_CMS_mo
{
   my $typeMO = $_[0];
   my $nameMO = $_[1];
   my $result; 
   
 
   if($nameMO) {
   	$result = `$cstest -s $segment_CS lt $typeMO | grep $nameMO`; }
   else {
	$result = `$cstest -s $segment_CS lt $typeMO`; }
   $result =~ s/^\s+//; # To remove leading space

   if($result)
   {
      my @MOFDN = split /\n/,$result;
      my $count_FDN = scalar @MOFDN;
      if($count_FDN==1) {
         return (1,@MOFDN); }
      else {
	 log_registry("$typeMO Total Count is : $count_FDN") if (!($nameMO) or $nameMO !~ /CMSAUTO/);
 	 log_registry("$typeMO Total Count matching $nameMO is : $count_FDN") if ($nameMO and $nameMO =~ /CMSAUTO/);
         return ($count_FDN,@MOFDN); }
   }
   else
   {
      return;
   }
}


########################################################################
#
# Find out new lac values which does not exist yet
# number of new lac is return by function according to demanded
# e.g. PICK_NEW_LAS(2) => will return 2 unique lac values 
#
########################################################################

sub PICK_NEW_LAS
{
  my $LA_count = $_[0];
  log_registry("Picking $LA_count new LAs which are non Existing Yet...");
  my $list_LA = `$cstest -s $segment_CS lt LocationArea`;
  my @a = split("\,",$list_LA);
  my @temp_LA = ();
  my $k;
  foreach $k (@a)
  {
    if($k =~ /LocationArea=/)
    {
        $k =~ s/.[a-zA-Z]+.\=//g;
        $k =~ s/[a-zA-Z]+//g;
	$k =~ s/\s*\n*\_*//g;
        push(@temp_LA,$k);
    }
  }
  my %unique = map { $_ => 1 } @temp_LA;
  my @result = keys %unique;
  my @LA =();
  my $count = scalar @LA;
  while($count != $LA_count)
  {
   	my $lac = int(rand(9000));
	if (!(grep {$_ == $lac} @result))
	{
          	 push(@LA,$lac);
        	 $count++;
	}
  }
  log_registry("Selected LAs are: @LA");
  return @LA;
}

#################################################
#
# Pick a MO of a NE based on type 
#
#################################################
sub pick_a_mo
{
  my $ne = $_[0];
  my $type = $_[1];
  log_registry("Selecting MO for NE => $ne \n MO type => $type");
  my  $result = `$cstest -s $segment_CS lm $ne -l 1 -f '\$type_name==$type'`;
  if($result)
  {
  	my @mos = split("\n",$result);
  	my $count = scalar @mos;
	my $pick = "$mos[int(rand($count))]";
#	$pick = "$mos[int(rand($count))]" if ($pick =~ /\,UtranNetwork\=77$/); eeitjn: updated to stop it picking =6 as this gave Plmn instead of ExternalUtranPlmn!!!!
	
	

	$pick = "$mos[int(rand($count))]" if ($pick =~ /\,UtranNetwork\=77$/) || ($pick =~ /\,UtranNetwork\=6$/);

	if ($type =~ /UtranNetwork/ && $pick =~ /\,UtranNetwork\=6$/ )
		{ # still no good random number is not helping when only 2 utranNetwork
		foreach(@mos)
			{
			if ($_ =~ /\,UtranNetwork\=7$/)
				{
				log_registry("In last resort pick ... going for $_");
				$pick = $_;
				}
			}

		}


	my $mo_valid = mo_name_is_OK($pick, qr/SubNetwork=\S+/);
        if($mo_valid) {
		log_registry("Selected MO is: $pick");
		return $pick; }
	else {
  		log_registry("There is some issue with MO name of NE: $ne, so no MO has been selected..");
  		return; }
  }
  else
  {
	log_registry("There is no MO under NE : $ne of type <$type>");
	return;
  }
}

##############################################
#
# To Create Proxy MO using CLI utility
# To create MO on CS side use base -> CSCLI
# To Create MO on Node side use base -> CLI
#
##############################################

sub create_mo_CLI
{
  my %param = ( base => "CSCLI" , attributes => "0", @_ );
 
  if(!($param{mo}))
  {
        log_registry("MO name is not specified....");
        return 0;
  }

   my $mo_fdn = $param{mo};
   
# eeitjn: comment out to allow it to now create masters in subnetwork....
#  my $mo_fdn = mo_name_is_OK($param{mo}, qr/SubNetwork.*?MeContext=[^,\s]+/);
#  log_registry("Given Mo name is not valid $param{mo}") if not $mo_fdn;
#  return "0" if not $mo_fdn;

  my $base = $param{base};
  log_registry("Selected Base is not correct..., please use CSCLI or CLI as base") if not ($base eq "CSCLI" or $base eq "CLI");
  return "0" if not ($base eq "CSCLI" or $base eq "CLI");

  my $status = does_mo_exist_CLI( base => $base, mo => $mo_fdn);
  log_registry("Specified MO => $mo_fdn already exist, so can not create the same...") if ($status eq "YES");
  return "0" if ($status eq "YES");
  return "0" if not $status ;
  log_registry("MO => $mo_fdn is going to be created on Node side..., Selected Base is $base") if ($base eq "CLI");
  log_registry("MO => $mo_fdn is going to be created on CS side...,Selected Base is $base") if ($base eq "CSCLI");

  my $attributes = $param{attributes};
  $attributes = attributes_CLI($attributes) if $attributes; 
  log_registry("Attributes of MO would be: $attributes") if $attributes;
  log_registry("No attributes for the MO") if not $attributes;
  my $result = "";
  if($attributes)
  {
        log_registry("EEITJN $cli_tool $base cm:$mo_fdn:$attributes " );

  	$result = `$cli_tool $base "cm:$mo_fdn:$attributes"  2>&1`;
  }
  else
  {
        log_registry("EEITJN in the one without attributes" );

  
  	$result = `$cli_tool $base "cm:$mo_fdn" 2>&1` ;
  }
  if($result =~ /Exception/ or $result =~ /Connection refused/)
  {
	log_registry("Problem in creation of MO: $mo_fdn \n $result");
	return 0;
  }
  return OK;
}

##############################################
#
# To check MO exist or not using CLI Utility
#
##############################################

sub does_mo_exist_CLI
{
  my %param = ( base => "CSCLI" , @_ );

  if(!($param{mo})) {
        log_registry(" MO name is not specified.... ");
        return "NO"; }

  my $mo_fdn = mo_name_is_OK($param{mo}, qr/SubNetwork.*?MeContext=[^,\s]+/);
  log_registry("Given Mo name is not valid $param{mo}") if not $mo_fdn;
  return "NO" if not $mo_fdn;

  my $base = $param{base};
  log_registry("MO => $mo_fdn is getting checked on CS side..., Selected Base is $base") if ($base eq "CLI");
  log_registry("MO => $mo_fdn is getting checked on CS side...,Selected Base is $base") if ($base eq "CSCLI");
  log_registry("Selected Base is not correct..., please use CSCLI or CLI as base")if not($base eq "CSCLI" or $base eq "CLI");
  return "NO" if not ($base eq "CSCLI" or $base eq "CLI");

#Commented out because CLI utility use print attribute feature to check mo existence and sometime it cause problem
#  my $result = `$cli_tool $base "pm:$mo_fdn" 2>&1`;
#  return "0" if ($result =~ /Connection refused/);
#  if($result =~ /Exception/) {
#	log_registry("MO => $mo_fdn : NOT EXIST");
#	return "NO"; }
  if($base eq "CSCLI") {
  	my $result = does_mo_exist_CS( mo =>$mo_fdn ); 
	log_registry("MO => $mo_fdn : NOT EXIST") if ($result == $result_code_CS{MO_DOESNT_EXIST});	
	return "NO" if ($result == $result_code_CS{MO_DOESNT_EXIST}); 
  	log_registry("MO => $mo_fdn : EXIST") if ($result == $result_code_CS{MO_ALREADY_EXISTS});
	return "YES" if ($result == $result_code_CS{MO_ALREADY_EXISTS});}
  if($base eq "CLI") {
  	my $result = does_mo_exist_CS( mo =>$mo_fdn ); 
	log_registry("MO => $mo_fdn : NOT EXIST") if ($result == $result_code_CS{MO_DOESNT_EXIST}); #Mo not exist if return code by NE is 4
	return "NO" if ($result == $result_code_CS{MO_DOESNT_EXIST}); 
  	log_registry("MO => $mo_fdn : EXIST") if ($result == $result_code_CS{MO_ALREADY_EXISTS}); #Mo exist will return 3
  	return "YES" if ($result == $result_code_CS{MO_ALREADY_EXISTS});}
   log_registry("It seems issue in checking existence of mo in snad : $mo_fdn");
   # EEITJN updated so both CLI and CSCLI use same, does_mo_exist_NE has problems with ipv6 Addresses...
   return "NO";
}

##############################################
#
# To prepare attribute format for CLI tool usage
#
##############################################

sub attributes_CLI
{
  my $attrs = shift;
  if($attrs)
  {
  	my @temp = split(" ",$attrs);
  	my $len = scalar(@temp);
  	my %hash =();
  	my @cli_attrs = ();
	for(my $i = 0; $i < $len ; $i=($i + 2) )
	{
		$hash{ $temp[$i] } = $temp[$i+1]; 
	}
	for my $key ( keys %hash ) 
	{
        	my $value = $hash{$key};
		push (@cli_attrs, "$key"."="."$value");
		
    	}
        $attrs = join("|",@cli_attrs); 
  }
  return $attrs; 
}

##############################################
#
# To Set Proxy MO using CLI utility
# To Set MO on CS side use base -> CSCLI
# To Set MO on Node side use base -> CLI
#
##############################################

sub set_attributes_mo_CLI
{
  my %param = ( base => "CSCLI" , attributes => "", @_ );

  if(!($param{mo}))
  {
        log_registry(" MO name is not specified.... ");
        return 0;
  }

  my $mo_fdn = mo_name_is_OK($param{mo}, qr/SubNetwork.*?MeContext=[^,\s]+/);
  log_registry("Given Mo name is not valid $param{mo}") if not $mo_fdn;
  return "0" if not $mo_fdn;

  my $base = $param{base};
  log_registry("Selected Base is not correct..., please use CSCLI or CLI as base") if not ($base eq "CSCLI" or $base eq "CLI");
  return "0" if not ($base eq "CSCLI" or $base eq "CLI");

  my $status = does_mo_exist_CLI( base => $base, mo => $mo_fdn);
  log_registry("Specified MO => $mo_fdn Exist") if ($status eq "YES");
  log_registry("Specified MO => $mo_fdn does not exist, so can not set attributes for a non-existing MO...") if ($status eq "NO");
  return "0" if ($status eq "NO");
  return "0" if not $status ;
  log_registry("Attributes of MO => $mo_fdn is going to be set on Node side..., Selected Base is $base") if ($base eq "CLI");
  log_registry("Attributes of MO => $mo_fdn is going to be set on CS side...,Selected Base is $base") if ($base eq "CSCLI");

  my $attributes = $param{attributes};
  $attributes = attributes_CLI($attributes) if $attributes;
  log_registry("New Attributes of MO would be: $attributes") if $attributes;
  log_registry("No attributes for the MO") if not $attributes;
  my $result = "";
  if($attributes)
  {
        log_registry("EEITJN         $result = $cli_tool $base sa:$mo_fdn:$attributes");
        $result = `$cli_tool $base "sa:$mo_fdn:$attributes"  2>&1`;

  }
  else
  {
	log_registry("No new attributes has given for the MO...");
	return 0;
  }
  if($result =~ /Exception/ or $result =~ /Connection refused/)
  {
        log_registry("Problem in setting attributes of MO: $mo_fdn \n $result");
        return 0;
  }
  return OK;
}

##############################################
#
# To Delete Proxy MO using CLI utility
# To Delete MO on CS side use base -> CSCLI
# To Delete MO on Node side use base -> CLI
#
##############################################
sub delete_mo_CLI
{
  my %param = ( base => "CSCLI" , @_ );

  if(!($param{mo}))
  {
        log_registry(" MO name is not specified.... ");
        return 0;
  }

  my $mo_fdn = mo_name_is_OK($param{mo}, qr/SubNetwork.*?MeContext=[^,\s]+/);
  log_registry("Given Mo name is not valid $param{mo}") if not $mo_fdn;
  return "0" if not $mo_fdn;

  my $base = $param{base};
  log_registry("Selected Base is not correct..., please use CSCLI or CLI as base") if not ($base eq "CSCLI" or $base eq "CLI");
  return "0" if not ($base eq "CSCLI" or $base eq "CLI");

  my $status = does_mo_exist_CLI( base => $base, mo => $mo_fdn);
  log_registry("Specified MO => $mo_fdn Exist") if ($status eq "YES");
  log_registry("Specified MO => $mo_fdn does not exist, so can not delete a non-existing MO...") if ($status eq "NO");
  return "0" if ($status eq "NO");
  return "0" if not $status ;
  log_registry(" MO => $mo_fdn is going to be deleted on Node side..., Selected Base is $base") if ($base eq "CLI");
  log_registry(" MO => $mo_fdn is going to be deleted on CS side...,Selected Base is $base") if ($base eq "CSCLI");
 
  my $result = "";
          log_registry("$cli_tool $base dm:$mo_fdn ");

  $result = `$cli_tool $base "dm:$mo_fdn"  2>&1`;
          
            log_registry("result -> $result ");

  if($result =~ /Exception/ or $result =~ /Connection refused/)
  {
        log_registry("Problem in deletion of MO: $mo_fdn \n $result");
        return 0;
  }
  return OK;
}

###########################################################################
#
# It is used to check MO exist in snad db based on label and level values
#
############################################################################
sub list_mos_exist_cs
{
   my $level = shift;
   my $key = shift;
   log_registry("Number of Level under $top_one base given is null, so not able to check MOs under CS...") if not $level;
   log_registry("Keyword for MOs is null, so not able to check MOs under CS...") if not $key;
   return "0" if not $key;
   return "0" if not $level;
   my $list_mos = `$cstest -s $segment_CS lm $top_one -l $level | grep $key`;
   return $list_mos;
}

####################################################################################
#
# To get mo fdn using cstest based on Input
# Inputs like: Type of MO, (Keyword) Pattern matching in Mo fdn and specific attribute value
#
####################################################################################

sub select_mo_cs 
{
   my %param = ( MO => "", KEY => "", ATTR => "", VAL => "", NOTKEY =>"", @_);
   my $typeMO = $param{MO};
   my $nameMO = $param{KEY};
   my $attr = $param{ATTR};
   my $attr_value = $param{VAL};
   my $not_keyword = $param{NOTKEY};
   log_registry("It seems no keyword supplied to get MO from cstest....") if not $typeMO;
   return "0" if not $typeMO;
   my $result;   
   $result = `$cstest -s $segment_CS lt $typeMO` if not ($nameMO or $attr);
   $result = `$cstest -s $segment_CS lt $typeMO | grep $nameMO` if ($nameMO and !($attr));
   $result = `$cstest -s $segment_CS lt $typeMO -f '$attr==$attr_value'` if ($attr and !($nameMO));
   $result = `$cstest -s $segment_CS lt $typeMO -f '$attr==$attr_value' | grep $nameMO` if ($attr and $nameMO);
   $result = `$cstest -s $segment_CS lt $typeMO -f '$attr==$attr_value' | grep -v $not_keyword` if ($attr and $not_keyword and !($nameMO));

   # eeitjn : fix added fro TC 4.4.1.9.2 was get MeContext and FDN with 0000:0000:0000
   $result = `$cstest -s $segment_CS lt $typeMO | grep -v $not_keyword | grep -v ":"` if ($not_keyword and $typeMO);

   $result =~ s/^\s+//; # To remove leading space

   if($result)
   {
      my @MOFDN;
      my @MOFDNS = split /\n/,$result;
      if($not_keyword and $nameMO)
      {
	  foreach(@MOFDNS)
	  {
		push(@MOFDN,$_) if ($_ !~ /$not_keyword/ );	
	  }
      }
      else
      {
		@MOFDN = @MOFDNS;
      }
      my $count_FDN = scalar @MOFDN;
      if($count_FDN == 1)
      {
         return (1,@MOFDN);
      }
      else
      {
         log_registry("<$count_FDN> MO Exist of $typeMO Type and $nameMO as Name") if $nameMO;
         log_registry("Total Count is : $count_FDN");
         return ($count_FDN,@MOFDN);
      }
   }
   return;
}

#####################################################
#
# Force CC nudge for a MO
#
####################################################

sub forceCC
{
# Changed in 12.2.4 to replace forceCC with a check action
#
	my $mo = shift;
	my $time = sleep_start_time();
	log_registry("check nudge is going to apply for the MO $mo") if $mo;
	log_registry("It seems no mo name has been supplied for check nudge...") if not $mo;
	return "0" if not $mo;
	my $result = `smtool -action cms_snad_reg check MoFDN $mo`;
	if($result =~ /Consistency check has completed/)
	{
		log_registry("It seems check  nudged successfully...");
	        my $nudge_state = nudge_cc_sybase($time);
		log_registry("It seems CC has not nudged...") if not $nudge_state;
   		log_registry("It seems CC has nudged... \n $nudge_state") if $nudge_state;
		return ($time);
	}
	else
	{
		log_registry("It seems there is a problem in nudging check CC on mo $mo \n $result");
		log_registry("WE didn't get Consistency check has completed as output from smtool -action cms_snad_reg check MoFDN");
		log_registry("There could be something wrong with forceCC in MasterProxyUtiles.pm file");
		return "0";
	} 
}

#########################################################################################
#
# This is a master function used to track MOs created in snad DB because of automation
#
##########################################################################################
sub list_all_mos
{
   my $file = shift;
   my $list_mos = 0;
   log_registry("Up to 4 level under $top_one base checking for list of master mos in region $region_CS");
   $list_mos = `$cstest -s $region_CS lm $top_one -l 4 > $file`;
   return $list_mos;
}

1;
