#package Abills::Templates;

=head1 NAME

  Base ABIllS Templates Managments

=cut

use strict;

my $domain_path = '';
our (
  $Bin,
  %FORM,
  $admin,
  $html,
  %lang,
  %conf
);

use FindBin '$Bin';
#if ($admin && $admin->{DOMAIN_ID}) {
#  $domain_path = "$admin->{DOMAIN_ID}/";
#}

#**********************************************************
=head2 _include($tpl, $module, $attr) - templates

  Arguments
    $tpl
    $module
    $attr
      CHECK_ONLY
      SUFIX
      DEBUG

  Returns:
    Retun content

=cut
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;

  my $sufix = ($attr->{pdf} || $FORM{pdf}) ? '.pdf' : '.tpl';
  $tpl .= '_' . $attr->{SUFIX} if ($attr->{SUFIX});

  start:
  $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
  }
  elsif ($FORM{DOMAIN_ID}) {
    $domain_path = "$FORM{DOMAIN_ID}/";
  }

  $FORM{NAS_GID}='' if (!$FORM{NAS_GID});
  my $language = $html->{language} || q{};

  my @search_paths = (
    $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . "_$language" . $sufix,
    $Bin . '/../Abills/templates/' . $domain_path . '/' . $FORM{NAS_GID} . '/' . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/' . $domain_path  . $module . '_' . $tpl . "_$language" . $sufix,
           '../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
           '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . "_$language" . $sufix,
           '../../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
           '../Abills/templates/' . $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/'. $domain_path . $module . '_' . $tpl . $sufix,
    $Bin . '/../Abills/templates/' . $module . '_' . $tpl . "_$language" . $sufix,
    #Fixme for unifi hotspot
    $Bin . '/../../../../../../../Abills/templates/'. $domain_path . $module . '_' . $tpl . $sufix
  );

  foreach my $result_template (@search_paths) {
    if($attr->{DEBUG}) {
      print $result_template . "\n";
    }

    if (-f $result_template) {
      if ($attr->{CHECK_ONLY}) {
        return 1;
      }
      else {
        return ($FORM{pdf}) ? $result_template : tpl_content($result_template) ;
      }
    }
  }

  if ($attr->{CHECK_ONLY}) {
    return 0;
  }

  if ($module) {
    $tpl = "modules/$module/templates/$tpl";
  }

  foreach my $prefix ('../', @INC) {
    my $realfilename = "$prefix/Abills/$tpl$sufix";

    if($attr->{DEBUG}) {
      print $realfilename . "\n";
    }

    if (-f $realfilename) {
      return ($FORM{pdf}) ? $realfilename : tpl_content($realfilename);
    }
  }

  if ($attr->{SUFIX}) {
    $tpl =~ /\/([a-z0-9\_\.\-]+)$/i;
    $tpl = $1;
    $tpl =~ s/_$attr->{SUFIX}$//;
    delete $attr->{SUFIX};
    goto start;
  }

  return "No such module template [$tpl]\n";
}

#**********************************************************
=head2 tpl_content($filename, $attr)

=cut
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';

  if(! %lang) {
    %lang = ();
  }

  open(my $fh, '<', $filename) || die "Can't open tpl file '$filename' $!";
    while (<$fh>) {
      if (/\$/) {
        my $res = $_;
        if($res) {
          $res =~ s/\_\{(\w+)\}\_/$lang{$1}/sg;
          $res =~ s/\{secretkey\}//g;
          $res =~ s/\{dbpasswd\}//g;
          $res = eval " \"$res\" " if($res !~ /\`/);
          $tpl_content .= $res || q{};
        }
      }
      else {
        # Old
        s/\_\{(\w+)\}\_/$lang{$1}/sg;
        $tpl_content .= $_;
#        # New check speed
#        my $row = $_;
#        if ($row =~ /\_\{(\w+)\}\_/sg) {
#          my $text = $1;
#          if($lang{$text}) {
#            $row =~ s/\_\{(\w+)\}\_/$lang{$text}/sg;
#          }
#          else {
#            $row =~ s/\_\{(\w+)\}\_/$text/sg;
#          }
#        }
#        $tpl_content .= $row;
      }
    }
  close($fh);

  return $tpl_content;
}

#**********************************************************
=head2 templates($tpl_name) - Show template

  Arguments:
    $tpl_name

  Return:
    tpl content

=cut
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

  if(! $conf{base_dir}) {
    $conf{base_dir} = '/usr/abills/';
  }

  my @search_paths = (
    #Lang tpls
    $Bin . "/../../Abills/templates/" . '_' . "$tpl_name" . '.tpl',
    $Bin . "/../Abills/templates/_$tpl_name" . "_$html->{language}.tpl",
    #$Bin . "/../../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl",
    #$Bin . "/../Abills/main_tpls/$tpl_name" . "_$html->{language}.tpl",
    #Main tpl
    $Bin . "/../Abills/templates/_$tpl_name" . ".tpl",
    $Bin . "/../../Abills/main_tpls/$tpl_name" . ".tpl",
    $Bin . "/../Abills/main_tpls/$tpl_name" . ".tpl",
    $conf{base_dir} . "/Abills/main_tpls/$tpl_name" . ".tpl",
    $conf{base_dir} . "/Abills/templates/$tpl_name" . ".tpl",
  );

  if ($admin->{DOMAIN_ID}) {
    $domain_path = "$admin->{DOMAIN_ID}/";
    @search_paths = (
      $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
      $Bin . "/../Abills/templates/$domain_path" . '_' . "$tpl_name" . "_$html->{language}.tpl",
      $Bin . "/../../Abills/templates/$domain_path" . '_' . "$tpl_name" . '.tpl',
      $Bin . "/../Abills/templates/$domain_path" . '_' . "$tpl_name" . ".tpl",
      @search_paths
    );
  }

  #Nas path
  if ($FORM{NAS_GID} && -f $Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl") {
    return tpl_content($Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . "_$html->{language}.tpl");
  }
  elsif ($FORM{NAS_GID} && -f $Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl") {
    return tpl_content($Bin . "/../Abills/templates/$domain_path" . '/' . $FORM{NAS_GID} . '/' . "_$tpl_name" . ".tpl");
  }
  else {
    foreach my $tpl ( @search_paths ) {
      if (-f $tpl) {
        return tpl_content($tpl);
      }
    }
  }

  return "No such template [$tpl_name]";
}

1
