#!/usr/bin/perl

#################################################################
#
# To Create Master MO
#
#
#################################################################

sub FUT000  #0.0.0.0.0CLEAN  To check if MO exist created by master.pl after completion
{
  log_registry("==================== CLEAN UP: master.pl ========================");
  log_registry("Check if any MO still exist created by master.pl after completion of batch...");
  my $list_mos = list_mos_exist_cs("5",$mo_master_cms);
  if($list_mos)
  {
  	log_registry("===============================================================");
	log_registry("========= LIST of MOs =========================================");
	log_registry("$list_mos");
	log_registry("===============================================================");
	log_registry("Trying to delete MOs.... if someone fails please delete it manually....");
	my @mo = split ('\n',$list_mos);	
	my @rev_mo = reverse(@mo);
	foreach(@rev_mo)
	{
		log_registry("Trying to delete MO => $_ ");
		my $result = delete_mo_CS( mo => $_ );
		log_registry("ERROR => problem in deletion of MO $_ with result $result") if $result;
		if (! $result) 
			{
		        log_registry("FIX Delete => keeping MO $_ for second delete attempt") if $result;
			shift(@rev_mo) if !$result;
			}
	}
	foreach(@rev_mo)
	{
		log_registry("Second Trying to delete MO => $_ ");
	}

  }
  else
  {
	log_registry("It seems no MO exist in cs created by master.pl.....");
	log_registry("It looking good,But please check once manually in cstest as well...");
  }
}

sub FUT001   # 4.3.1.2.1  To create one ExternalUtranFreq type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.1 ; Create   - Create   ExternalUtranFreq from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT002   # 4.3.3.2.1 To delete one ExternalUtranFreq type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.2.1 ; Delete   - Delete Master ExternalUtranFreq MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","delete");
 
  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUT003   # 4.3.1.3.1  To create one ExternalCdma2000FreqBand type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.1 ; Create   - Create   ExternalCdma2000FreqBand from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT004   # 4.3.1.3.5 To create one ExternalCdma2000Freq type MO Based on existing ExternalCdma2000FreqBand
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.5 ; Create   - Create   ExternalCdma2000Freq from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT005   # 4.3.1.3.9 To create one ExternalCdma2000Cell type MO linked to existing ExternalCdma2000Freq
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.9 ; Create   - Create   ExternalCdma2000Cell from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","create");

  my @ExternalCdma2000Freq = `$cstest -s $region_CS lt ExternalCdma2000Freq`; 

  my $ExternalCdma2000Freq_ref = $ExternalCdma2000Freq[0];
  $ExternalCdma2000Freq_ref =~ s/\s+\n+//g;

  log_registry("To Create ExternalCdma2000Cell reference ExternalCdma2000Freq is -> $ExternalCdma2000Freq_ref");

  $attr = "$attr"." "."$ExternalCdma2000Freq_ref";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT006   # 4.3.3.3.9 To delete one ExternalCdma2000Cell type MO linked to existing ExternalCdma2000Freq
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.9 ; Delete   - Delete Master ExternalCdma2000Cell MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr); 
}

sub FUT007   # 4.3.3.3.5 To delete one ExternalCdma2000Freq type MO linked to existing ExternalCdma2000FreqBand
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.5 ; Delete   - Delete Master ExternalCdma2000Freq MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUT008   # 4.3.3.3.1 To delete one ExternalCdma2000FreqBand type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.1 ; Delete   - Delete Master ExternalCdma2000FreqBand MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUT009   # 4.3.1.4.1 To create one ExternalGsmFreqGroup type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.4.1 ; Create   - Create   ExternalGsmFreqGroup from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT010   # 4.3.1.4.8 To create one ExternalGsmFreq type MO linked to existing ExternalGsmFreqGroup 
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.4.8 ; Create - Create ExternalGsmFreq from an application where there is no corresponding proxy GeranFreqGroup in any LTE node, MissingProxy autofix off ;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT011   # 4.3.1.1.4 To create one ExternalGsmCell type MO linked to one existing ExternalGsmPlmn
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.4 ; Create   - Create snExteranlGsmcell from an application;; 1";

  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalGsmPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","create");
  
  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUT012   # 4.3.3.4.9 To delete one ExternalGsmFreq
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.4.9 ; Delete   - Delete Master ExternalGsmFreq MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUT013   # 4.3.3.4.1 To delete one ExternalGsmFreqGroup
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.4.1 ; Delete   - Delete Master ExternalGsmFreqGroup MO from an application;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr); 
}

sub FUT014   # 4.3.3.4.13 To delete one ExternalGsmCell
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUT015   # 4.3.1.2.5 To create one ExternalUtranFreq MO in a Planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.5 ; Create   - Create   ExternalUtranFreq from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name); 
}

sub FUT016   # 4.3.3.2.7 To delete one ExternalUtranFreq MO using Planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.2.7 ; Delete   - Delete Master ExternalUtranFreq MO from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","delete");

  my $status = mo_delete_decision("0",$base_fdn, $attr,$plan_name);
  test_failed($test_slogan) if ($status ne "OK");
  return "0" if ($status ne "OK");

  log_registry("Now creating master ExternalUtranFreq and proxy UtranFrequency  mo ..");
  my $ERBS = pick_a_ne("ENodeBFunction");
  log_registry("It seems no synched ERBS found ..") if not $ERBS;
  test_failed($test_slogan) if not $ERBS;
  return "0" if  not $ERBS;  

  my $UNW = pick_a_mo("$ERBS","UtraNetwork");
  log_registry("It seems no UtraNetwork mo found under selected ERBS : $ERBS") if not $UNW;
  test_failed($test_slogan) if not $UNW;
  return "0" if  not $UNW;
  log_registry("Selected UtraNetwork : $UNW ");

  ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","create");
  $status = mo_create_decision("0",$base_fdn, $attr,$plan_name);
  test_failed($test_slogan) if (!($status) or $status ne "OK");
  return "0" if (!($status) or $status ne "OK");
 
  my $UF = "$UNW".",UtranFrequency=$mo_master_cms";
  log_registry("Creating proxy UtranFrequency mo : $UF and attributes are $attr");
  $status = create_mo_CS(mo => $UF,attributes => $attr);
  log_registry("Problem in creation of proxy UtranFrequency mo..") if $status;
  test_failed($test_slogan) if $status;
  return "0" if $status;
  log_registry("Wait for 3 mins to get system stabililized ..");
  sleep 180;

  my $proxies = get_proxies_master($base_fdn);
  my $flag = 0;
  $flag = 1 if (!($proxies) and $proxies !~ /$UF/);
  log_registry("getProxiesForMaster $base_fdn are: \n $proxies") if $proxies;
  log_registry("It seems created proxy is not pointing to master :$base_fdn") if $flag;
  test_failed($test_slogan) if $flag;
  return "0" if $flag;

  $status = mo_delete_decision("0",$base_fdn, $attr,$plan_name);  
  test_failed($test_slogan) if ($status ne "OK");
  return "0" if ($status ne "OK");

  $status = does_mo_exist_CS( mo => $UF);
  $flag = 1 if ($status = $result_code_CS{MO_DOESNT_EXIST});
  log_registry("It seems proxy UtranFrequency mo is not get deleted while its master is deleted ...") if not $flag;
  log_registry("It seems proxy UtranFrequency mo is deleted with its master...") if $flag;
  test_failed($test_slogan) if not $flag;
  test_passed($test_slogan) if $flag;
}

sub FUT017   # 4.3.1.3.13 To create one ExternalCdma2000FreqBand type MO in a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.13 ; Create   - Create   ExternalCdma2000FreqBand from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT018#4.3.1.3.17 To create one ExternalCdma2000Freq type MO Based on existing ExternalCdma2000FreqBand in a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.17 ; Create   - Create   ExternalCdma2000Freq from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT019   #4.3.1.3.21 To create one ExternalCdma2000Cell type MO linked to existing ExternalCdma2000Freq in a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.3.21 ; Create   - Create   ExternalCdma2000Cell from an application, Planned Area;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","create");

  my @ExternalCdma2000Freq = `$cstest -s $region_CS lt ExternalCdma2000Freq`;

  my $ExternalCdma2000Freq_ref = $ExternalCdma2000Freq[0];
  $ExternalCdma2000Freq_ref =~ s/\s+\n+//g;

  log_registry("To Create ExternalCdma2000Cell reference ExternalCdma2000Freq is -> $ExternalCdma2000Freq_ref");

  $attr = "$attr"." "."$ExternalCdma2000Freq_ref";
  $attr =~ s/\n+//g ;

  my $plan_name = create_plan_name();

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT020#4.3.3.3.21 To delete one ExternalCdma2000Cell type MO linked to existing ExternalCdma2000Freq using a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.21 ; Delete   - Delete Master ExternalCdma2000Cell MO from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT021 # 4.3.3.3.17 To delete one ExternalCdma2000Freq type MO linked to existing ExternalCdma2000FreqBand using a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.17 ; Delete   - Delete Master ExternalCdma2000Freq MO from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT022   # 4.3.3.3.13 To delete one ExternalCdma2000FreqBand type MO using a planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.3.13 ; Delete   - Delete Master ExternalCdma2000FreqBand MO from an application, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT023   # 4.3.1.4.22 To create one ExternalGsmFreqGroup type MO using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.4.22 ; Create   - Create   ExternalGsmFreqGroup from an application; Planned Area; ; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT024   # 4.3.1.4.29 To create one ExternalGsmFreq type MO linked to existing ExternalGsmFreqGroup using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.4.29 ; WRANCM_CMSSnad_4.3.1.4.29 ; Create   - Create   ExternalGsmFreq from an application where theres no corresponding proxy GeranFreqGroup or , MissingProxy autofix off ; Planned Area;  1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT025   # 4.3.1.4.40 To create one ExternalGsmCell type MO using planned area linked to an existing ExternalGsmPlmn
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.4.40 ; Create   - Create   ExternalGsmCell from an application; Planned Area; ; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalGsmPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","create");

  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT026   # 4.3.3.4.25 To delete one ExternalGsmFreq using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.4.25 ; Delete   - Delete Master ExternalGsmFreq MO from an application; Planned Area; ; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT027   # 4.3.3.4.17 To delete one ExternalGsmFreqGroup using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.4.17 ; Delete   - Delete Master ExternalGsmFreqGroup MO from an application; Planned Area; ; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT028  # 4.3.3.4.29 To delete one ExternalGsmCell using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.4.29 ; Delete   - Delete Master ExternalGsmCell MO from an application; Planned Area; ; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT029  # 4.3.2.2.1 To set attributes of one Existing ExternalUtranFreq type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.2.1 ; Set ExternalUtranFreq attribute;; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}


sub FUT030  # 4.3.2.2.7 To set attributes of one Existing ExternalUtranFreq type MO using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.2.7 ; Set ExternalUtranFreq attribute, Planned Area;; 1";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalUtranFreq","set");

  mo_set_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUT031  # 4.3.2.3.7 To set attributes of one Existing ExternalCdma2000Cell type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT032  # 4.3.2.3.3 To set attributes of one Existing ExternalCdma2000Freq type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT033  # 4.3.2.3.1 To set attributes of one Existing ExternalCdma2000FreqBand type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT034  # 4.3.2.3.18  To set attributes of one Existing ExternalCdma2000Cell type MO using planned area
{
  my $test_slogan = $_[0];

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Cell","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT035  # 4.3.2.3.14 To set attributes of one Existing ExternalCdma2000Freq type MO using planned area
{
  my $test_slogan = $_[0];

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000Freq","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT036  # 4.3.2.3.12 To set attributes of one Existing ExternalCdma2000FreqBand type MO using planned area
{
  my $test_slogan = $_[0];
  
  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalCdma2000FreqBand","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT037  # 4.3.2.4.15 To set attributes of one Existing ExternalGsmCell type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.4.15 ; Set a Traffical Id attribute of master ExternalGsmCell; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT038  # 4.3.2.4.3 To set attributes of one Existing ExternalGsmFreq type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT039  # 4.3.2.4.1 To set attributes of one Existing ExternalGsmFreqGroup type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUT040  # 4.3.2.4.27  set attributes of one Existing ExternalGsmCell type MO using planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.4.27 ; Set a Traffical Id attribute of master ExternalGsmCell in Planned Area; 1";

  my $plan_name = create_plan_name();  

  my ($base_fdn, $attr) = get_fdn("ExternalGsmCell","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT041  # 4.3.2.4.18 To set attributes of one Existing ExternalGsmFreq type MO using planned area
{
  my $test_slogan = $_[0];

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreq","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUT042  # 4.3.2.4.16 To set attributes of one Existing ExternalGsmFreqGroup type MO using planned area
{
  my $test_slogan = $_[0];

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmFreqGroup","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS001  # 4.4.1.1.1 To create one UtranCell based on SNAD VS Test Cases
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.1.1.1 ; Create   - Create   UtranCell from an application; ; 1";

   my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
   my $rnc = pick_an_rnc();
   my ($rnc_name,$rest_attr) = cell_attr_fdn($base_fdn,$attr_full,$rnc);

   if($rnc_name)
   {
   	$attr_full = "$attr_full"." "."$rest_attr";
   	$attr_full =~ s/\n+//g ;
	$base_fdn = base_fdn_modify("$rnc_name","$base_fdn");
   	mo_create_decision($test_slogan,$base_fdn, $attr_full);
   }
   else
   {
	log_registry("There is no RNC has been picked, so leaving the processing of test case");
	mo_create_decision($test_slogan);
   }
}

sub FUTVS002  # 4.4.3.1.1 To delete one UtranCell 
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.3.1.1 ; Delete   - Delete Master UtranCell MO from an application; ; 1";

   my ($countUtranCell,@UtranCellFDN) = get_UtranCell($mo_master_cms);
   if($countUtranCell)
   {
       log_registry("Deleting Utran Cell: $UtranCellFDN[0]");
       mo_delete_decision($test_slogan,$UtranCellFDN[0]);
   }
   else
   {
      log_registry("There is no Existing UtranCell of $mo_master_cms, To avoid any conflicts please create one UtranCell so run master.pl with 4.4.1.1.1 test case ");
      mo_delete_decision($test_slogan);
   }
}

sub FUTVS003   # 4.4.2.1.1 To set attributes of one existing UtranCell 
{
   my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.2.1.1 ; Set   - Set   UtranCell attribute; ; 1";

   my ($countUtranCell,@UtranCellFDN) = get_UtranCell($mo_master_cms);
   if($countUtranCell)
   {
   	my ($base_fdn,$attr) = get_fdn("UtranCell","set");
	log_registry("Utran Cell Selected to set attributes: $UtranCellFDN[0]");
       	mo_set_decision($test_slogan,$UtranCellFDN[0],$attr);
   }
   else
   {
      log_registry("There is no Existing UtranCell of $mo_master_cms, To avoid any conflicts please create one UtranCell so run master.pl with 4.4.1.1.1 test case ");
      test_failed($test_slogan);
   }
}

sub FUTVS004  # 4.3.1.1.8 To create one ExternalGsmPlmn type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.8 ; Create   - Create   ExternalGsmPlmn from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmPlmn","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS005  # 4.3.2.1.8 To set attributes of one ExternalGsmPlmn type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalGsmPlmn","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS006  # 4.3.3.1.9 To delete one ExternalGsmPlmn type MO 
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.9 ; Delete   - Delete Master ExternalGsmPlmn MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalGsmPlmn","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS007  # 4.3.1.1.6 To create one Plmn type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.6 ; Create   - Create   Plmn from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("Plmn","create");

  mo_create_decision($test_slogan,$base_fdn, $attr); 
}

sub FUTVS008  # 4.3.2.1.7 To set attributes of Plmn type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("Plmn","set");

  mo_set_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS009  # 4.3.3.1.5 To delete one Plmn type MO
{
  my $test_slogan = $_[0]; 
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.5 ; Delete   - Delete Master Plmn MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("Plmn","delete");
  
  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS010  # 4.3.5.1.2CEGP To create one ExternalGsmPlmn type MO using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."ExternalGsmPlmn_Create";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmPlmn","create");

  mo_create_decision($test_slogan,$base_fdn,$attr,$plan_name);
}
 
sub FUTVS011  # 4.3.5.1.6DEGP To delete one ExternalGsmPlmn type MO using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."ExternalGsmPlmn_Delete";
  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("ExternalGsmPlmn","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS012  # 4.3.5.1.22 To create/delete one Plmn type MO using Planned area
{
  my $test_slogan = $_[0];
  my $test_slogan_c = "$test_slogan"."CreatePlmn";
  my ($base_fdn, $attr) = get_fdn("Plmn","create");
  my $plan_name = create_plan_name();
  mo_create_decision($test_slogan_c,$base_fdn,$attr,$plan_name);
  
  log_registry("$test_slogan =>Now Starting Delete one after Creation within Same Test Case ....");
  my $test_slogan_d = "$test_slogan"."DeletePlmn";
  ($base_fdn, $attr) = get_fdn("Plmn","delete");
  $plan_name = create_plan_name();
  mo_delete_decision($test_slogan_d,$base_fdn, $attr,$plan_name);
}

sub FUTVS013  # 4.3.5.1.2CUCL To create one UtranCell using planned area
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."UtranCell_Create";
   my $plan_name = create_plan_name();
   my ($base_fdn,$attr_full) = get_fdn("UtranCell","create");
   my $rnc = pick_an_rnc();
   my ($rnc_name,$rest_attr) = cell_attr_fdn($base_fdn,$attr_full,$rnc);

   if($rnc_name)
   {
        $attr_full = "$attr_full"." "."$rest_attr";
        $attr_full =~ s/\n+//g ;
	$base_fdn = base_fdn_modify("$rnc_name","$base_fdn");
        mo_create_decision($test_slogan,$base_fdn, $attr_full,$plan_name);
   }
   else
   {
        log_registry("There is no RNC has been picked, so leaving the processing of test case");
        mo_create_decision($test_slogan);
   }
}

sub FUTVS014  # 4.3.5.1.6DUCL To delete one UtranCell using planned area
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."UtranCell_Delete";
   my $plan_name = create_plan_name();
   my $attr = "";
   my ($countUtranCell,@UtranCellFDN) = get_UtranCell($mo_master_cms);
   if($countUtranCell)
   {
       log_registry("Deleting Utran Cell: $UtranCellFDN[0]");
       mo_delete_decision($test_slogan,$UtranCellFDN[0],$attr,$plan_name);
   }
   else
   {
      log_registry("There is no Existing UtranCell of $mo_master_cms, To avoid any conflicts please create one UtranCell so run master.pl with 4.4.1.1.1 test case ");
      mo_delete_decision($test_slogan);
   }
}

sub FUTVS015  # 4.4.1.1.10 To create one WcdmaCarrier using planned area
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.1.1.10 ; Update RNC to add additional WcdmaCarrier MO in a planned area; Normal; 1";

   my $plan_name = create_plan_name();
   my ($base_fdn,$attr_full) = get_fdn("WcdmaCarrier","create");
   my $rnc = pick_an_rnc();

   if($rnc)
   {
	$base_fdn = base_fdn_modify("$rnc","$base_fdn");
        mo_create_decision($test_slogan,$base_fdn, $attr_full,$plan_name);
   }
   else
   {
        log_registry("There is no RNC has been picked, so leaving the processing of test case");
        mo_create_decision($test_slogan);
   }
}

sub FUTVS016  # 4.4.3.1.7 To delete one WcdmaCarrier using planned area
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.3.1.7 ; Delete a WcdmaCarrier MO in a Planned Area; Normal; 1";

   my $plan_name = create_plan_name();
   my ($countWcdmaCarrier,@WcdmaCarrierFDN) = get_WcdmaCarrier($mo_master_cms);
   if($countWcdmaCarrier)
   {
       log_registry("Deleting Utran Cell: $WcdmaCarrierFDN[0]");
       mo_delete_decision($test_slogan,$WcdmaCarrierFDN[0],$plan_name);
   }
   else
   {
      log_registry("There is no Existing WcdmaCarrier of $mo_master_cms, To avoid any conflicts please create one WcdmaCarrier using master.pl ");
      mo_delete_decision($test_slogan);
   }
}

sub FUTVS017  # 4.4.1.1.9 To create one WcdmaCarrier 
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.1.1.9 ; Update RNC to add additional WcdmaCarrier MO; Normal; 1";

   my ($base_fdn,$attr_full) = get_fdn("WcdmaCarrier","create");
   my $rnc = pick_an_rnc();

   if($rnc)
   {
	$base_fdn = base_fdn_modify("$rnc","$base_fdn");
        mo_create_decision($test_slogan,$base_fdn, $attr_full);
   }
   else
   {
        log_registry("There is no RNC has been picked, so leaving the processing of test case");
        mo_create_decision($test_slogan);
   }
}


sub FUTVS018  # 4.4.3.1.6 To delete one WcdmaCarrier
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.4.3.1.6 ; Delete a WcdmaCarrier MO; Normal; 1";

   my ($countWcdmaCarrier,@WcdmaCarrierFDN) = get_WcdmaCarrier($mo_master_cms);
   if($countWcdmaCarrier)
   {
       log_registry("Deleting Utran Cell: $WcdmaCarrierFDN[0]");
       mo_delete_decision($test_slogan,$WcdmaCarrierFDN[0]);
   }
   else
   {
      log_registry("There is no Existing WcdmaCarrier of $mo_master_cms, To avoid any conflicts please create one WcdmaCarrier using master.pl ");
      mo_delete_decision($test_slogan);
   }
}

sub FUTVS019  # 4.3.1.1.9 To create one MbmsServiceArea type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.9 ; Create   - Create sn MbmsServiceArea from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","create");

  mo_create_decision($test_slogan,$base_fdn, $attr); 
}

sub FUTVS020  # 4.3.3.1.17 To delete one MbmsServiceArea type MO
{
  my $test_slogan = $_[0]; 
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.17 ; Delete   - Delete Master MbmsServiceArea MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","delete");
  
  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS021  # 4.3.2.1.4 To set attributes of MbmsServiceArea type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","set");

  mo_set_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS022  # 4.4.1.1.4 To Create Master MO EUtranCellFDD having a reference with one existing SectorEquipmentFunction
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("EUtranCellFDD","create");
  my $erbs = pick_a_ne(ENodeBFunction);
  if($erbs)
  {
  	my $mec = get_mec($erbs);
  	my ($fdn_SEF,$attr_SEF) = get_fdn("SectorEquipmentFunction","create");
	$fdn_SEF = base_fdn_modify("$mec","$fdn_SEF");
	mo_create_decision(0,$fdn_SEF,$attr_SEF);	
	$base_fdn = base_fdn_modify("$erbs","$base_fdn");
	$attr = "$attr"." "."$fdn_SEF";
	$attr =~ s/\n+//g ;
	mo_create_decision($test_slogan,$base_fdn,$attr);
   }
   else
   {
        log_registry("There is no synched ERBS has been picked, so leaving the processing of test case");
        mo_create_decision($test_slogan);
   }
}

sub FUTVS023 # 4.4.2.1.14 To set attributes of EUtranCellFDD 
{
   my $test_slogan = $_[0];
   my ($count_cell,@EUtranCellFDD) = get_CMS_mo(EUtranCellFDD,$mo_master_cms);
   if($count_cell)
   {
	log_registry("Selected EUtranCellFDD: $EUtranCellFDD[0]");
	my ($base_fdn, $attr) = get_fdn("EUtranCellFDD","set");
	mo_set_decision($test_slogan,$EUtranCellFDD[0],$attr);
   }
   else
   {
	log_registry("There is no existing EUtranCellFDD type mo of $mo_master_cms, so leaving the processing of test case");
	test_failed($test_slogan);
   }
}

sub FUTVS024 # 4.4.3.1.20 To delete one existing EUtranCellFDD type MO
{
   my $test_slogan = $_[0];
   my ($count_cell,@EUtranCellFDD) = get_CMS_mo(EUtranCellFDD,$mo_master_cms);
   if($count_cell)
   {
        log_registry("Selected EUtranCellFDD: $EUtranCellFDD[0]");
        mo_delete_decision($test_slogan,$EUtranCellFDD[0]);
	my ($count_SEF,@SectorEquipmentFunction) = get_CMS_mo(SectorEquipmentFunction,$mo_master_cms);
	if($count_SEF)
    	{
		log_registry("Deleteing existing SectorEquipmentFunction type MO created by $mo_master_cms to avoid Junk");
		for(my $i=0; $i < $count_SEF; $i++)
		{
			log_registry("Selected MO is: $SectorEquipmentFunction[$i]");
			delete_mo_CS(mo => $SectorEquipmentFunction[$i]);
		}
	}
   }
   else
   {
        log_registry("There is no existing EUtranCellFDD type mo of $mo_master_cms,so leaving the processing of test case");
        test_failed($test_slogan);
   }
}

sub FUTVS025  # 4.3.5.1.2CEUCFD To Create Master MO EUtranCellFDD having a refernec with one existing SectorEquipmentFunction using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."Create_EUtranCellFDD";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("EUtranCellFDD","create");
  my $erbs = pick_a_ne(ENodeBFunction);
  if($erbs)
   {
        my $mec = get_mec($erbs);
        my ($fdn_SEF,$attr_SEF) = get_fdn("SectorEquipmentFunction","create");
	$fdn_SEF = base_fdn_modify("$mec","$fdn_SEF");
        mo_create_decision(0,$fdn_SEF,$attr_SEF);
	$base_fdn = base_fdn_modify("$erbs","$base_fdn");
        $attr = "$attr"." "."$fdn_SEF";
        $attr =~ s/\n+//g ;
        mo_create_decision($test_slogan,$base_fdn,$attr,$plan_name);
   }
   else
   {
        log_registry("There is no synched ERBS has been picked, so leaving the processing of test case");
        mo_create_decision($test_slogan);
   }
}

sub FUTVS026 # 4.3.5.1.6DEUCFD To delete one existing EUtranCellFDD type MO using Planned area
{
   my $test_slogan = $_[0];
   $test_slogan = "$test_slogan"."Delete_EUtranCellFDD";
   my $plan_name = create_plan_name();
   my ($count_cell,@EUtranCellFDD) = get_CMS_mo(EUtranCellFDD,$mo_master_cms);
   if($count_cell)
   {
        log_registry("Selected EUtranCellFDD: $EUtranCellFDD[0]");
        mo_delete_decision($test_slogan,$EUtranCellFDD[0],"",$plan_name);
        my ($count_SEF,@SectorEquipmentFunction) = get_CMS_mo(SectorEquipmentFunction,$mo_master_cms);
        if($count_SEF)
        {
                log_registry("Deleteing existing SectorEquipmentFunction type MO created by $mo_master_cms to avoid Junk");
                for(my $i=0; $i < $count_SEF; $i++)
                {
                        log_registry("Selected MO is: $SectorEquipmentFunction[$i]");
                        delete_mo_CS(mo => $SectorEquipmentFunction[$i]);
                }
        }
   }
   else
   {
        log_registry("There is no existing EUtranCellFDD type mo of $mo_master_cms,so leaving the processing of test case");
        test_failed($test_slogan);
   }
}

sub FUTVS027  # 4.3.1.1.7 Create one ExternalUtranPlmn type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.7 ; Create   - Create   ExternalUtranPlmn from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranPlmn","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS028  # 4.3.2.1.9 To set attributes of one ExternalUtranPlmn type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalUtranPlmn","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS029  # 4.3.3.1.7 To delete one ExternalUtranPlmn type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.7 ; Delete   - Delete Master ExternalUtranPlmn MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranPlmn","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS030  # 4.3.5.1.2CEUP Create one ExternalUtranPlmn type MO using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."Create_ExternalUtranPlmn";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalUtranPlmn","create");

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS031  # 4.3.5.1.7 To delete one ExternalUtranPlmn type MO using planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.5.1.7 ; Delete ExternalUtranPlmn using planned area; Normal; 1";

  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalUtranPlmn","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS032   # 4.3.1.1.5 To create one ExternalUtranCell type MO linked to one existing ExternalUtranPlmn
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.5 ; Create   - Create   snExternalUtranCell from an application; ;1";

  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalUtranPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalUtranCell","create");

  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS060   # 4.3.1.2.9 To create one ExternalUtranCellTDD type MO linked to one existing ExternalUtranPlmn
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.9 ; Create   - Create ExternalUtranCellTDD from an application; ;1";

  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalUtranPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","create");

  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS061   # 4.3.1.2.13 To create one ExternalUtranCellTDD type MO in a Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.13 ; Create   - Create ExternalUtranCellTDD from an application, Planned Area ;1";
  my $plan_name = create_plan_name(); 
 
  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalUtranPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","create");
  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS033  # 4.3.2.1.6 To set attributes of one Existing ExternalUtranCell type MO
{
  my $test_slogan = $_[0];

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCell","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}


sub FUTVS058  # 4.3.2.2.15 To set attributes of one Existing ExternalUtranCellTDD type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.2.15 ; Set ExternalUtranCellTDD attribute; ;1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS062  # 4.3.2.2.16 To set attributes ExternalUtranCellTDD type MO in Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.2.16 ; Set ExternalUtranCellTDD attribute, Planned Area ;1";
  my $plan_name = create_plan_name(); 

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS034  # 4.3.3.1.3 To delete one ExternalUtranCell type mo
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.3 ; Delete   - Delete Master snExternalUtranCell MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}


sub FUTVS059  # 4.3.3.2.14 To delete one ExternalUtranCellTDD type mo
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.2.14 ; Delete   - Delete Master snExternalUtranCellTDD MO from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr);
}


sub FUTVS063  # 4.3.3.2.16 To delete one ExternalUtranCellTDD type mo in Planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.2.14 ; Delete   - Delete Master snExternalUtranCellTDD MO from an application, Planned Area ; 1";
  my $plan_name = create_plan_name(); 

  my ($base_fdn, $attr) = get_fdn("ExternalUtranCellTDD","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name );
}


sub FUTVS035   # 4.3.5.1.2CEUC To create one ExternalUtranCell type MO linked to one existing ExternalUtranPlmn using Planned area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."Create_ExternalUtranCell";
  my $plan_name = create_plan_name(); 
  my ($base_fdn_Plmn, $attr_Plmn) = get_fdn("ExternalUtranPlmn","create");
  my ($base_fdn, $attr) = get_fdn("ExternalUtranCell","create");

  $attr = "$attr"." "."$base_fdn_Plmn";
  $attr =~ s/\n+//g ;

  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS036  # 4.3.5.1.6DEUC To delete one ExternalUtranCell type mo using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."Delete_ExternalUtranCell";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalUtranCell","delete");

  mo_delete_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS037  # 4.3.1.1.1 To create one LocationArea type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.1 ; Create   - Create   snLocationArea from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("LocationArea","create");

  mo_create_decision($test_slogan,$base_fdn, $attr); 
}

sub FUTVS038  # 4.3.5.1.28 To create one MbmsServiceArea type MO using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."MbmsServiceArea_Create";

  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","create");

  mo_create_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS039  # 4.3.5.1.29 To set attributes of MbmsServiceArea type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."MbmsServiceArea_Set";	
  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","set");

  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}
 
sub FUTVS040  # 4.3.5.1.30 To delete one MbmsServiceArea type MO using Planned Area
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."MbmsServiceArea_Delete";
  my $plan_name = create_plan_name();

  my ($base_fdn, $attr) = get_fdn("MbmsServiceArea","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr,$plan_name);
}


sub FUTVS041  # 4.3.2.1.1 Set   snLocationArea attribute
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.1 ; Set   snLocationArea attribute";

  my ($base_fdn, $attr) = get_fdn("LocationArea","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS042  # 4.3.3.1.11 Delete Master snLocationArea MO from an application
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.11 ;Delete Master snLocationArea MO from an application";

  my ($base_fdn, $attr) = get_fdn("LocationArea","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS043  # 4.3.5.1.19 
{
  my $test_slogan = $_[0];
  log_registry("WRANCM_CMSSnad_4.3.5.1.19 ; Planned Area - Create/Modify/Delete LocationArea,RoutingArea,ServiceArea");
  my $flag = 0;
  my $plmn;
  my $rnc = pick_a_ne(RncFunction);
  my $pickLA = pick_a_mo($rnc,LocationArea);
  
  my $plmn_la = get_master_for_proxy($pickLA);
  my ($plmn,$b) = $plmn_la =~ /(.*),(.*)/;

  if($plmn and $rnc)
  {
  	log_registry("Using plmn $plmn_proxies removed $b");
  }
  else
  {
	log_registry("It seems either no Plmn exist or no synched RNC found, so leaving test case execution...");
	test_failed($test_slogan);
	return "0";
  }
  log_registry("It seems RNC is not linked with Plmn, so leaving test case execution...") if not $plmn;
  test_failed($test_slogan) if not $plmn;
  return "0" if not $plmn;
  my $test_slogan_la_c = "$test_slogan"."LocationAreaCreate";
  my ($la_fdn, $la_attr) = get_fdn("LocationArea","create");
  my $plan_name = create_plan_name();
  $la_fdn =~ s/^SubNet.*Plmn\=.*\,/$plmn\,/;
  my $la_create_status = mo_create_decision($test_slogan_la_c,$la_fdn,$la_attr,$plan_name);

  my $test_slogan_sa_c = "$test_slogan"."ServiceAreaCreate";
  my ($sa_fdn, $sa_attr) = get_fdn("ServiceArea","create");
  $plan_name = create_plan_name();
  $sa_fdn =~ s/^SubNet.*Plmn\=.*\,/$la_fdn\,/;
  my $sa_create_status = mo_create_decision($test_slogan_sa_c,$sa_fdn, $sa_attr,$plan_name);

  my $test_slogan_ra_c = "$test_slogan"."RoutingAreaCreate";
  my ($ra_fdn, $ra_attr) = get_fdn("RoutingArea","create");
  $plan_name = create_plan_name();
  $ra_fdn =~ s/^SubNet.*Plmn\=.*\,/$la_fdn\,/;
  my $ra_create_status = mo_create_decision($test_slogan_ra_c,$ra_fdn, $ra_attr,$plan_name);

  log_registry("$test_slogan =>Now Starting modify one after Creation within Same Test Case ....");
  my $test_slogan_la_m = "$test_slogan"."LocationAreaModify";
  my ($la_fdn_m, $la_attr_m) = get_fdn("LocationArea","set");
  $plan_name = create_plan_name();
  my $la_modify_status = mo_set_decision($test_slogan_la_m,$la_fdn,$la_attr_m,$plan_name);

  my $test_slogan_sa_m = "$test_slogan"."ServiceAreaModify";
  my ($sa_fdn_m, $sa_attr_m) = get_fdn("ServiceArea","set");
  $plan_name = create_plan_name();
  my $sa_modify_status = mo_set_decision($test_slogan_sa_m,$sa_fdn,$sa_attr_m,$plan_name);

  my $test_slogan_ra_m = "$test_slogan"."RoutingAreaModify";
  my ($ra_fdn_m, $ra_attr_m) = get_fdn("RoutingArea","set");
  $plan_name = create_plan_name();
  my $ra_modify_status = mo_set_decision($test_slogan_ra_m,$ra_fdn,$ra_attr_m,$plan_name);

  my $test_slogan_uc_c = "$test_slogan"."CreateUtranCell";
  $plan_name = create_plan_name();
  my $plan = create_plan_area($plan_name);
  my $time = sleep_start_time();
  my $cell = create_UtranCell($rnc,"$la_attr $sa_attr $ra_attr",$plan_name); 
  if($cell)
  {
  	long_sleep_found($time);
	my $stat = get_master($cell);
  	get_mo_attr($cell,"$la_attr $sa_attr $ra_attr");
  	test_passed($test_slogan_uc_c) if ($stat);
	test_failed($test_slogan_uc_c) if not ($stat);
	return "0" if not ($stat);
  }
  else
  {
	test_failed($test_slogan_uc_c);
	return "0";
  }
  log_registry("Deleting UtranCell/LocationArea/ServiceArea/RoutingArea..."); 
  my $delete_cell = delete_mo_CS(mo => $cell);
  $time = sleep_start_time(); 
  my $areas = delete_mo_CS(mo => $la_fdn);
  test_failed($test_slogan) if ($delete_cell or $areas);
  return "0" if ($delete_cell or $areas);
  long_sleep_found($time);
  my $review_cache_log = cache_file();
  my ($cell_id,$cell_log) = rev_find(file => $review_cache_log,mo => $cell);
  my ($la_id,$la_log) = rev_find(file => $review_cache_log,mo => $la_fdn);
  my ($sa_id,$sa_log) = rev_find(file => $review_cache_log,mo => $sa_fdn);
  my ($ra_id,$ra_log) = rev_find(file => $review_cache_log,mo => $ra_fdn);
  my $test_slogan_la_d = "$test_slogan"."LocationAreaDelete";
  my $test_slogan_sa_d = "$test_slogan"."ServiceAreaDelete";
  my $test_slogan_ra_d = "$test_slogan"."RoutingAreaDelete";
  my $test_slogan_cell_d = "$test_slogan"."UtranCellDelete";
  test_passed($test_slogan_la_d) if not $la_id;
  test_passed($test_slogan_sa_d) if not $sa_id;
  test_passed($test_slogan_ra_d) if not $ra_id;
  test_passed($test_slogan_cell_d) if not $cell_id;
  $flag = 0;
  $flag = 1 if ($cell_id  or $la_id  or $sa_id  or $ra_id); 
  test_failed($test_slogan) if $flag;
  log_registry("Problem in deletion of UtranCell/locationArea/RoutingArea/ServiceArea...") if $flag;
  return "0" if $flag;
  if(!($flag) and $ra_modify_status and $sa_modify_status and $la_modify_status and $ra_create_status and $sa_create_status and $la_create_status and $ra_create_status eq "OK" and $sa_create_status eq "OK" and $la_create_status eq "OK")
   {
	test_passed($test_slogan);
   }
   else
   {
	test_failed($test_slogan);
   }
}

sub FUTVS044  # 4.3.1.1.2
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.2 ; Create   - Create   snRoutingArea from an application";
  my ($base_fdn, $attr) = get_fdn("RoutingArea","create");
  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS045  #4.3.1.1.3
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.3 ; Create   - Create   snServiceArea from an application";
  my ($base_fdn, $attr) = get_fdn("ServiceArea","create");
  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS046  # 4.3.2.1.2 Set   snRoutingArea attribute
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.2 ; Set snRoutingArea attribute";

  my ($base_fdn, $attr) = get_fdn("RoutingArea","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS047  # 4.3.2.1.3 Set   snServiceArea attribute
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.3 ; Set   snServiceArea attribute";

  my ($base_fdn, $attr) = get_fdn("ServiceArea","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS048  # 4.3.3.1.13
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.13 ; Delete Master snRoutingArea MO from an application";

  my ($base_fdn, $attr) = get_fdn("RoutingArea","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS049  # 4.3.3.1.15
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.15 ; Delete Master snServiceArea MO from an application";

  my ($base_fdn, $attr) = get_fdn("ServiceArea","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr);
}

# ExternalEutranFrequency MO are all moved to FUT_MASTER.pm and run in proxy.pl
sub FUTVS050  #4.3.1.1.16
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.16;Create master sn ExternalEutranFrequency from an application";
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","create");
  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS051  # 4.3.2.1.11
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.11 ; Set ExternalEutranFrequency attribute";

  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","set");

  mo_set_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS052  # 4.3.3.1.23
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.23;Delete Master ExternalEutranFrequency MO from an application";

  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","delete");

  mo_delete_decision($test_slogan,$base_fdn,$attr);
}

sub FUTVS053  #4.3.5.1.4
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.5.1.4;Create master ExternalEutranFrequency from an application in a PLANNED Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","create");
  mo_create_decision($test_slogan,$base_fdn, $attr,$plan_name);
}

sub FUTVS054  # 4.3.2.1.15
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.2.1.15 ; Set ExternalEutranFrequency attribute, Planned Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","set");
  mo_set_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS055  # 4.3.3.1.27
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.27;Delete Master ExternalEutranFrequency MO from an application, Planned Area";
  my $plan_name = create_plan_name();
  my ($base_fdn, $attr) = get_fdn("ExternalEutranFrequency","delete");
  mo_delete_decision($test_slogan,$base_fdn,$attr,$plan_name);
}

sub FUTVS056  # 4.3.1.1.22 and 4.3.1.1.22P
{
  my $test_slogan = $_[0];
  my $result,$tc_id;
  $tc_id = 1 if($test_slogan =~ /4\.3\.1\.1\.22/);
  $tc_id = 2 if($test_slogan =~ /4\.3\.1\.1\.22P/);
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.22;Create master EUtranFrequency in plan area" if($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.22;Create master  EUtranFrequency in valid area" if($tc_id == 1);
  my $plan_name = create_plan_name() if ($tc_id == 2);
  my ($base_fdn, $attr) = get_fdn("MasterEUtranFrequency","create");
  mo_create_decision($test_slogan,$base_fdn,$attr,$plan_name) if ($tc_id == 2);
  mo_create_decision($test_slogan,$base_fdn,$attr) if ($tc_id == 1); 
}


sub FUTVS057  # 4.3.3.1.31 and 4.3.3.1.31P
{
  my $test_slogan = $_[0];
  my $area,$result,$tc_id,$plan_name;
  $tc_id = 1 if($test_slogan =~ /4\.3\.3\.1\.31/);
  $tc_id = 2 if($test_slogan =~ /4\.3\.3\.1\.31P/);
  $area = "Valid" if ($tc_id == 1);
  $area = "Plan" if ($tc_id == 2);
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.3.1.31 ; Delete Master sn EUtranFrequency MO in $area area";
  my $test_slogan_1 = "$test_slogan"." - No Proxy Exists under Master";
  my $test_slogan_2 = "$test_slogan"." - Proxy exist under master EUtranFrequency but proxy is Redundant";
  my $test_slogan_3 = "$test_slogan"." - Reserved proxies exists under master EUtranFrequency mo";
  my ($base_fdn, $attr) = get_fdn("MasterEUtranFrequency","delete");
  $plan_name = create_plan_name() if ($tc_id == 2);
  $result = mo_delete_decision($test_slogan_1,$base_fdn,$attr,"$plan_name","no wait");
  return "0" if ($result ne "OK");
  my $ERBS = pick_a_ne("ENodeBFunction","NEW");
  if($ERBS)
  {
	my $EUtraNetwork = pick_a_mo($ERBS,"EUtraNetwork");
	log_registry("It seems no EUtraNetwork is found under ERBS $ERBS...") if not $EUtraNetwork;
	test_failed($test_slogan_2) if not $EUtraNetwork;
	return "0" if not $EUtraNetwork;
  	$result = mo_create_decision("0",$base_fdn,$attr,"","wait for long sleep");
  	test_failed($test_slogan_2) if (!($result) or $result ne "OK");
  	return "0" if (!($result) or $result ne "OK");
	my $proxy_mo = "$EUtraNetwork".",EUtranFrequency=$mo_master_cms";
	log_registry("Creating Proxy EUtranFrequency MO: $proxy_mo \n attributes will be $attr");
	$result = create_mo_CS(mo => $proxy_mo, attributes => $attr);
	log_registry("Problem in creation of proxy EUtranFrequency ...") if $result;
	test_failed($test_slogan_2) if $result;
	return "0" if $result;
	sleep 180;
        my $review_cache_log = cache_file();
        my ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $proxy_mo);
	log_registry("Proxy does not seems to be redundant ..") if (!($rev_log) or $rev_id == 1);
	test_failed($test_slogan_2) if (!($rev_log) or $rev_id == 1);
	return "0" if (!($rev_log) or $rev_id == 1);
	my $proxies = get_proxies_master($base_fdn);
	log_registry("It seems proxy $proxy_mo is not under master $base_fdn ..") if ($proxies !~ /$proxy_mo/);
	test_failed($test_slogan_2) if ($proxies !~ /$proxy_mo/);
	return "0" if ($proxies !~ /$proxy_mo/);
	$result = mo_delete_decision("0",$base_fdn,$attr,"$plan_name","no wait");
	test_failed($test_slogan_2) if ($result ne "OK");
  	return "0" if ($result ne "OK");
        $review_cache_log = cache_file();
        ($rev_id,$rev_log) = rev_find(file => $review_cache_log,mo => $proxy_mo);
	log_registry("It seems proxy no more exist after deletion of master mo ...") if not $rev_log;
	test_passed($test_slogan_2) if not $rev_log;
	test_failed($test_slogan_2) if $rev_log;	
	return "0" if $rev_log;
#################################### deleton of master EUtranFrequency when consistent proxy exist under master #############
	my $EUtranFrequency = pick_a_mo($EUtraNetwork,"EUtranFrequency");
        log_registry("It seems no EUtranFrequency is found under $EUtraNetwork...") if not $EUtranFrequency;
        test_failed($test_slogan_3) if not $EUtranFrequency;
        return "0" if not $EUtranFrequency;
	my %attrs = get_mo_attributes_CS( mo => $EUtranFrequency,attributes => "reservedBy");
	log_registry("It seems selected EUtranFrequency is redundant, its atttribute reservedBy is null") if not $attrs{reservedBy};
	test_failed($test_slogan_3) if not $attrs{reservedBy};
	return "0" if not $attrs{reservedBy};
	my $master = get_master_for_proxy($EUtranFrequency);
	log_registry("No master exist for the Proxy $EUtranFrequency") if not $master;
	test_failed($test_slogan_3) if not $master;
	return "0" if not $master;
	$master =~ s/\n+//g;
	$result = mo_delete_decision("0",$master,"","$plan_name","no wait");
	log_registry("It seems master mo $master is get deleted while proxies are reserved it was not expected") if ($result eq "OK");
	test_failed($test_slogan_3) if ($result eq "OK");
	test_passed($test_slogan_3) if ($result ne "OK");
  }
  else
  {
	log_registry("It seems no synched ERBS found ...");
	test_failed($test_slogan);
  }
}

sub FUTVS064  # 4.3.1.1.31 Create one ExternalEUtranPlmn type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.1.31 ; Create   - Create   ExternalEUtranPlmn from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalEUtranPlmn","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS065  # 4.3.1.2.19 Create one ExternalEUtranCellFDD type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.19 ; Create   - Create   ExternalEUtranCellFDD from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalEUtranCellFDD","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}

sub FUTVS066  # 4.3.1.2.15 Create one ExternalEUtranCellTDD type MO
{
  my $test_slogan = $_[0];
  $test_slogan = "$test_slogan"."-"."WRANCM_CMSSnad_4.3.1.2.15 ; Create   - Create   ExternalEUtranCellTDD from an application; ; 1";

  my ($base_fdn, $attr) = get_fdn("ExternalEUtranCellTDD","create");

  mo_create_decision($test_slogan,$base_fdn, $attr);
}



1;
