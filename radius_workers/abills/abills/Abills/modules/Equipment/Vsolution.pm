=head1 NAME

  VSOLUTION

=cut

use strict;
use warnings;
use Abills::Base qw(in_array);
use Abills::Filters qw(bin2mac _mac_former dec2hex);
our %lang;

#**********************************************************
=head2 _vsolution_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _vsolution_get_ports {
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
=head2 _vsolution_onu_list($attr)

  Arguments:
    $attr
      COLS       - ARRAY refs
      INFO_OIDS  - Hash refs
      NAS_ID
      TIMEOUT

=cut
#**********************************************************
sub _vsolution_onu_list {
  my ($port_list, $attr) = @_;

  my @cols      = ('PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT');
  my $debug     = $attr->{DEBUG} || 0;
  my @all_rows  = ();
  my %pon_types = ();
  my %port_ids  = ();

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

  #my $ether_ports = $snmp_info->{PORTS};
  if ($port_list) {
    foreach my $snmp_id (keys %{$port_list}) {
      $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
      $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
    }
  }
  else {
    %pon_types = (epon => 1, gpon => 1);
  }

  my $pon_ports_descr = snmp_get({
    %$attr,
    WALK    => 1,
    OID     => '.1.3.6.1.4.1.37950.1.1.5.10.1.2.1.1.2',
    VERSION => 2,
    TIMEOUT => $attr->{TIMEOUT} || 2
  });

  if (!$pon_ports_descr || $#{$pon_ports_descr} < 1) {
    return [];
  }

  foreach my $pon_type (keys %pon_types) {
    my $snmp = _vsolution({ TYPE => $pon_type });

    if (!$snmp->{ONU_STATUS}->{OIDS}) {
      print "$pon_type: no oids\n" if ($debug > 0);
      next;
    }
    else {
      if($debug > 3) {
        print "PON TYPE: $pon_type\n";
      }
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

        if($oid_name eq 'reset') {
          next
        }

        push @cols, $oid_name;
        print "PON ONU INFO $oid_name: $oid\n" if ($debug > 3);
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
          elsif($debug > 4) {
            print " IF_INDEX: $interface_index RESULT: $line\n";
          }

          if ($function && defined(&{$function})) {
            ($value) = &{\&$function}($value);
          }

          if($interface_index =~ /^\d+$/) {
            print "$oid_name: Index: $interface_index OID: $oid VALUE: $value\n";
            next;
          }

          $onu_snmp_info{$oid_name}{$interface_index} = $value;
        }
      }
    }

    my $onu_count = 0;
    foreach my $key (sort keys %{ $onu_snmp_info{ONU_MAC_SERIAL} }) {
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
          #$value = $port_list->{$snmp_id}->{ID};
          $value = $port_ids{'0/'.$branch} ;
        }
        elsif ($oid_name eq 'PON_TYPE') {
          $value = $pon_type;
        }
        elsif ($oid_name eq 'ONU_DHCP_PORT') {
          $value = $branch . ':' . $onu_id;
        }
        elsif ($oid_name eq 'ONU_SNMP_ID') {
          $value = $key;
        }
        else {
          $value = $onu_snmp_info{$cols[$i]}{$key};
        }
        $onu_info{$oid_name}=$value;
      }

      push @all_rows, \%onu_info;
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _vsolution($attr)

  Parsms:
    cur_tx   - current onu TX
    onu_iden - ONU IDENT (MAC SErial or othe)

=cut
#**********************************************************
sub _vsolution {
  my ($attr) = @_;

  my %snmp = (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME   => 'Mac/Serial',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.25.1.5', #'.1.3.6.1.4.1.37950.1.1.5.12.2.1.2.1.5',
        PARSER => ''
      },
      'ONU_STATUS'     => {
        NAME   => 'STATUS',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.25.1.4', #'.1.3.6.1.4.1.37950.1.1.5.12.1.12.1.5',
        PARSER => ''
      },
      'ONU_TX_POWER'   => {
        NAME   => 'ONU_TX_POWER',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.8.1.6',
        PARSER => '_vsolution_convert_power'
      }, #tx_power = tx_power * 0.1;
      'ONU_RX_POWER'   => {
        NAME   => 'ONU_RX_POWER',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.8.1.7',
        PARSER => '_vsolution_convert_power'
      }, #tx_power = tx_power * 0.1;
      'ONU_DESC'       => {
        NAME   => 'DESCRIBE',
        OIDS   => 'iso.3.6.1.4.1.37950.1.1.5.12.1.25.1.9',
		  #'.1.3.6.1.4.1.37950.1.1.5.12.1.25.1.6', #'.1.3.6.1.4.1.37950.1.1.5.12.1.12.1.10',
        PARSER => ''
      },
      'ONU_IN_BYTE'    => {
        NAME   => 'PORT_IN',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.20.1.3', #'.1.3.6.1.4.1.37950.1.1.5.10.1.2.2.1.44',
        PARSER => ''
      },
      'ONU_OUT_BYTE'   => {
        NAME   => 'PORT_OUT',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.20.1.10', #'.1.3.6.1.4.1.37950.1.1.5.10.1.2.2.1.45',
        PARSER => ''
      },
      'TEMPERATURE'    => {
        NAME   => 'TEMPERATURE',
        OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.8.1.3',
        PARSER => '_vsolution_convert_temperature'
      }, #@remared -> temperature = temperature / 256;
      'reset'          => {
        NAME        => '',
        OIDS        => '.1.3.6.1.4.1.37950.1.1.5.12.1.15',
        RESET_VALUE => 0,
        PARSER      => ''
      },
      main_onu_info    => {
        'HARD_VERSION'     => {
          NAME   => 'VERSION',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.2.1.6',
          PARSER => ''
        },
        'FIRMWARE'         => {
          NAME   => 'FIRMWARE',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.2.1.7',
          PARSER => ''
        },
        'VOLTAGE'          => {
          NAME   => 'VOLTAGE',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.2.1.8.1.4',
          PARSER => '_vsolution_convert_voltage'
        }, #voltage = voltage * 0.0001;
        'MAC'              => {
          NAME   => 'MAC',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.9.1.5',
          PARSER => '_vsolution_mac_list',
          WALK   => 1
        },
        'VLAN'             => {
          NAME   => 'VLAN',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.10.2.6.1.5',
          PARSER => '',
          WALK   => 1
        },
        # 0-1 - Active
        # 2 - Not connected
        'ONU_PORTS_STATUS' => {
          NAME   => 'ONU_PORTS_STATUS',
          OIDS   => '.1.3.6.1.4.1.37950.1.1.5.12.1.25.1.4',
          PARSER => '',
          WALK   => 1
        }
      }
    },
    gpon => {
    }

  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _vsolution_mac_list()

=cut
#**********************************************************
sub _vsolution_mac_list {
  my ($value) = @_;

  my (undef, $v) = split(/:/, $value);
  $v = bin2mac($v) . ';';

  return '', $v;
}

#**********************************************************
=head2 _vsolution_onu_status()

=cut
#**********************************************************
sub _vsolution_onu_status {
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
    1 => 'Registered:text-green',
    2 => 'Deregistered:text-red',
    3 => 'Auto_config:text-green'
  );
  return \%status;
}
#**********************************************************
=head2 _vsolution_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _vsolution_set_desc {
  my ($attr) = @_;

  my $oid = $attr->{OID} || '';

  if ($attr->{PORT}) {
    #    $oid = '1.3.6.1.2.1.31.1.1.1.18.'.$attr->{PORT};
  }

  snmp_set({
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    OID            => [ $oid, "string", "$attr->{DESC}" ]
  });

  return 1;
}

#**********************************************************
=head2 _vsolution_convert_power($power);

  Arguments:
    $power

=cut
#**********************************************************
sub _vsolution_convert_power {
  my ($power) = @_;

  $power =~ /\s\([0-9\.]+\s/;
  $power = $1 || 0;

  if (-65535 == $power) {
    $power = '';
  }
  else {
    $power = $power * 0.1;
  }

  return $power;
}

#**********************************************************
=head2 _vsolution_convert_temperature();

=cut
#**********************************************************
sub _vsolution_convert_temperature {
  my ($temperature) = @_;

  $temperature ||= 0;

  $temperature =~ s/\s+C//;

#@  $temperature = ($temperature / 256);
  $temperature = sprintf("%.2f", $temperature);

  return $temperature;
}

#**********************************************************
=head2 _vsolution_convert_voltage();

=cut
#**********************************************************
sub _vsolution_convert_voltage {
  my ($voltage) = @_;

  $voltage //= 0;
  $voltage = $voltage * 0.0001;
  $voltage = sprintf("%.2f", $voltage);
  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _vsolution_convert_distance();

=cut
#**********************************************************
sub _vsolution_convert_distance {
  my ($distance) = @_;

  $distance //= 0;

  $distance = $distance * 0.001;
  $distance .= ' km';
  return $distance;
}

#**********************************************************
=head2 _vsolution_get_fdb($attr);

  Arguments:
    SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
    NAS_INFO       => $attr->{NAS_INFO},
    SNMP_TPL       => $attr->{SNMP_TPL},
    FILTER         => $attr->{FILTER} || ''

  Results:


=cut
#**********************************************************
sub _vsolution_get_fdb {
  my ($attr) = @_;
  my %fdb_hash = ();

  my $debug = $attr->{DEBUG} || 0;

  print "vsolution mac " if ($debug > 1);
  my $perl_scalar = _get_snmp_oid($attr->{SNMP_TPL} || 'vsolution.snmp', $attr);
  my $oid = '.1.3.6.1.4.1.37950.1.1.5.10.3.2.1.3';
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

  return {} if (!$ports_name);

  my $count = 0;
  foreach my $iface (@$ports_name) {
    print "Iface: $iface \n" if ($debug > 1);
    my ($id, $port_name) = split(/:/, $iface, 2);

    #get macs
    my $mac_list = snmp_get({
      %$attr,
      WALK    => 1,
      OID     => '.1.3.6.1.4.1.37950.1.1.5.10.3.2.1.3' . $id,
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
