=head1 NAME

 huawei snmp monitoring and managment

=cut

use strict;
use warnings;
use Abills::Base qw(in_array _bp int2byte load_pmodule check_time gen_time);
use Abills::Filters qw(bin2hex bin2mac);

our (
  $html,
  %lang,
  %html_color
);

my $Telnet;

#**********************************************************
=head2 _huawei_get_ports($attr) - Get OLT ports

=cut
#**********************************************************
sub _huawei_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    PORT_INFO => 'PORT_NAME,PORT_DESCR,PORT_STATUS,PORT_SPEED,PORT_IN,PORT_OUT,PORT_TYPE,PORT_ALIAS,PORT_NAME',
  });

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1|250$/ && $ports_info->{$key}{PORT_NAME} =~ /(.PON)/) {
      my $type = lc($1);
      my $branch = decode_port($key);
      $ports_info->{$key}{BRANCH} = $branch;
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return \%{$ports_info};
}

#**********************************************************
=head2 _huawei_onu_list($port_list, $attr) -

  Arguments:
    $port_list
    $attr
      DEBUG
      SNMP_COMMUNITY
      VERSION

  Results:

=cut
#**********************************************************
sub _huawei_onu_list {
  my ($port_list, $attr) = @_;

  my @all_rows = ();
  my $debug = $attr->{DEBUG} || 0;
  delete($attr->{DEBUG});
  my $ports_info = equipment_test({
    %{$attr},
    PORT_INFO => 'PORT_STATUS',
  });
  print "SNMP VERSION: $attr->{VERSION}, SNMP_COMMUNITY: $attr->{SNMP_COMMUNITY}\n" if ($debug > 2);

  foreach my $snmp_id (keys %{$port_list}) {
    my $type = $port_list->{$snmp_id}{PON_TYPE};
    my %total_info = ();
    my $snmp = _huawei({ TYPE => $type });
    my @cols = ('PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT');
    print "-------------------------------------\n" . uc($port_list->{$snmp_id}{PON_TYPE}) . $port_list->{$snmp_id}{BRANCH} . "\n" if ($debug > 2);
    my $port_begin_time = 0;
    $port_begin_time = check_time() if ($debug > 2);

    if (!defined($ports_info->{$snmp_id}->{PORT_STATUS}) || $ports_info->{$snmp_id}->{PORT_STATUS} != 1) {
      print "Port is not online\n" if ($debug > 2);
      next;
    }

    foreach my $oid_name (keys %{$snmp}) {
      if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info') {
        next;
      }

      push @cols, $oid_name;
      my $oid_begin_time = 0;
      $oid_begin_time = check_time() if ($debug > 2);
      my $oid = $snmp->{$oid_name}->{OIDS};

      if (!$oid) {
        next;
      }

      if ($debug > 2) {
        print "OID: $oid_name -- " . ($snmp->{$oid_name}->{NAME} || '') . " -- " . ($snmp->{$oid_name}->{OIDS} || '')
          . 'SNMP_ID:' . $snmp_id;
      }

      my $values = snmp_get({
        %{$attr},
        WALK    => 1,
        OID     => $oid . '.' . $snmp_id,
        TIMEOUT => 25
      });
      print " " . gen_time($oid_begin_time) . "\n" if ($debug > 2);
      foreach my $line (@{$values}) {
        next if (!$line);
        #print "$line\n";
        my ($onu_id, $oid_value) = split(/:/, $line, 2);
        if ($debug > 3) {
          print $oid . '->' . "$onu_id, $oid_value \n";
        }
        my $function = $snmp->{$oid_name}->{PARSER};
        if ($function && defined(&{$function})) {
          ($oid_value) = &{\&$function}($oid_value);
        }
        $total_info{$oid_name}{$snmp_id . '.' . $onu_id} = $oid_value;
      }
    }
    my $onu_count = 0;
    foreach my $key (keys %{$total_info{ONU_STATUS}}) {
      my %onu_info = ();
      $onu_count++;
      my ($branch, $onu_id) = split(/\./, $key, 2);
      for (my $i = 0; $i <= $#cols; $i++) {
        my $value = '';
        my $oid_name = $cols[$i];
        if ($oid_name eq 'ONU_ID') {
          $value = $onu_id;
        }
        elsif ($oid_name eq 'PORT_ID') {
          $value = $port_list->{$snmp_id}->{ID};
        }
        elsif ($oid_name eq 'PON_TYPE') {
          $value = $type;
        }
        elsif ($oid_name eq 'ONU_DHCP_PORT') {
          $value = decode_port($branch) . ':' . $onu_id;
        }
        elsif ($oid_name eq 'ONU_SNMP_ID') {
          $value = $key;
        }
        else {
          $value = $total_info{$cols[$i]}{$key};
        }
        $onu_info{$oid_name} = $value;
      }
      push @all_rows, { %onu_info };
    }
    print "ONU_COUNT: " . $onu_count . "\n" . gen_time($port_begin_time) . "\n" if ($debug > 2);
  }

  return \@all_rows;
}

#**********************************************************
=head2 _huawei_unregister($attr);

  Arguments:
    $attr

  Returns;
    \@unregister

=cut
#**********************************************************
sub _huawei_unregister {
  my ($attr) = @_;

  my @unregister = ();
  my @types = ('epon', 'gpon');

  foreach my $pon_type (@types) {
    my $snmp = _huawei({ TYPE => $pon_type });
    my $unreg_result;
    if($pon_type eq 'epon') {
      $unreg_result = snmp_get({
        %{$attr},
        WALK   => 1,
        OID    => $snmp->{unregister}->{UNREGISTER}->{OIDS},
        #TIMEOUT => 8,
        SILENT => 1,
        DEBUG  => $attr->{DEBUG} || 1
      });

      my %unreg_info = (
        2  => 'mac_serial',
        3  => 'info',
        #    4  => 'x4',
        #    5  => 'x5',
        6  => 'register',
        #    7  => 'x7',
        #    8  => 'x8',
        9  => 'vendor',
        10 => 'firnware',
        11 => 'version',
        #    12 => 'x12',
      );

      my %unregister_info = ();
      foreach my $line (@$unreg_result) {
        next if (!$line);
        my ($id, $value) = split(/:/, $line || q{});
        my ($type, $snmp_port_id, undef) = split(/\./, $id || q{});

        next if (!$unreg_info{$type});

        if ($unreg_info{$type} eq 'mac_serial') {
          $value = bin2mac($value);
        }

        $unregister_info{$snmp_port_id}->{$unreg_info{$type}} = $value;
        $unregister_info{$snmp_port_id}->{'branch'}     = decode_port($snmp_port_id);
        $unregister_info{$snmp_port_id}->{'branch_num'} = $snmp_port_id;
        $unregister_info{$snmp_port_id}->{'pon_type'}   = $pon_type;
      }

      push @unregister, values %unregister_info;

      next;
    }

    if($snmp->{unregister}->{'MAC/SERIAL'}->{OIDS}) {
      $unreg_result = snmp_get({
        %{$attr},
        WALK   => 1,
        OID    => $snmp->{unregister}->{'MAC/SERIAL'}->{OIDS},
        #TIMEOUT => 8,
        SILENT => 1
      });
    }

    foreach my $line (@$unreg_result) {
      my ($id, $mac_bin) = split(/:/, $line);
      my ($snmp_port_id, $onu_id) = split(/\./, $id, 2);
      my $branch  = decode_port($snmp_port_id);
      my $equipment_id;

      if ($snmp->{unregister}->{'EQUIPMENT_ID'}) {
        $equipment_id = snmp_get({
          %{$attr},
          OID    => "$snmp->{unregister}->{'EQUIPMENT_ID'}->{OIDS}.$id",
          #TIMEOUT => 8,
          SILENT => 1
        });
      };

      my $vendor;
      if ($pon_type eq 'gpon') {
        $vendor = bin2hex($mac_bin);
        $vendor =~ s/[A-F0-9]{8}$//g;
        $vendor = pack 'H*', $vendor;
      }

      $equipment_id =~ s/[^a-zA-Z0-9-_]//g;

      if ($vendor eq 'HWTC') {
        $equipment_id = "HG8$equipment_id" if ($equipment_id =~ /^\d{3}/);
      }
      elsif ($vendor eq 'ALCL') {
        $equipment_id =~ s/_//g;
      }

      push @unregister, {
        type         => $pon_type,
        pon_type     => $pon_type,
        branch       => $branch,
        branch_num   => $snmp_port_id,
        mac_serial   => bin2hex($mac_bin),
        equipment_id => $equipment_id,
        vendor       => $vendor
      }
    }
  }

  return \@unregister;
}

#**********************************************************
=head2 _huawei_delete_onu($attr)

=cut
#**********************************************************
sub _huawei_delete_onu {
}

#**********************************************************
=head2 _huawei_unregister_form($attr);

  Arguments:
    $attr
      PON_TYPE

  Returns;

=cut
#**********************************************************
sub _huawei_unregister_form {
  my ($attr) = @_;

  my $pon_type = $attr->{PON_TYPE} || $FORM{TYPE} || q{};
  my $snmp = _huawei({ TYPE => $pon_type });

  $attr->{ACTION}     = 'onu_registration';
  $attr->{ACTION_LNG} = $lang{ADD};
  $attr->{SNMP_TPL}   = $attr->{NAS_INFO}->{SNMP_TPL};

  my $vlan_hash = get_vlans($attr);
  my %vlans = ();
  foreach my $vlan_id (keys %{$vlan_hash}) {
    $vlans{ $vlan_id } = "Vlan$vlan_id ($vlan_hash->{ $vlan_id }->{NAME})";
  }

  my @line_profiles = ();
  my @srv_profiles = ();
  my @profiles = ('LINE_PROFILES', 'SRV_PROFILES');
  foreach my $type (@profiles) {
    my $oid = $snmp->{profiles}->{$type}->{OIDS};

    my $profile_list = snmp_get({
      %{$attr},
      WALK   => 1,
      OID    => $oid,
      #TIMEOUT => 8,
      SILENT => 1
    });

    foreach my $name (@$profile_list) {
      if ($type eq $profiles[0]) {
        push @line_profiles, huawei_parse_profile_name($name);
      }
      elsif ($type eq $profiles[1]) {
        push @srv_profiles, huawei_parse_profile_name($name);
      }
    }
  }

  $attr->{INTERNET_VLAN_SEL} = $html->form_select('VLAN_ID', {
    SELECTED    => $attr->{DEF_VLAN} || '',
    SEL_OPTIONS => { '' => '--' },
    SEL_HASH    => \%vlans,
    NO_ID       => 1
  });

  $attr->{TR_069_VLAN_SEL} = $html->form_select('TR_069_VLAN_ID', {
    SELECTED    => $attr->{TR_069_VLAN} || '',
    SEL_OPTIONS => { '' => '--' },
    SEL_HASH    => \%vlans,
    NO_ID       => 1
  });

  $attr->{IPTV_VLAN_SEL} = $html->form_select('IPTV_VLAN_ID', {
    SELECTED    => $attr->{IPTV_VLAN} || '',
    SEL_OPTIONS => { '' => '--' },
    SEL_HASH    => \%vlans,
    NO_ID       => 1
  });

  my $default_line_profile = $conf{HUAWEI_LINE_PROFILE_NAME} || 'ONU';
  $attr->{DEF_LINE_PROFILE} = $default_line_profile;

  my $triple_line_profile = $conf{HUAWEI_TRIPLE_LINE_PROFILE_NAME} || 'TRIPLE-PLAY';
  $attr->{TRIPLE_LINE_PROFILE} = $triple_line_profile;

  if ($conf{HUAWEI_TRIPLE_PLAY_ONU} && in_array($attr->{EQUIPMENT_ID}, $conf{HUAWEI_TRIPLE_PLAY_ONU})) {
    $default_line_profile = $triple_line_profile;
  }

  $attr->{LINE_PROFILE_SEL} = $html->form_select('LINE_PROFILE', {
    SELECTED    => $default_line_profile,
    SEL_OPTIONS => { '' => '--' },
    SEL_ARRAY   => \@line_profiles,
  });

  $attr->{SRV_PROFILE_SEL} = $html->form_select('SRV_PROFILE', {
    SELECTED    => $conf{HUAWEI_SRV_PROFILE_NAME} || 'ALL',
    SEL_OPTIONS => { '' => '--' },
    SEL_ARRAY   => \@srv_profiles,
  });

  $attr->{TYPE} = $pon_type;

  if ($pon_type eq 'gpon') {
    $attr->{UC_TYPE} = uc($pon_type);
    $html->tpl_show(_include('equipment_registred_onu', 'Equipment'), { %$attr, %FORM });
  }
  elsif ($pon_type eq 'epon') {
    $attr->{SHOW_VLANS}=1;
    $html->tpl_show(_include('equipment_registred_onu', 'Equipment'), $attr);
  }

  return 1;
}

#**********************************************************
=head2 _huawei_prase_line_profile($attr) 

  Arguments:
    $attr
      TYPE - PON type gpon/epon
      LINE_PROFILE

  Returns;
    \%line_profile

=cut
#**********************************************************
sub _huawei_prase_line_profile {
  my ($attr) = @_;

  my %line_profile = ();

  my $snmp = _huawei({ TYPE => $attr->{TYPE} });
  my $oid = $snmp->{profiles}->{'LINE_PROFILE_VLANS'}->{OIDS};

  if ($attr->{TYPE} eq 'gpon') {
    $oid .= '.' . huawei_make_profile_name($attr->{LINE_PROFILE});
  }

  my $data = snmp_get({
    %{$attr},
    WALK   => 1,
    OID    => $oid,
    #TIMEOUT => 8,
    SILENT => 1
  });

  foreach my $line (@$data) {
    my ($gem_maping, $vlan) = split(':', $line);
    my ($gem, undef) = split('\.', $gem_maping);
    push @{$line_profile{$gem}}, $vlan;
  }

  return \%line_profile;
}

#**********************************************************
=head2 _huawei($attr) - Snmp recovery

  Arguments:
    $attr
      TYPE

  http://pastebin.com/wjj68SUX

=cut
#**********************************************************
sub _huawei {
  my ($attr) = @_;

  my %snmp = (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.53.1.3',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.15',
        PARSER => ''
      },
      'ONU_TX_POWER'   => {
        NAME   => 'ONU_TX_POWER',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.4',
        PARSER => '_huawei_convert_power'
      }, #tx_power = tx_power * 0.01;
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.5',
        PARSER => '_huawei_convert_power'
      }, #tx_power = tx_power * 0.01;
      'OLT_RX_POWER'   => {
        NAME   => 'OLT_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.1',
        PARSER => '_huawei_convert_olt_power'
      }, #olt_rx_power = olt_rx_power * 0.01 - 100;
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.53.1.9',
        PARSER => '_huawei_convert_desc'
      },
      'ONU_IN_BYTE'    => {
        NAME   => 'PORT_IN',
        OIDS   => '',
        PARSER => ''
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'PORT_OUT',
        OIDS   => '',
        PARSER => ''
      },
      'TEMPERATURE'    => {
        NAME   => 'TEMPERATURE',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.2',
        PARSER => '_huawei_convert_temperature'
      },
      'SRV_PROFILE'    => {
        NAME   => 'ont-srvprofile',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.53.1.6',
      },
      'LINE_PROFILE'   => {
        NAME   => 'ont-lineprofile',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.53.1.7',
      },
      'reset'          => {
        NAME   => '',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.2',
        PARSER => ''
      },
      main_onu_info    => {
        'HARD_VERSION' => {
          NAME   => 'Hhard_Version',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.55.1.4',
          PARSER => ''
        },
        'SOFT_VERSION' => {
          NAME   => 'Soft_Version',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.55.1.5',
          PARSER => ''
        },
        'VOLTAGE'      => {
          NAME   => 'VOLTAGE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.104.1.6',
          PARSER => '_huawei_convert_voltage'
        },
        'DISTANCE'     => {
          NAME   => 'DISTANCE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.57.1.19',
          PARSER => '_huawei_convert_distance'
        },
      },
      unregister       => {
        'MAC/SERIAL' => {
          NAME   => 'MAC/SERIAL',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.58.1.2',
          PARSER => 'bin2mac',
          WALK   => '1'
        },
        UNREGISTER => {
          NAME   => 'UNREGISTER',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.58.1',
          TYPE   => 'epon',
          PARSER => '',
          WALK   => '1'
        }
      },
      profiles         => {
        'LINE_PROFILES'      => {
          NAME   => 'LINE_PROFILES',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.41.1.2',
          PARSER => '',
          WALK   => '1'
        },
        'SRV_PROFILES'       => {
          NAME   => 'SRV_PROFILES',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.43.1.2',
          PARSER => '',
          WALK   => '1'
        },
        'LINE_PROFILE_VLANS' => {
          NAME   => 'LINE_PROFILE_VLANS',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.64.1.8',
          PARSER => '',
          WALK   => '1'
        }
      }
    },
    gpon => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.3',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.15',
      },
      #     'ONU_TX_POWER' => {
      #       NAME   => 'ONU_TX_POWER',
      #       OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.3',
      #       PARSER => '_huawei_convert_power'
      #     }, # tx_power = tx_power * 0.01;
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4',
        PARSER => '_huawei_convert_power'
      }, # rx_power = rx_power * 0.01;
      'OLT_RX_POWER'   => {
        NAME   => 'OLT_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.6',
        PARSER => '_huawei_convert_olt_power'
      }, # olt_rx_power = olt_rx_power * 0.01 - 100;
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.9',
        PARSER => '_huawei_convert_desc'
      },
      'ONU_IN_BYTE'    => {
        NAME   => 'PORT_IN',
        OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.4.23.1.4',
        PARSER => ''
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'PORT_OUT',
        OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.4.23.1.3',
      },
      'LINE_PROFILE'   => {
        NAME   => 'ont-lineprofile',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.7',
      },
      'SRV_PROFILE'    => {
        NAME   => 'ont-srvprofile',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.43.1.8',
      },
      'reset'          => {
        NAME   => '',
        OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.2',
      },
      main_onu_info    => {
        'VERSION_ID'       => {
          NAME   => 'Version_ID',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.1',
        },
        'VENDOR_ID'        => {
          NAME   => 'Vendor_ID',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.5',
          PARSER => ''
        },
        'EQUIPMENT_ID'     => {
          NAME   => 'Equipment_ID',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.45.1.4',
          PARSER => ''
        },
        'VOLTAGE'          => {
          NAME   => 'VOLTAGE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.5',
          PARSER => '_huawei_convert_voltage'
        },
        'DISTANCE'         => {
          NAME   => 'DISTANCE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.46.1.20',
          PARSER => '_huawei_convert_distance'
        },
        'ETH_DUPLEX'       => {
          NAME   => 'ETH_DUPLEX',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.3',
          PARSER => '_huawei_convert_duplex',
          WALK   => '1'
        },
        'ETH_SPEED'        => {
          NAME   => 'ETH_SPEED',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.4',
          PARSER => '_huawei_convert_speed',
          WALK   => '1'
        },
        'ETH_ADMIN_STATE'  => {
          NAME   => 'ETH_ADMIN_STATE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.5',
          PARSER => '_huawei_convert_admin_state',
          WALK   => '1'
        },
        'ONU_PORTS_STATUS' => {
          NAME   => 'ONU_PORTS_STATUS',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.22',
          PARSER => '_huawei_convert_state',
          WALK   => '1'
        },
        'VLAN'             => {
          NAME   => 'VLAN',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.62.1.7',
          PARSER => '_huawei_convert_eth_vlan',
          WALK   => '1'
        },
        'TEMPERATURE'      => {
          NAME   => 'TEMPERATURE',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.1',
          PARSER => '_huawei_convert_temperature'
        },
        'ONU_TX_POWER'     => {
          NAME   => 'ONU_TX_POWER',
          OIDS   => '.1.3.6.1.4.1.2011.6.128.1.1.2.51.1.3',
          PARSER => '_huawei_convert_power'
        } # tx_power = tx_power * 0.01;
      },
      unregister       => {
        'MAC/SERIAL'   => {
          NAME   => 'MAC/SERIAL',
          # GPON
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.48.1.2',
          #OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.52.1.2',
          WALK   => '1'
        },
        'EQUIPMENT_ID' => {
          NAME   => 'EQUIPMENT_ID',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.2.48.1.7',
          PARSER => '',
          WALK   => '1'
        }
      },
      profiles         => {
        'LINE_PROFILES'      => {
          NAME   => 'LINE_PROFILES',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.61.1.2',
          PARSER => '',
          WALK   => '1'
        },
        'SRV_PROFILES'       => {
          NAME   => 'SRV_PROFILES',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.65.1.2',
          PARSER => '',
          WALK   => '1'
        },
        'LINE_PROFILE_VLANS' => {
          NAME   => 'LINE_PROFILE_VLANS',
          OIDS   => '1.3.6.1.4.1.2011.6.128.1.1.3.64.1.8',
          PARSER => '',
          WALK   => '1'
        }
      }
    }
  );

  # 1.3.6.1.4.1.2011.6.128.1.1.2.46.1.21 - ONU MAC COUNT
  #

  #  Получить все сервис-порты: 1.3.6.1.4.1.2011.5.14.3.1.1.1
  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _huawei_onu_status();

=cut
#**********************************************************
sub _huawei_onu_status {

  my %status = (
    1 => 'Online:text-green',
    2 => 'Offline:text-red',
  );

  return \%status;
}

#**********************************************************
=head2 decode_port($dec) - Decode onu int

  Arguments:
    $dec

  Returns:
    deparsing string

=cut
#**********************************************************
sub decode_port {
  my ($fsp, $type) = @_;
  $type //= '';
  $fsp =~ s/\.\d+//;
  my $frame = -1;
  my $slot = -1;
  my $port = -1;

  if ($type eq 'eth') {
    $frame = ($fsp & 0x7C0000) >> 18;
    $slot = ($fsp & 0x3E000) >> 13;
    $port = ($fsp & 0x1FC0) >> 6;
  }
  else {
    $frame = ($fsp & 0x7C0000) >> 18;
    $slot = ($fsp & 0x3E000) >> 13;
    $port = ($fsp & 0x1F00) >> 8;
  }

  return $frame . '/' . $slot . '/' . $port;
}

#**********************************************************
=head2 encode_port($frame, $slot, $port, $type) - Encode port

  Arguments:
    $frame, $slot, $port, $type

  Returns:
    snmp port index

=cut
#**********************************************************
sub encode_port {
  my ($frame, $slot, $port, $type) = @_;
  my $fsp = 0;

  if ($type =~ /pon/) {
    $fsp |= 0xFA000000;
    $fsp |= ($frame & 0x1F) << 18;
    $fsp |= ($slot & 0x1F) << 13;
    $fsp |= ($port & 0x1F) << 8;
  }
  elsif ($type eq 'eth') {
    $fsp |= 0x0E000000;
    $fsp |= ($frame & 0x1F) << 18;
    $fsp |= ($slot & 0x1F) << 13;
    $fsp |= ($port & 0x7F) << 6;
  }

  return $fsp;
}

#**********************************************************
=head2 _huawei_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _huawei_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    $oid = '1.3.6.1.2.1.31.1.1.1.18.' . $attr->{PORT};
  }

  snmp_set({
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return 1;
}

#**********************************************************
=head2 _huawei_get_service_ports_2($attr) - Get OLT service ports

  Arguments:
    $attr
      ONU_SNMP_ID
      GET_ONU_SERVICE_PORT

=cut
#**********************************************************
sub _huawei_get_service_ports_2 {
  my ($attr) = @_;

  my %snmp_oids = (
    FRAME         => '.1.3.6.1.4.1.2011.5.14.5.2.1.2',
    SLOT          => '.1.3.6.1.4.1.2011.5.14.5.2.1.3',
    PORT          => '.1.3.6.1.4.1.2011.5.14.5.2.1.4',
    ONU_ID        => '.1.3.6.1.4.1.2011.5.14.5.2.1.5',
    GEMPORT_ETH   => '.1.3.6.1.4.1.2011.5.14.5.2.1.6',
    TYPE          => '.1.3.6.1.4.1.2011.5.14.5.2.1.7',
    S_VLAN        => '.1.3.6.1.4.1.2011.5.14.5.2.1.8',
    MULTISERVICE  => '.1.3.6.1.4.1.2011.5.14.5.2.1.11',
    C_VLAN        => '.1.3.6.1.4.1.2011.5.14.5.2.1.12',
    TAG_TRANSFORM => '.1.3.6.1.4.1.2011.5.14.5.2.1.18'
  );
  my @basic_oids = ('FRAME', 'SLOT', 'PORT', 'ONU_ID');
  my %service_ports_info = ();

  foreach my $type (keys %snmp_oids) {
    next if ($attr->{GET_ONU_SERVICE_PORT} && !in_array($type, \@basic_oids));
    my $oid = $snmp_oids{$type};
    my $sp_info = snmp_get({
      %{$attr},
      OID  => $oid,
      WALK => 1,
    });

    foreach my $line (@{$sp_info}) {
      next if (!$line);
      my ($sp_id, $data) = split(/:/, $line, 2);
      $service_ports_info{$sp_id}{$type} = $data;
    }
  }
  return %service_ports_info if (!$attr->{ONU_SNMP_ID});
  my @service_ports = ();
  my ($snmp_port_id, $onu_id) = split(/\./, $attr->{ONU_SNMP_ID}, 2);
  my $branch = decode_port($snmp_port_id);
  my $onu = $branch . ':' . $onu_id;

  my %type = (
    1  => 'pvc',
    2  => 'eth',
    3  => 'vdsl',
    4  => 'gpon',
    5  => 'shdsl',
    6  => 'epon',
    7  => 'vcl',
    8  => 'adsl',
    9  => 'gpon', #gponOntEth
    10 => 'epon', #eponOntEth
    11 => 'gpon', #gponOntIphost
    12 => 'epon', #eponOntIphost
    14 => 'gpon'
  ); #?

  my %multi_srv_type = (
    1 => 'user-vlan',
    2 => 'user-encap',
    3 => 'user-8021p'
  );

  my %tag_transform = (
    0 => 'add',
    1 => 'transparent',
    2 => 'translate',
    3 => 'translateAndAdd',
    4 => 'addDouble',
    5 => 'translateDouble',
    6 => 'translateAndRemove',
    7 => 'remove',
    8 => 'removeDouble',
  );

  foreach my $sp_id (keys %service_ports_info) {
    my $sp_data = $service_ports_info{$sp_id};
    if ($onu && $onu eq $sp_data->{FRAME} . '/' . $sp_data->{SLOT} . '/' . $sp_data->{PORT} . ':' . $sp_data->{ONU_ID}) {
      if ($attr->{GET_ONU_SERVICE_PORT}) {
        push @service_ports, $sp_id;
      }
      else {
        unshift @service_ports, [ 'Service port', "service-port $sp_id vlan $sp_data->{S_VLAN} $type{ $sp_data->{TYPE} } $branch ont $onu_id "
          . (($sp_data->{TYPE} eq '4') ? "gemport $sp_data->{GEMPORT_ETH}" : '')
          . (($sp_data->{TYPE} > '8') ? "eth $sp_data->{GEMPORT_ETH}" : '')
          . " multi-service $multi_srv_type{ $sp_data->{MULTISERVICE} } $sp_data->{C_VLAN}"
          . " tag-transform $tag_transform{ $sp_data->{TAG_TRANSFORM} }" ];
      }
    }
  }

  return @service_ports;
}

#**********************************************************
=head2 _huawei_get_service_ports($attr) - Get OLT service ports

  Arguments:
    $attr
      ONU_SNMP_ID

=cut
#**********************************************************
sub _huawei_get_service_ports {
  my ($attr) = @_;

  my $onu_type = $attr->{ONU_TYPE} || $attr->{TYPE};
  if (_huawei_telnet_open($attr)) {
    my $data = '';
    $data = _huawei_telnet_cmd("display service-port port $attr->{BRANCH} ont $attr->{ONU_ID} sort-by vlan");
    $Telnet->close();
    my @list = split('\n', $data || q{});
    my @service_ports = ();
    foreach my $line (@list) {
      if ($onu_type eq 'gpon') {
        if ($line =~ /(\d+)\s+(\d+)\s+common\s+gpon\s+\d+\/\d+\s*\/\d+\s+\d+\s+(\d+)\s+vlan\s+(\d+)/) {
          push @service_ports, [ 'Service port', "service-port $1 vlan $2 $onu_type $attr->{BRANCH} ont $attr->{ONU_ID} "
            . "gemport $3 multi-service user-vlan $4" ];
        }
      }
    }
    return @service_ports;
  }

  return [];
}

#**********************************************************
=head2 _huawei_get_free_id($attr)

   Arguments:
     $attr
       OID                - oid
       SNMP_COMMUNITY     - Port id
       MAX_ID             - Maximal id (default 128)

=cut
#**********************************************************
sub _huawei_get_free_id {
  my ($attr) = @_;

  my $max_id = $attr->{MAX_ID} || '128';
  my %used_ids = ();
  my $values = snmp_get({
    %{$attr},
    WALK    => 1,
    OID     => $attr->{OID},
    TIMEOUT => 25
  });

  foreach my $line (@{$values}) {
    my ($id, undef) = split(/:/, $line, 2);
    $used_ids{$id} = 1;
  }

  my $id = "-1";
  for (my $i = 0; $i <= $max_id; $i++) {
    if (!$used_ids{$i}) {
      $id = $i;
      last;
    }
  }

  return $id;
}

#**********************************************************
=head2 _huawei_convert_power($power);

=cut
#**********************************************************
sub _huawei_convert_power {
  my ($power) = @_;

  $power //= 0;

  if (2147483647 == $power) {
    $power = '';
  }
  else {
    $power = $power * 0.01;
    $power = sprintf("%.2f", $power);
  }

  return $power;
}

#**********************************************************
=head2 _huawei_convert_olt_power($olt_power);

=cut
#**********************************************************
sub _huawei_convert_olt_power {
  my ($olt_power) = @_;

  $olt_power //= 0;

  if (2147483647 == $olt_power) {
    $olt_power = '';
  }
  else {
    $olt_power = $olt_power * 0.01 - 100;
    $olt_power = sprintf("%.2f", $olt_power);
  }

  return $olt_power;
}
#**********************************************************
=head2 _huawei_convert_desc();

=cut
#**********************************************************
sub _huawei_convert_desc {
  my ($desc) = @_;

  $desc //= q{};

  if ($desc eq 'ONT_NO_DESCRIPTION') {
    $desc = '';
  }

  return $desc;
}
#**********************************************************
=head2 _huawei_convert_temperature();

=cut
#**********************************************************
sub _huawei_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;

  if (2147483647 == $temperature) {
    $temperature = '';
  }

  return $temperature;
}
#**********************************************************
=head2 _huawei_convert_voltage();

=cut
#**********************************************************
sub _huawei_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;

  if (2147483647 == $voltage) {
    $voltage = '';
  }
  else {
    $voltage = $voltage * 0.001;
    $voltage .= ' V'
  }
  return $voltage;
}

#**********************************************************
=head2 _huawei_convert_distance();

=cut
#**********************************************************
sub _huawei_convert_distance {
  my ($distance) = @_;

  $distance //= -1;

  if ($distance eq '-1') {
    $distance = '';
  }
  else {
    $distance = $distance * 0.001;
    $distance .= ' km';
  }
  return $distance;
}

#**********************************************************
=head2 _huawei_convert_duplex($data);

=cut
#**********************************************************
sub _huawei_convert_duplex {
  my ($data) = @_;

  my ($oid, $index) = split(/:/, $data, 2);
  my $port = $oid;
  my $duplex = 'Unknown';

  my %duplex_hash = (
    3 => 'Auto',
    4 => 'Half',
    5 => 'Full'
  );

  if ($duplex_hash{ $index }) {
    $duplex = $duplex_hash{ $index };
  }

  return($port, $duplex);
}
#**********************************************************
=head2 _huawei_convert_speed();

=cut
#**********************************************************
sub _huawei_convert_speed {
  my ($data) = @_;
  my ($oid, $index) = split(/:/, $data, 2);
  my $port = "$oid";
  my $speed = 'Unknown';
  my %speed_hash = (
    4 => 'Auto',
    5 => '10Mb/s',
    6 => '100Mb/s',
    7 => '1Gb/s'
  );

  if ($speed_hash{ $index }) {
    $speed = $speed_hash{ $index };
  }

  return($port, $speed);
}


#**********************************************************
=head2 _huawei_convert_admin_state();

=cut
#**********************************************************
sub _huawei_convert_admin_state {
  my ($data) = @_;
  my ($oid, $index) = split(/:/, $data, 2);
  my $port = "$oid";
  my $state = 'Unknown';
  my %state_hash = (
    1 => 'Enable',
    2 => 'Disable',
  );
  if ($state_hash{ $index }) {
    $state = $state_hash{ $index };
  }
  return($port, $state);
}

#**********************************************************
=head2 _huawei_convert_state($data);

=cut
#**********************************************************
sub _huawei_convert_state {
  my ($data) = @_;

  my ($port, $state_id) = split(/:/, $data, 2);

  my $state = 0;
  my %state_hash = (
    1 => 1, #'Up',
    2 => 2  #'Down',
  );

  if ($state_hash{ $state_id }) {
    $state = $state_hash{ $state_id };
  }

  return($port, $state);
}

#**********************************************************
=head2 _huawei_convert_eth_vlan();

=cut
#**********************************************************
sub _huawei_convert_eth_vlan {
  my ($data) = @_;

  my ($port, $vlan) = split(/:/, $data, 2);

  return($port, $vlan);
}

#**********************************************************
=head2 _huawei_convert_cpu_usage();

=cut
#**********************************************************
sub _huawei_convert_cpu_usage {
  my ($data) = @_;

  my ($oid, $value) = split(/:/, $data, 2);
  my ($frame, $slot) = split(/\./, $oid, 2);
  $slot = "Slot " . $frame . "/" . $slot;
  if ($value eq '-1') {
    $value = '--';
  }
  else {
    my $color = q{};
    (undef, $color) = split(/:/, equipment_add_color($value)) if ($value =~ /\d+/);
    $color //= $html_color{green};
    $value = '<span style="background-color:' . $color . '" class="badge">' . $value . ' %</span>';
  }

  return($slot, $value);
}

#**********************************************************
=head2 _huawei_convert_info_temperature();

=cut
#**********************************************************
sub _huawei_convert_info_temperature {
  my ($data) = @_;
  my ($oid, $value) = split(/:/, $data, 2);
  my ($frame, $slot) = split(/\./, $oid, 2);
  $slot = "Slot " . $frame . "/" . $slot;
  if ($value eq '2147483647') {
    $value = '--';
  }
  else {
    my $color = q{};
    (undef, $color) = split(/:/, equipment_add_color($value)) if ($value =~ /\d+/);
    $color //= $html_color{green};
    $value = '<span style="background-color:' . $color . '" class="badge">' . $value . ' °C</span>';
  }
  return($slot, $value);
}

#**********************************************************
=head2 _huawei_convert_info_describe();

=cut
#**********************************************************
sub _huawei_convert_info {
  my ($data) = @_;
  my ($oid, $value) = split(/:/, $data, 2);
  my ($frame, $slot) = split(/\./, $oid, 2);
  $slot = "Slot " . $frame . "/" . $slot;
  return($slot, $value);
}

#**********************************************************
=head2 xpon_parse_profile_name

  Decode profile name from OID

  Arguments:
    $name - the part of OID with name

  Returns:
    profile name

=cut
#**********************************************************
sub huawei_parse_profile_name {
  my ($name) = @_;

  $name = pack('(C)*', split(/\./, $name || q{}));
  #
  # #Fixme
  # my $name1 = 'EponAll';
  # my @pro_hex = unpack('C*', $name1);
  # print "<br>$name1 --->". join('.', @pro_hex). '<---<br>';

  return $name;
}

#**********************************************************
=head2 huawei_make_profile_name

  Endcode a string to profile name for use in OID

  Arguments:
    $name - string

  Returns:
    a part of OID

=cut
#**********************************************************
sub huawei_make_profile_name {
  my ($name) = @_;

  my $length = length($name);
  my @name = unpack('(C)*', $name);
  $name = join(".", @name);
  $name = $length . '.' . $name;

  return $name;
}

#**********************************************************
=head2 _huawei_get_fdb($attr) - GET FDB by telnet

  Arguments:
    $attr

  Results:


=cut
#**********************************************************
sub _huawei_get_fdb {
  my ($attr) = @_;

  my %hash = ();
  if (_huawei_telnet_open($attr)) {
    my $data = _huawei_telnet_cmd("display mac-address all");
    $Telnet->close();
    #$data =~ s/\n/<br>/g;
    my @list = split("\n", $data || q{});
    my $port_types = ({ eth => 'ethernet', gpon => 'GPON ', epon => 'EPON ' });
    foreach my $line (@list) {
      #print "$line ||| <br>";
      if ($line =~ /([-0-9]+)\s+.+\s+([a-z]+)\s+([a-f0-9]{2})([a-f0-9]{2})\-([a-f0-9]{2})([a-f0-9]{2})\-([a-f0-9]{2})([a-f0-9]{2})\s+([a-z]+)\s+(\d+)\s+\/(\d+)\s+\/(\d+)\s+([-0-9]+)\s+([-0-9]+)\s+(\d+)/) {
        #print "$1 | $2 | $3 | $4 | $5 | $6 | $7 | $8 | $9 | $10 | $11 | $12 | $13 | $14 | $15 | <br>";
        my $mac = "$3:$4:$5:$6:$7:$8";
        my ($srv_port, $port_type, $frame, $slot, $port, $onu_id, $van_id) = ($1, $2, $10, $11, $12, $13, $15);
        my $key = $mac . '_' . $van_id;
        #        my $snmp_port_id = encode_port($port_type, $frame, $slot, $port);
        if ($attr->{FILTER}) {
          $attr->{FILTER} = lc($attr->{FILTER});
          if ($mac =~ m/($attr->{FILTER})/) {
            my $search = $1;
            $mac =~ s/$search/<b>$search<\/>/g;
          }
          else {
            next;
          }
        }
        $hash{$key}{1} = $mac;
        #$hash{$key}{2} = uc($port_type).' '.$port.(($onu_id =~ /\d+/) ? ":$onu_id" : "");
        $hash{$key}{2} = encode_port($frame, $slot, $port, $port_type) . (($onu_id =~ /\d+/) ? ".$onu_id" : "");
        $hash{$key}{4} = $van_id . (($srv_port =~ /\d+/) ? " ( SERVICE_PORT: $srv_port )" : "");
        $hash{$key}{5} = $port_types->{ $port_type } . $frame . '/' . $slot . '/' . $port . (($onu_id =~ /\d+/) ? ":$onu_id" : "");
      }
    }
  }

  return %hash;
}

#**********************************************************
=head2 _huawei_telnet_open($attr);

  Arguments:
    $attr
      NAS_INFO

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _huawei_telnet_open {
  my ($attr) = @_;

  my $load_data = load_pmodule('Net::Telnet', { SHOW_RETURN => 1 });
  if ($load_data) {
    print "$load_data";
    return 0;
  }

  if (!$attr->{NAS_INFO}->{NAS_MNG_IP_PORT}) {
    print "NAS_MNG_IP_PORT not defined";
    return 0;
  }

  my $user_name = $attr->{NAS_INFO}->{NAS_MNG_USER} || q{};
  my $password = $attr->{NAS_INFO}->{NAS_MNG_PASSWORD} || q{};

  $Telnet = Net::Telnet->new(
    Timeout => 20,
    Errmode => 'return'
  );

  my ($ip, $mng_port, undef) = split(/:/, $attr->{NAS_INFO}->{NAS_MNG_IP_PORT}, 3);
  my $port = $mng_port || 23;
  $Telnet->open(
    Host => $ip,
    Port => $port
  );

  if ($Telnet->errmsg) {
    print "Problem connecting to $ip, port: $port\n";
    return 0;
  }
  $Telnet->waitfor('/>>User name:/i');
  if ($Telnet->errmsg) {
    print ">Problem connecting to $ip, port: $port\n";
    return 0;
  }

  $Telnet->print($user_name);
  $Telnet->waitfor('/>>User password:/i');
  $Telnet->print($password);
  if ($Telnet->errmsg) {
    print "Telnet login or password incorrect\n";
    return 0;
  }
  $Telnet->print(" ") or print "ERROR USER OR PASS";;
  $Telnet->print(" ") or print "ERROR USER OR PASS";
  $Telnet->waitfor('/>/i') || print "ERROR USER OR PASS";
  $Telnet->print("enable");
  $Telnet->waitfor('/#/i');
  $Telnet->print("config");
  $Telnet->waitfor('/\(config\)#/i');
  if ($Telnet->errmsg) {
    print "Telnet login or password incorrect";
    return 0;
  }
  $Telnet->print("scroll");
  $Telnet->print(" ");
  $Telnet->waitfor('/#/i');

  return 1;
}

#**********************************************************
=head2 _huawei_telnet_cmd($cmd);

=cut
#**********************************************************
sub _huawei_telnet_cmd {
  my ($cmd) = @_;

  $Telnet->print($cmd);
  $Telnet->print(" ");
  my @data = $Telnet->waitfor('/#/');
  #$data[0] =~ s/\n/<br>/g;

  return $data[0];
}

1
