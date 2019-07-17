=head1 NAME

  BDCOM

=cut

use strict;
use warnings;
use Abills::Base qw(in_array);
use Abills::Filters qw(bin2mac _mac_former dec2hex);
our %lang;

#**********************************************************
=head2 _bdcom_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _bdcom_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    TIMEOUT   => 5,
    VERSION   => 2,
    PORT_INFO => 'PORT_NAME,PORT_TYPE,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT'
  });

  foreach my $key (keys %{$ports_info}) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^1$/ && $ports_info->{$key}{PORT_NAME} =~ /(.PON)(\d+\/\d+)$/) {
      my $type = lc($1);
      #my $branch = decode_port($key);
      $ports_info->{$key}{BRANCH} = $2;
      $ports_info->{$key}{PON_TYPE} = $type;
      $ports_info->{$key}{SNMP_ID} = $key;
      $ports_info->{$key}{BRANCH_DESC} = $ports_info->{$key}{PORT_DESCR};
    }
    else {
      delete($ports_info->{$key});
    }
  }

  return $ports_info;
}

#**********************************************************
=head2 _bdcom_onu_list($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

=cut
#**********************************************************
sub _bdcom_onu_list {
  my ($port_list, $attr) = @_;

  #my $cols = ['PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT'];
  my $debug = $attr->{DEBUG} || 0;
  my @all_rows = ();
  my %pon_types = ();
  my %port_ids = ();

  my $snmp_info = equipment_test({
    %{$attr},
    TIMEOUT  => 5,
    VERSION  => 2,
    TEST_OID => 'PORTS,UPTIME'
  });

  if (!$snmp_info->{UPTIME}) {
    print "$attr->{SNMP_COMMUNITY} Not response\n";
    return [];
  }

  my $ether_ports = $snmp_info->{PORTS};

  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.2.1.2.2.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$ports_descr || $#{$ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _bdcom({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }

    #    my $onu_status_list = snmp_get({ %$attr,
    #      WALK    => 1,
    #      OID     => $snmp->{ONU_STATUS}->{OIDS},
    #    });

    #    my %onu_cur_status = ();
    #    foreach my $line ( @$onu_status_list ) {
    #      my($port_index, $status)=split(/:/, $line);
    #      $onu_cur_status{$port_index}=$status;
    #    }

    #Get info
    my %onu_snmp_info = ();
    foreach my $oid_name (keys %{$snmp}) {
      if ($snmp->{$oid_name}->{OIDS}) {
        my $oid = $snmp->{$oid_name}->{OIDS};
        print ">> $oid\n" if ($debug > 3);
        my $result = snmp_get({
          %{$attr},
          OID     => $oid,
          VERSION => 2,
          WALK    => 1,
          SILENT  => 1
        });

        foreach my $line (@$result) {
          next if (!$line);
          my ($interface_index, $value) = split(/:/, $line, 2);
          my $function = $snmp->{$oid_name}->{PARSER};

          if (!defined($value)) {
            print ">> $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          $onu_snmp_info{$interface_index}{$oid_name} = $value;
        }
      }
    }

    foreach my $line (@$ports_descr) {
      next if (!$line);
      my ($interface_index, $type) = split(/:/, $line, 2);
      if ($type && $type =~ /(.+):(.+)/) {
        $type =~ /(\d+)\/(\d+):(\d+)/;
        my $device_index = $3;
        my $brench_index = $2;
        my %onu_info = ();

        if ($onu_snmp_info{$interface_index}) {
          %onu_info = %{$onu_snmp_info{$interface_index}};
        }

        $onu_info{PORT_ID} = $port_ids{$1 . '/' . $brench_index};
        $onu_info{ONU_ID} = $device_index;
        $onu_info{ONU_SNMP_ID} = $interface_index;
        $onu_info{PON_TYPE} = $pon_type;

        my $port_id;

        # option 82 - hn-type
        if ($conf{DHCP_O82_BDCOM_TYPE} && $conf{DHCP_O82_BDCOM_TYPE} eq 'hn-type') {
          $type =~ /\/(\d+)/;
          my $olt_num = $1 + $ether_ports;
          $port_id = sprintf("%02x%02x", $olt_num, $device_index);
        }
        # option 82 - cm-type
        else {
          $type =~ /\/(\d+)/;
          my $olt_num = $1 + $ether_ports;
          $port_id = sprintf("%02x%02x", $olt_num, $device_index);
          #print "// $olt_num, $device_index \n";
          #$port_id = sprintf( "%02d%02x", $brench_index, $interface_index );
        }

        #        #if($debug > 1) {
        #          my $olt_num = $1 + 6;
        #          my $hn_type = sprintf( "%02x%02x", $olt_num, $device_index );
        #          print "$port_id '$conf{DHCP_O82_BDCOM_TYPE}' // cm-type: $port_id hn-type: $hn_type / Olt_num: $olt_num BRanch index: $brench_index Int_index: $interface_index Device: $device_index ($type) ----> $onu_info{ONU_MAC_SERIAL}\n";
        #        #}
        #        print "?? $attr->{SNMP_COMMUNITY}\n\n";
        $onu_info{ONU_DHCP_PORT} = $port_id;

        foreach my $oid_name (keys %{$snmp}) {
          print "$oid_name -- " . ($snmp->{$oid_name}->{NAME} || 'Unknow oid') . '--' . ($snmp->{$oid_name}->{OIDS} || 'unknown') . " \n" if ($debug > 1);
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info') {
            next;
          }
          elsif ($oid_name =~ /POWER|TEMPERATURE/ && $onu_snmp_info{$interface_index}{STATUS} && $onu_snmp_info{$interface_index}{STATUS} ne '3') {
            $onu_info{$oid_name} = '';
            next;
          }
          elsif ($oid_name eq 'STATUS') {
            $onu_info{$oid_name} = $onu_snmp_info{$interface_index}{STATUS};
            next;
          }
          elsif ($oid_name eq 'VLAN') {
            $onu_info{$oid_name} = $onu_snmp_info{$interface_index . ".1"}{VLAN};
            next;
          }

          #          my $oid_value = '';
          #          if ($snmp->{$oid_name}->{OIDS}) {
          #            my $oid = $snmp->{$oid_name}->{OIDS}.'.'.$interface_index;
          #            $oid_value = snmp_get( { %{$attr}, OID => $oid, SILENT => 1 } );
          #          }
          #
          #          my $function = $snmp->{$oid_name}->{PARSER};
          #          if ($function && defined( &{$function} ) ) {
          #            ($oid_value) = &{ \&$function }($oid_value);
          #          }
          #
          #          $onu_info{$oid_name} = $oid_value;
        }
        push @all_rows, { %onu_info };
      }
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _bdcom($attr)

  Parsms:
    cur_tx   - current onu TX
    onu_iden - ONU IDENT (MAC SErial or othe)

=cut
#**********************************************************
sub _bdcom {
  my ($attr) = @_;

  my %snmp = (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.3320.101.10.4.1.1',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '.1.3.6.1.4.1.3320.101.10.1.1.26',
        PARSER => ''
      },
      'ONU_TX_POWER'   => {
        NAME   => 'ONU_TX_POWER',
        OIDS   => '.1.3.6.1.4.1.3320.101.10.5.1.6',
        PARSER => '_bdcom_convert_power'
      }, #tx_power = tx_power * 0.1;
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.3320.101.10.5.1.5',
        PARSER => '_bdcom_convert_power'
      }, #tx_power = tx_power * 0.1;
      # ONU_TX_POWER NOt work on BDCOM(tm) P3616-2TE Software, Version 10.1.0E Build 28164
      #'OLT_RX_POWER' => {
      #  NAME   => 'Olt_Rx_Power',
      #  OIDS   => '.1.3.6.1.4.1.3320.9.183.1.1.5',
      #  PARSER => '_bdcom_convert_power',
      #  SKIP   => 'P3616-2TE'
      #}, #olt_rx_power = olt_rx_power * 0.1;
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => '.1.3.6.1.2.1.31.1.1.1.18',
        PARSER => ''
      },
      'ONU_IN_BYTE'    => {
        NAME   => 'PORT_IN',
        OIDS   => '.1.3.6.1.2.1.31.1.1.1.6',
        PARSER => ''
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'PORT_OUT',
        OIDS   => '.1.3.6.1.2.1.31.1.1.1.10',
        PARSER => ''
      },
      'TEMPERATURE'    => {
        NAME   => 'TEMPERATURE',
        OIDS   => '.1.3.6.1.4.1.3320.101.10.5.1.2',
        PARSER => '_bdcom_convert_temperature'
      }, #temperature = temperature / 256;
      'reset'          => {
        NAME        => '',
        OIDS        => '.1.3.6.1.4.1.3320.101.10.1.1.29',
        RESET_VALUE => 0,
        PARSER      => ''
      },
      'VLAN'           => {
        NAME   => 'VLAN',
        OIDS   => '1.3.6.1.4.1.3320.101.12.1.1.3',
        PARSER => '',
        WALK   => 1
      },
      main_onu_info    => {
        'HARD_VERSION'     => {
          NAME   => 'VERSION',
          OIDS   => '.1.3.6.1.4.1.3320.101.10.1.1.4',
          PARSER => ''
        },
        'FIRMWARE'         => {
          NAME   => 'FIRMWARE',
          OIDS   => '.1.3.6.1.4.1.3320.101.10.1.1.5',
          PARSER => ''
        },
        'VOLTAGE'          => {
          NAME   => 'VOLTAGE',
          OIDS   => '.1.3.6.1.4.1.3320.101.10.5.1.3',
          PARSER => '_bdcom_convert_voltage'
        }, #voltage = voltage * 0.0001;
        'DISTANCE'         => {
          NAME   => 'DISTANCE',
          OIDS   => '.1.3.6.1.4.1.3320.101.10.1.1.27',
          PARSER => '_bdcom_convert_distance'
        }, #distance = distance * 0.001;
        'MAC'              => {
          NAME   => 'MAC',
          OIDS   => '.1.3.6.1.4.1.3320.152.1.1.3',
          PARSER => '_bdcom_mac_list',
          WALK   => 1
        },
        'VLAN'             => {
          NAME   => 'VLAN',
          OIDS   => '1.3.6.1.4.1.3320.101.12.1.1.3',
          PARSER => '',
          WALK   => 1
        },
        # 0-1 - Active
        # 2 - Not connected
        'ONU_PORTS_STATUS' => {
          NAME   => 'ONU_PORTS_STATUS',
          OIDS   => '1.3.6.1.4.1.3320.101.12.1.1.8',
          PARSER => '',
          WALK   => 1
        }
      }
    },
    gpon => {
    }
    #
    #    'onuReset'                        => '1.3.6.1.4.1.3320.101.10.1.1.29',
    #    'cur_tx'                          => '1.3.6.1.4.1.3320.101.10.5.1.5', #TX cure
    #    #''        => '1.3.6.1.4.1.3320.101.10.5.1.6', #TX ULimit
    #    'cur_rx'                          => '1.3.6.1.4.1.3320.9.183.1.1.5', #RX cure
    #    #'mac_onu' => '1.3.6.1.4.1.3320.101.10.1.1.3',
    #    #'RTT(TQ)' =>  '1.3.6.1.4.1.3320.101.11.1.1.8.8',
    #    'onu_ports_status'                => '1.3.6.1.4.1.3320.101.12.1.1.8',
    #    'onustatus'                       => '1.3.6.1.4.1.3320.101.10.1.1.26',
    #    'onu_distance'                    => '1.3.6.1.4.1.3320.101.10.1.1.27',
    #    'mac/serial'                      => '1.3.6.1.4.1.3320.101.10.4.1.1', #Active macs
    #    #'onu_mac' =>  '1.3.6.1.4.1.3320.101.10.1.1.76',  #new params
    #    #                'speed_in' => '1.3.6.1.4.1.3320.101.12.1.1.13',  # onu_id.onu_port
    #    #                'speed_out'=> '1.3.6.1.4.1.3320.101.12.1.1.21',  # onu_id.onu_port
    #
    #    # bdEponOnuEntry
    #    'onuVendorID'                     => '1.3.6.1.4.1.3320.101.10.1.1.1',
    #    'onuIcVersion'                    => '1.3.6.1.4.1.3320.101.10.1.1.10',
    #    'onuServiceSupported'             => '1.3.6.1.4.1.3320.101.10.1.1.11',
    #    'onuGePortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.12',
    #    'onuGePortDistributing'           => '1.3.6.1.4.1.3320.101.10.1.1.13',
    #    'onuFePortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.14',
    #    'onuFePortDistributing'           => '1.3.6.1.4.1.3320.101.10.1.1.15',
    #    'onuPotsPortCount'                => '1.3.6.1.4.1.3320.101.10.1.1.16',
    #    'onuE1PortCount'                  => '1.3.6.1.4.1.3320.101.10.1.1.17',
    #    'onuUsQueueCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.18',
    #    'onuUsQueueMaxCount'              => '1.3.6.1.4.1.3320.101.10.1.1.19',
    #    'onuModuleID'                     => '1.3.6.1.4.1.3320.101.10.1.1.2',
    #    'onuDsQueueCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.20',
    #    'onuDsQueueMaxCount'              => '1.3.6.1.4.1.3320.101.10.1.1.21',
    #    'onuIsBakupBattery'               => '1.3.6.1.4.1.3320.101.10.1.1.22',
    #    'onuADSL2PlusPortCount'           => '1.3.6.1.4.1.3320.101.10.1.1.23',
    #    'onuVDSL2PortCount'               => '1.3.6.1.4.1.3320.101.10.1.1.24',
    #    'onuLLIDCount'                    => '1.3.6.1.4.1.3320.101.10.1.1.25',
    #    'onuStatus'                       => '1.3.6.1.4.1.3320.101.10.1.1.26',
    #    'onuDistance'                     => '1.3.6.1.4.1.3320.101.10.1.1.27',
    #    'onuBindStatus'                   => '1.3.6.1.4.1.3320.101.10.1.1.28',
    #    'onuReset'                        => '1.3.6.1.4.1.3320.101.10.1.1.29',
    #    'onuID'                           => '1.3.6.1.4.1.3320.101.10.1.1.3',
    #    'onuUpdateImage'                  => '1.3.6.1.4.1.3320.101.10.1.1.30',
    #    'onuUpdateEepromImage'            => '1.3.6.1.4.1.3320.101.10.1.1.31',
    #    'onuEncryptionStatus'             => '1.3.6.1.4.1.3320.101.10.1.1.32',
    #    'onuEncryptionMode'               => '1.3.6.1.4.1.3320.101.10.1.1.33',
    #    'onuIgmpSnoopingStatus'           => '1.3.6.1.4.1.3320.101.10.1.1.34',
    #    'onuMcstMode'                     => '1.3.6.1.4.1.3320.101.10.1.1.35',
    #    'OnuAFastLeaveAbility'            => '1.3.6.1.4.1.3320.101.10.1.1.36',
    #    'onuAcFastLeaveAdminControl'      => '1.3.6.1.4.1.3320.101.10.1.1.37',
    #    'onuAFastLeaveAdminState'         => '1.3.6.1.4.1.3320.101.10.1.1.38',
    #    'onuInFecStatus'                  => '1.3.6.1.4.1.3320.101.10.1.1.39',
    #    'onuHardwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.4',
    #    'onuOutFecStatus'                 => '1.3.6.1.4.1.3320.101.10.1.1.40',
    #    'onuIfProtectedStatus'            => '1.3.6.1.4.1.3320.101.10.1.1.41',
    #    'onuSehedulePolicy'               => '1.3.6.1.4.1.3320.101.10.1.1.42',
    #    'onuDynamicMacLearningStatus'     => '1.3.6.1.4.1.3320.101.10.1.1.43',
    #    'onuDynamicMacAgingTime'          => '1.3.6.1.4.1.3320.101.10.1.1.44',
    #    #          'onuStaticMacAddress' => '1.3.6.1.4.1.3320.101.10.1.1.45',
    #    #          'onuStaticMacAddressPortBitmap' => '1.3.6.1.4.1.3320.101.10.1.1.46',
    #    #          'onuStaticMacAddressConfigRowStatus' => '1.3.6.1.4.1.3320.101.10.1.1.47',
    #    'onuClearDynamicMacAddressByMac'  => '1.3.6.1.4.1.3320.101.10.1.1.48',
    #    'onuClearDynamicMacAddressByPort' => '1.3.6.1.4.1.3320.101.10.1.1.49',
    #    'onuSoftwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.5',
    #    'onuPriorityQueueMapping'         => '1.3.6.1.4.1.3320.101.10.1.1.50',
    #    #          'onuVlanMode'             => '1.3.6.1.4.1.3320.101.10.1.1.51',
    #    'onuIpAddressMode'                => '1.3.6.1.4.1.3320.101.10.1.1.52',
    #    'onuStaticIpAddress'              => '1.3.6.1.4.1.3320.101.10.1.1.53',
    #    'onuStaticIpMask'                 => '1.3.6.1.4.1.3320.101.10.1.1.54',
    #    'onuStaticIpGateway'              => '1.3.6.1.4.1.3320.101.10.1.1.55',
    #    'onuMgmtVlan'                     => '1.3.6.1.4.1.3320.101.10.1.1.56',
    #    'onuStaticIpAddressRowStatus'     => '1.3.6.1.4.1.3320.101.10.1.1.57',
    #    #nf          'onuCIR' => '1.3.6.1.4.1.3320.101.10.1.1.58',
    #    #nf          'onuCBS' => '1.3.6.1.4.1.3320.101.10.1.1.59',
    #    'onuFirmwareVersion'              => '1.3.6.1.4.1.3320.101.10.1.1.6',
    #    #60          'onuEBS' => '1.3.6.1.4.1.3320.101.10.1.1.60',
    #    'onuIfMacACL'                     => '1.3.6.1.4.1.3320.101.10.1.1.61',
    #    'onuIfIpACL'                      => '1.3.6.1.4.1.3320.101.10.1.1.62',
    #    'onuVlans'                        => '1.3.6.1.4.1.3320.101.10.1.1.63',
    #    'onuActivePonDiid'                => '1.3.6.1.4.1.3320.101.10.1.1.64',
    #    'onuPonPortCount'                 => '1.3.6.1.4.1.3320.101.10.1.1.65',
    #    'onuActivePonPortIndex'           => '1.3.6.1.4.1.3320.101.10.1.1.66',
    #    'onuSerialPortWorkMode'           => '1.3.6.1.4.1.3320.101.10.1.1.67',
    #    'onuSerialPortWorkPort'           => '1.3.6.1.4.1.3320.101.10.1.1.68',
    #    'onuSerialWorkModeRowStatus'      => '1.3.6.1.4.1.3320.101.10.1.1.69',
    #    'onuChipVendorID'                 => '1.3.6.1.4.1.3320.101.10.1.1.7',
    #    'onuRemoteServerIpAddrIndex'      => '1.3.6.1.4.1.3320.101.10.1.1.70',
    #    'onuPeerOLTIpAddr'                => '1.3.6.1.4.1.3320.101.10.1.1.71',
    #    'onuPeerPONIndex'                 => '1.3.6.1.4.1.3320.101.10.1.1.72',
    #    'onuSerialPortCount'              => '1.3.6.1.4.1.3320.101.10.1.1.73',
    #    'onuChipModuleID'                 => '1.3.6.1.4.1.3320.101.10.1.1.8',
    #    'onuChipRevision'                 => '1.3.6.1.4.1.3320.101.10.1.1.9',
    #
    #
    #    #Mac argument  bdEponLlidOnuBindEntry ->
    #    mac_arg                           => {
    #      'llidEponIfDiid'      => '1.3.6.1.4.1.3320.101.11.1.1.1',
    #      'llidSequenceNo'      => '1.3.6.1.4.1.3320.101.11.1.1.2',
    #      'onuMacAddressIndex'  => '1.3.6.1.4.1.3320.101.11.1.1.3',
    #      'llidOnuBindDesc'     => '1.3.6.1.4.1.3320.101.11.1.1.4',
    #      'llidOnuBindType'     => '1.3.6.1.4.1.3320.101.11.1.1.5',
    #      'llidOnuBindStatus'   => '1.3.6.1.4.1.3320.101.11.1.1.6',
    #      'llidOnuBindDistance' => '1.3.6.1.4.1.3320.101.11.1.1.7', # distance
    #      'llidOnuBindRTT'      => '1.3.6.1.4.1.3320.101.11.1.1.8',
    #    },
    #
    #    #bdEponOnuIfEntry
    #    onu_info                          => {
    #      'onuLlidDiid'                     => '1.3.6.1.4.1.3320.101.12.1.1.1',
    #      'onuUniIfSpeed'                   => '1.3.6.1.4.1.3320.101.12.1.1.10',
    #      'onuUniIfFlowControlStatus'       => '1.3.6.1.4.1.3320.101.12.1.1.11',
    #      'onuUniIfLoopbackTest'            => '1.3.6.1.4.1.3320.101.12.1.1.12',
    #      'onuUniIfSpeedLimit'              => '1.3.6.1.4.1.3320.101.12.1.1.13',
    #      'onuUniIfStormControlType'        => '1.3.6.1.4.1.3320.101.12.1.1.14',
    #      'onuUniIfStormControlThreshold'   => '1.3.6.1.4.1.3320.101.12.1.1.15',
    #      'onuUniIfStormControlRowStatus'   => '1.3.6.1.4.1.3320.101.12.1.1.16',
    #      'onuUniIfDynamicMacLearningLimit' => '1.3.6.1.4.1.3320.101.12.1.1.17',
    #      'onuUniIfVlanMode'                => '1.3.6.1.4.1.3320.101.12.1.1.18',
    #      'onuUniIfVlanCost'                => '1.3.6.1.4.1.3320.101.12.1.1.19',
    #      'onuIfSequenceNo'                 => '1.3.6.1.4.1.3320.101.12.1.1.2',
    #      'onuPvid'                         => '1.3.6.1.4.1.3320.101.12.1.1.3',
    #      'onuOuterTagTpid'                 => '1.3.6.1.4.1.3320.101.12.1.1.4',
    #      'onuMcstTagStrip'                 => '1.3.6.1.4.1.3320.101.12.1.1.5',
    #      'onuMcstMaxGroup'                 => '1.3.6.1.4.1.3320.101.12.1.1.6',
    #      'onuUniIfAdminStatus'             => '1.3.6.1.4.1.3320.101.12.1.1.7',
    #      'onuUniIfOperStatus'              => '1.3.6.1.4.1.3320.101.12.1.1.8',
    #      'onuUniIfMode'                    => '1.3.6.1.4.1.3320.101.12.1.1.9',
    #    }
  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _bdcom_mac_list()

=cut
#**********************************************************
sub _bdcom_mac_list {
  my ($value) = @_;

  my (undef, $v) = split(/:/, $value);
  $v = bin2mac($v) . ';';

  return '', $v;
}

#**********************************************************
=head2 _bdcom_onu_status()

=cut
#**********************************************************
sub _bdcom_onu_status {
  #  my %status = (
  #    0  => 'free',
  #    1  => 'allocated:text-success',
  #    2  => 'authInProgress:text-warning',
  #    3  => 'cfgInProgress:text-info',
  #    4  => 'authFailed:text-danger',
  #    5  => 'cfgFailed:text-danger',
  #    6  => 'reportTimeout',
  #    7  => 'ok',
  #    8  => 'authOk',
  #    9  => 'resetInProgress',
  #    10 => 'resetOk',
  #    11 => 'discovered',
  #    12 => 'blocked:text-danger',
  #    13 => 'checkNewFw',
  #    14 => 'unidentified',
  #    15 => 'unconfigured',
  #  );
  my %status = (
    0 => 'Authenticated:text-green',
    1 => 'Registered:text-green', #work
    2 => 'Deregistered:text-red', #not work
    3 => 'Auto_config:text-green' #not work
  );
  return \%status;
}

#**********************************************************
=head2 _bdcom_set_desc($attr) - Set Description to OLT ports

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub _bdcom_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    $oid = '1.3.6.1.2.1.31.1.1.1.18.' . $attr->{PORT};
  }

  my $result = snmp_set({
    %$attr,
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return $result;
}

#**********************************************************
=head2 _bdcom_convert_power();

=cut
#**********************************************************
sub _bdcom_convert_power {
  my ($power) = @_;
  $power //= 0;

  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = $power * 0.1;
  }

  return $power;
}

#**********************************************************
=head2 _bdcom_convert_temperature();

=cut
#**********************************************************
sub _bdcom_convert_temperature {
  my ($temperature) = @_;

  $temperature //= 0;
  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _bdcom_convert_voltage();

=cut
#**********************************************************
sub _bdcom_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.0001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _bdcom_convert_distance();

=cut
#**********************************************************
sub _bdcom_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _bdcom_get_fdb($attr);

  Arguments:
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    NAS_INFO       => $attr->{NAS_INFO},
    SNMP_TPL       => $attr->{SNMP_TPL},
    FILTER         => $attr->{FILTER} || ''

  Results:


=cut
#**********************************************************
sub _bdcom_get_fdb {
  my ($attr) = @_;
  my %fdb_hash = ();

  my $debug = $attr->{DEBUG} || 0;

  print "BDCOM mac " if ($debug > 1);
  my $perl_scalar = _get_snmp_oid($attr->{SNMP_TPL} || 'bdcom.snmp', $attr);
  my $oid = '.1.3.6.1.2.1.17.4.3.1';
  if ($perl_scalar && $perl_scalar->{FDB_OID}) {
    $oid = $perl_scalar->{FDB_OID};
  }

  my ($expr_, $values, $attribute);
  my @EXPR_IDS = ();

  if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
    $perl_scalar->{FDB_EXPR} =~ s/\%\%/\\/g;
    ($expr_, $values, $attribute) = split(/\|/, $perl_scalar->{FDB_EXPR} || '');
    @EXPR_IDS = split(/,/, $values);
  }

  #Get port name list
  my $ports_name;
  my $port_name_oid = $perl_scalar->{ports}->{PORT_NAME}->{OIDS} || '';
  if ($port_name_oid) {
    $ports_name = snmp_get({
      %$attr,
      TIMEOUT => $attr->{TIMEOUT} || 8,,
      OID     => $port_name_oid,
      VERSION => 2,
      WALK    => 1
    });
  }

  return 1 if (!$ports_name);

  my $count = 0;
  foreach my $iface (@$ports_name) {
    print "Iface: $iface \n" if ($debug > 1);
    my ($id, $port_name) = split(/:/, $iface, 2);

    #get macs
    my $mac_list = snmp_get({
      %$attr,
      WALK    => 1,
      OID     => '.1.3.6.1.4.1.3320.152.1.1.3.' . $id,
      VERSION => 2,
      TIMEOUT => $attr->{TIMEOUT} || 4
    });

    foreach my $line (@$mac_list) {
      #print "$line <br>";
      #my ($oid, $value);
      next if (!$line);
      my $vlan;
      my $mac_dec;
      my $port = $id;

      if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
        my %result = ();

        if (my @res = ($line =~ /$expr_/g)) {
          for (my $i = 0; $i <= $#res; $i++) {
            $result{$EXPR_IDS[$i]} = $res[$i];
          }
        }

        if ($result{MAC_HEX}) {
          $result{MAC} = _mac_former($result{MAC_HEX}, { BIN => 1 });
        }

        if ($result{PORT_DEC}) {
          $result{PORT} = dec2hex($result{PORT_DEC});
        }

        $vlan = $result{VLAN} || 0;
        $mac_dec = $result{MAC} || '';
      }

      my $mac = _mac_former($mac_dec);

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

      $mac_dec //= $count;

      # 1 mac
      $fdb_hash{$mac_dec}{1} = $mac;
      # 2 port
      $fdb_hash{$mac_dec}{2} = $port;
      # 3 status
      # 4 vlan
      $fdb_hash{$mac_dec}{4} = $vlan;
      # 5 port name
      $fdb_hash{$mac_dec}{5} = $port_name;
      $count++;
    }

    #    if($count > 3) {
    #      last;
    #    }
  }

  return %fdb_hash;
}

1
