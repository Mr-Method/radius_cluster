
=head1 NAME

  ZTE snmp monitoring and managment

  VERSION: 0.02

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw( _bp in_array int2byte convert);
use Abills::Filters qw(bin2mac bin2hex);

our (
  %lang,
  $html
);

my %type_name = (
  1 => 'epon_olt_virtualIfBER',
  3 => 'epon-onu',
  6 => 'type6'
);

#**********************************************************
=head2 _zte_get_ports($attr) - Get OLT slots and connect ONU

=cut
#**********************************************************
sub _zte_get_ports {
  my ($attr) = @_;

  my $ports_info = equipment_test({
    %{$attr},
    PORT_INFO => 'PORT_NAME,PORT_DESCR,PORT_STATUS,PORT_SPEED,IN,OUT,PORT_TYPE',
  });

  my $ports_info_hash = ();

  foreach my $key ( keys %{ $ports_info } ) {
    if ($ports_info->{$key}{PORT_TYPE} && $ports_info->{$key}{PORT_TYPE} =~ /^300|250$/ && $ports_info->{$key}{PORT_NAME} =~ /(.pon)_(.+)$/) {
      my $type = $1;
      my $branch = $2;
      my ($self, $slot, $olt) = $branch =~ /^(\d+)\/(\d+)\/(\d+)/;
      $self++ if ($self eq '0');
      my $port_snmp_id = encode_port(1, $self, $slot, $olt);
      my $port_descr;
      $ports_info_hash->{$port_snmp_id} = $ports_info->{$key};
      $ports_info_hash->{$port_snmp_id}{BRANCH} = $branch;
      $ports_info_hash->{$port_snmp_id}{PON_TYPE} = $type;
      $ports_info_hash->{$port_snmp_id}{SNMP_ID} = $port_snmp_id;
      if ($type eq 'gpon') {
        $port_descr = snmp_get( { %{$attr},
                OID => '1.3.6.1.4.1.3902.1012.3.13.1.1.1.' . $port_snmp_id,
            });
      }
      else {
        $port_descr = snmp_get( { %{$attr},
                OID => '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1.' . $port_snmp_id,
            });
      }
      $ports_info_hash->{$port_snmp_id}{BRANCH_DESC} = $port_descr;
    }
  }
  return \%{$ports_info_hash};
}

#**********************************************************
=head2 _zte_onu_list($attr) -

=cut
#**********************************************************
sub _zte_onu_list  {
  my ($port_list, $attr) = @_;

  my @all_rows = ();
  my %pon_types = ();
  my %port_ids = ();

  foreach my $snmp_id (keys %{ $port_list }) {
    $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
  }

  foreach my $type (keys %pon_types) {
    my $snmp = _zte({TYPE => $type});
    if ($type eq 'epon') {
      my $onu_status_list = snmp_get( {
        %$attr,
        WALK => 1,
        OID  => $snmp->{ONU_STATUS}->{OIDS},
      });

      foreach my $line ( @{$onu_status_list} ) {
        my ($interface_index, $status) = split( /:/, $line, 2 );
        my $port_id = decode_onu($interface_index, {MODEL_NAME => $attr->{MODEL_NAME}});
        my $port_dhcp_id = decode_onu($interface_index, {TYPE => 'dhcp', MODEL_NAME => $attr->{MODEL_NAME}});
        $port_id =~ /^(\d+)\/(\d+)\/(\d+):(\d+)/;
        my $onu_id = $4;
        my $olt_port = $1 . '/' . $2 . '/' . $3;
        my %onu_info = ();

        $onu_info{PORT_ID}       = $port_ids{$olt_port};
        $onu_info{ONU_ID}        = $onu_id;
        $onu_info{ONU_SNMP_ID}   = $interface_index;
        $onu_info{PON_TYPE}      = $type;
        $onu_info{ONU_DHCP_PORT} = $port_dhcp_id;

        foreach my $oid_name ( keys %{ $snmp } ){
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' ){
            next;
          }
          elsif ( $oid_name =~ /POWER|TEMPERATURE/ && $status ne '3' ){
            $onu_info{$oid_name} = '';
            next;
          }
          elsif ( $oid_name eq 'ONU_STATUS' ){
            $onu_info{$oid_name} = $status;
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "epon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS} \n";
          }

          my $oid_value = '';
          if ($snmp->{$oid_name}->{OIDS}) {
            my $oid = $snmp->{$oid_name}->{OIDS}.'.'.$interface_index;
            $oid_value = snmp_get( { %{$attr}, OID => $oid, SILENT => 1 } );
          }

          my $function = $snmp->{$oid_name}->{PARSER};
          if ($function && defined( &{$function} ) ) {
            ($oid_value) = &{ \&$function }($oid_value);
          }
          $onu_info{$oid_name} = $oid_value;
        }
        push @all_rows, {%onu_info};
      }
    }
    else {
      foreach my $snmp_id (keys %{ $port_list }) {
        my %total_info = ();
        next if ($port_list->{$snmp_id}{PON_TYPE} ne $type);
        my $cols = [ 'PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT' ];
        foreach my $oid_name (keys %{ $snmp }) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info') {
            next;
          }

          push @{$cols}, $oid_name;
          my $oid = $snmp->{$oid_name}->{OIDS};
          if (!$oid) {
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "gpon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS}.$snmp_id \n";
          }

          my $values = snmp_get({ %{$attr},
            WALK    => 1,
            OID     => $oid . '.' . $snmp_id,
            TIMEOUT => 25
          });

          foreach my $line (@{$values}) {
            next if (!$line || $line !~ /\d+:.+/);
            my ($onu_id, $oid_value) = split( /:/, $line, 2 );
            $onu_id =~ s/\.\d+//;
            if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
              print $oid.' -> '."$onu_id, $oid_value \n";
            }
            my $function = $snmp->{$oid_name}->{PARSER};
            if ($function && defined( &{$function} )) {
              ($oid_value) = &{ \&$function }($oid_value);
            }
            $total_info{$oid_name}{$snmp_id.'.'.$onu_id} = $oid_value;
          }
        }

        foreach my $key (keys %{ $total_info{ONU_STATUS} }) {
          my %onu_info = ();
          my ($branch, $onu_id) = split(/\./, $key, 2);
          my $port_dhcp_id = decode_onu($branch, { TYPE => 'dhcp' });
          for (my $i = 0; $i <= $#{ $cols }; $i++) {
            my $value = '';
            my $oid_name = $cols->[$i];
            my $num = sprintf("%03d", $onu_id);
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
              $value = $port_dhcp_id.'/'.$num;
            }
            elsif ($oid_name eq 'ONU_SNMP_ID') {
              $value = $key;
            }
            else {
              $value = $total_info{$cols->[$i]}{$key};
            }
            $onu_info{$oid_name}=$value;
          }
          push @all_rows, {%onu_info};
        }
      }
    }
  }

  return \@all_rows;
}

#**********************************************************
=head2 _zte_onu_list2($attr) -

=cut
#**********************************************************
sub _zte_onu_list2  {
  my ($port_list, $attr) = @_;

  my @all_rows = ();
  my %pon_types = ();
  my %port_ids = ();

  foreach my $snmp_id (keys %{ $port_list }) {
    $pon_types{ $port_list->{$snmp_id}{PON_TYPE} } = 1;
    $port_ids{$port_list->{$snmp_id}{BRANCH}} = $port_list->{$snmp_id}{ID};
  }

  foreach my $type (keys %pon_types) {
    my $snmp = _zte({TYPE => $type});
    if ($type eq 'epon') {
      my $onu_status_list = snmp_get( {
        %$attr,
        WALK => 1,
        OID  => $snmp->{ONU_STATUS}->{OIDS},
      });

      foreach my $line ( @{$onu_status_list} ) {
        my ($interface_index, $status) = split( /:/, $line, 2 );
        my $port_id = decode_onu($interface_index, {MODEL_NAME => $attr->{MODEL_NAME}});
        my $port_dhcp_id = decode_onu($interface_index, {TYPE => 'dhcp', MODEL_NAME => $attr->{MODEL_NAME}});
        $port_id =~ /^(\d+)\/(\d+)\/(\d+):(\d+)/;
        my $onu_id = $4;
        my $olt_port = $1 . '/' . $2 . '/' . $3;
        my %onu_info = ();

        $onu_info{PORT_ID}       = $port_ids{$olt_port};
        $onu_info{ONU_ID}        = $onu_id;
        $onu_info{ONU_SNMP_ID}   = $interface_index;
        $onu_info{PON_TYPE}      = $type;
        $onu_info{ONU_DHCP_PORT} = $port_dhcp_id;

        foreach my $oid_name ( keys %{ $snmp } ){
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info' ){
            next;
          }
          elsif ( $oid_name =~ /POWER|TEMPERATURE/ && $status ne '3' ){
            $onu_info{$oid_name} = '';
            next;
          }
          elsif ( $oid_name eq 'ONU_STATUS' ){
            $onu_info{$oid_name} = $status;
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "epon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS} \n";
          }

          my $oid_value = '';
          if ($snmp->{$oid_name}->{OIDS}) {
            my $oid = $snmp->{$oid_name}->{OIDS}.'.'.$interface_index;
            $oid_value = snmp_get( { %{$attr}, OID => $oid, SILENT => 1 } );
          }

          my $function = $snmp->{$oid_name}->{PARSER};
          if ($function && defined( &{$function} ) ) {
            ($oid_value) = &{ \&$function }($oid_value);
          }
          $onu_info{$oid_name} = $oid_value;
        }
        push @all_rows, {%onu_info};
      }
    }
    else {
      foreach my $snmp_id (keys %{ $port_list }) {
        my %total_info = ();
        next if ($port_list->{$snmp_id}{PON_TYPE} ne $type);
        my $cols = [ 'PORT_ID', 'ONU_ID', 'ONU_SNMP_ID', 'PON_TYPE', 'ONU_DHCP_PORT' ];
        foreach my $oid_name (keys %{ $snmp }) {
          if ($oid_name eq 'reset' || $oid_name eq 'main_onu_info') {
            next;
          }

          push @{$cols}, $oid_name;
          my $oid = $snmp->{$oid_name}->{OIDS};
          if (!$oid) {
            next;
          }

          if ($attr->{DEBUG} && $attr->{DEBUG} > 1) {
            print "gpon $oid_name -- $snmp->{$oid_name}->{NAME} -- $snmp->{$oid_name}->{OIDS}.$snmp_id \n";
          }

          my $values = snmp_get({ %{$attr},
            WALK    => 1,
            OID     => $oid . '.' . $snmp_id,
            TIMEOUT => 25
          });

          foreach my $line (@{$values}) {
            next if (!$line || $line !~ /\d+:.+/);
            my ($onu_id, $oid_value) = split( /:/, $line, 2 );
            $onu_id =~ s/\.\d+//;
            if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
              print $oid.'->'."$onu_id, $oid_value \n";
            }
            my $function = $snmp->{$oid_name}->{PARSER};
            if ($function && defined( &{$function} )) {
              ($oid_value) = &{ \&$function }($oid_value);
            }
            $total_info{$oid_name}{$snmp_id.'.'.$onu_id} = $oid_value;
          }
        }

        foreach my $key (keys %{ $total_info{ONU_STATUS} }) {
          my %onu_info = ();
          my ($branch, $onu_id) = split(/\./, $key, 2);
          my $port_dhcp_id = decode_onu($branch, { TYPE => 'dhcp' });
          for (my $i = 0; $i <= $#{ $cols }; $i++) {
            my $value = '';
            my $oid_name = $cols->[$i];
            my $num = sprintf("%03d", $onu_id);
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
              $value = $port_dhcp_id.'/'.$num;
            }
            elsif ($oid_name eq 'ONU_SNMP_ID') {
              $value = $key;
            }
            else {
              $value = $total_info{$cols->[$i]}{$key};
            }
            $onu_info{$oid_name}=$value;
          }
          push @all_rows, {%onu_info};
        }
      }
    }
  }

  return \@all_rows;
}


#**********************************************************
=head2 _zte($attr) - Snmp recovery

  Arguments:
    $attr
      EPON

  Returns:
    OID hash_ref

=cut
#**********************************************************
sub _zte {
  my ($attr) = @_;

  my %snmp =  (
    epon => {
      'ONU_MAC_SERIAL' => {
        NAME => 'Mac/Serial',
        OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.4',
        PARSER => 'bin2mac'
      },
      'ONU_STATUS' => {
        NAME => 'Status',
        OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.17',
        PARSER => ''
      },
      'ONU_TX_POWER' => {
        NAME => 'Tx_Power',
        OIDS => '', #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.4
        PARSER => '_zte_convert_epon_power'
      },
      'ONU_RX_POWER' => {
        NAME => 'Rx_Power',
        OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.5',
        PARSER => '_zte_convert_epon_power'
      },
      'OLT_RX_POWER' => {
        NAME => 'Olt_Rx_Power',
        OIDS => '',
        PARSER => ''
      },
      'ONU_DESC' => {
        NAME => 'Description',
        OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.1',
        PARSER => '_zte_convert_epon_description'
      },
      'ONU_IN_BYTE' => {
        NAME => 'In',
        OIDS => '',
        PARSER => ''
      },
      'ONU_OUT_BYTE' => {
        NAME => 'Out',
        OIDS => '',
        PARSER => ''
      },
      'TEMPERATURE' => {
        NAME => 'Temperature',
        OIDS => '', #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.1
        PARSER => '_zte_convert_epon_temperature'
      },
      'reset' => {
        NAME => '',
        OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.2.1.1.1',
        PARSER => ''
      },
      main_onu_info => {
        'HARD_VERSION' => {
          NAME => 'Hhard_Version',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.5',
          PARSER => ''
        },
        'SOFT_VERSION' => {
          NAME => 'Soft_Version',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.6',
          PARSER => ''
        },
        'VOLTAGE' => {
          NAME => 'Voltage',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.2',
          PARSER => '_zte_convert_epon_voltage'
        },
        'DISATNCE' => {
          NAME => 'Distance',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.2.1.1.10',
          PARSER => '_zte_convert_distance',
        },
        'TEMPERATURE' => {
          NAME => 'Temperature',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.1',
          PARSER => '_zte_convert_epon_temperature'
        },
        'ONU_TX_POWER' => {
          NAME => 'Tx_Power',
          OIDS => '.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.4',
          PARSER => '_zte_convert_epon_power'
        }
      }
    },
    gpon => {
      'ONU_MAC_SERIAL' => {
        NAME => 'Mac/Serial',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5',
        PARSER => 'bin2hex'
      },
      'ONU_STATUS' => {
        NAME => 'Status',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
        PARSER => ''
      },
      'ONU_TX_POWER' => {
        NAME => 'Tx_Power',
        OIDS => '', #.1.3.6.1.4.1.3902.1012.3.50.12.1.1.14
        PARSER => '_zte_convert_power',
        ADD_2_OID => '.1'
      }, # tx_power = tx_power * 0.002 - 30.0;
      'ONU_RX_POWER' => {
        NAME => 'Rx_Power',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.10',
        PARSER => '_zte_convert_power',
        ADD_2_OID => '.1'
      }, # rx_power = rx_power * 0.002 - 30.0;
      'OLT_RX_POWER' => {
        NAME => 'Olt_Rx_Power',
        OIDS => '', #.1.3.6.1.4.1.3902.1015.1010.11.2.1.2
        PARSER => '_zte_convert_olt_power'
      }, # olt_rx_power = olt_rx_power * 0.001;
      'ONU_DESC' => {
        NAME => 'Description',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
        PARSER => '_zte_convert_description'
      },
      'ONU_IN_BYTE' => {
        NAME => 'In',
        OIDS => '',
        PARSER => ''
      },
      'ONU_OUT_BYTE' => {
        NAME => 'Out',
        OIDS => '',
        PARSER => ''
      },
      'TEMPERATURE' => {
        NAME => 'Temperature',
        OIDS => '', #.1.3.6.1.4.1.3902.1012.3.50.12.1.1.19
        PARSER => '_zte_convert_temperature',
        ADD_2_OID => '.1'
      },
      'reset' => {
        NAME => '',
        OIDS => '.1.3.6.1.4.1.3902.1012.3.50.11.3.1.1',
        PARSER => ''
      },
      main_onu_info => {
        'VERSION_ID' => {
          NAME => 'Version_ID',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.2',
          PARSER => ''
        },
        'VENDOR_ID' => {
          NAME => 'Vendor_ID',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.1',
          PARSER => ''
        },
        'EQUIPMENT_ID' => {
          NAME => 'Equipment_ID',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
          PARSER => ''
        },
        'VOLTAGE' => {
          NAME => 'Voltage',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.17',
          PARSER => '_zte_convert_voltage',
          ADD_2_OID => '.1'
        },
        'DISATNCE' => {
          NAME => 'Distance',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
          PARSER => '_zte_convert_distance'
        },
        'TEMPERATURE' => {
          NAME => 'Temperature',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.19',
          PARSER => '_zte_convert_temperature',
          ADD_2_OID => '.1'
        },
        'ONU_TX_POWER' => {
          NAME => 'Tx_Power',
          OIDS => '.1.3.6.1.4.1.3902.1012.3.50.12.1.1.14',
          PARSER => '_zte_convert_power',
          ADD_2_OID => '.1'
        }
      }
    }
#    'reg_onu_count'   => '.1.3.6.1.4.1.3902.1012.3.13.1.1.13', #
#    'unreg_onu_count' => '.1.3.6.1.4.1.3902.1012.3.13.1.1.14', #
#    'onu_type'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.1',
#    'onu_name'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.2',
#    'onu_desr'    => '.1.3.6.1.4.1.3902.1012.3.28.1.1.3',
#    'onu_vendorid'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.1',
#    'mac_onu'     => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
#    'onu_vlan'    => '1.3.6.1.4.1.3902.1012.3.50.13.3.1.1',
#    'serial'      => '.1.3.6.1.4.1.3902.1012.3.28.1.1.5', #'.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7',
#    'onustatus'   => '.1.3.6.1.4.1.3902.1012.3.28.2.1.4',
#    'num'         => '.1.3.6.1.4.1.3902.1012.3.28.3.1.8', #lld
#    'onu_model'   => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.9',
#    'cur_tx'      => '.1.3.6.1.4.1.3902.1015.1010.11.2.1.2', # lazerpower
#    'epon_n'      => '.1.3.6.1.4.1.3902.1012.3.13.1.1.1',
#    'onu_distance'=> '.1.3.6.1.4.1.3902.1012.3.11.4.1.2',
#    'onu_Reset'   => '.1.3.6.1.4.1.3320.101.10.1.1.29',
#    'onu_load'    => '.1.3.6.1.4.1.3902.1012.3.28.2.1.5',
#    'onu_uptime'  => '.1.3.6.1.4.1.3902.1012.3.50.11.2.1.20',
#    'onu_firmware'=> '.3.6.1.4.1.3902.1012.3.50.11.2.1.2',
#    'byte_in'     => '.1.3.6.1.4.1.3902.1012.3.28.6.1.5'
    #.1.3.6.1.4.1.3902.1012.3.13.1.1.1 - gpon port descr
    #.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1 - epon port descr
    #.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.7 - MAC-адреса ОНУ
    #.1.3.6.1.4.1.3902.1015.1010.1.2.1.1.10 - расстояние до ОНУ
    #.1.3.6.1.4.1.3902.1015.1010.1.1.1.29.1.5.ID - уровень сигнала (только через snmpget)
    #.1.3.6.1.4.1.3902.1015.1010.1.7.4.1.5 - модель ОНУ
    #.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.2 - производитель ОНУ
    #.1.3.6.1.4.1.3902.1015.1010.1.1.1.1.1.6 - версия ПО ОНУ
  );

  if ($attr->{TYPE}) {
    return $snmp{$attr->{TYPE}};
  }

  return \%snmp;
}

#**********************************************************
=head2 _zte_onu_status();

  Arguments:
    $attr
      EPON - Show epon status describe

  Returns:
    Status hash_ref

=cut
#**********************************************************
sub _zte_onu_status {
  my ($pon_type) = @_;

  my %status = (
      0 => 'unknown:text-orange',
      1 => 'LOS:text-red',
      2 => 'Synchronization:text-red',
      3 => 'Online:text-green',
      4 => 'Dying_gasp:text-red',
      5 => 'Power_Off:text-orange',
      6 => 'Offline:text-red',
  );

  if ($pon_type eq 'epon') {
    %status = (
        1 => 'Power_Off:text-orange',
        2 => 'Offline:text-red',
        3 => 'Online:text-green'
    );
  }

  return \%status;
}
#**********************************************************
=head2 _zte_set_desc_port($attr) - Set Description to OLT ports

=cut
#**********************************************************
sub _zte_set_desc {
  my ($attr) = @_;
  my $oid = $attr->{OID} || '' ;
  if ($attr->{PORT}) {
    if ($attr->{PORT_TYPE} eq 'gpon') {
      $oid = '1.3.6.1.4.1.3902.1012.3.13.1.1.1.'.$attr->{PORT};
    }
    else {
      $oid = '.1.3.6.1.4.1.3902.1015.1010.1.7.16.1.1.'.$attr->{PORT};
    }
  }
  #$attr->{DESC} = convert($attr->{DESC}, {utf82win => 1});
  if ($attr->{PON_TYPE} && $attr->{PON_TYPE} eq 'epon') {
    $attr->{DESC} = $attr->{ONU_ID}.'$$'.$attr->{DESC}.'$$';
  }
  Encode::_utf8_off($attr->{DESC});
  Encode::from_to($attr->{DESC}, 'utf-8', 'windows-1251');
  snmp_set(
      {
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
            OID        => [ $oid, "string", $attr->{DESC} ]
      }
  );
}
#**********************************************************
=head2 decode_onu($dec) - Decode onu int

  Arguments:
    $dec

  Returns:
    deparsing string

=cut
#**********************************************************
sub decode_onu {
  my ($dec, $attr) = @_;

  $dec =~ s/\.\d+//;

  my %result = ();
  my $bin = sprintf( "%032b", $dec );
  my ($bin_type) = $bin =~ /^(\d{4})/;
  my $type = oct( "0b$bin_type" );
  my $i = ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /C220/i ) ? 0 : 1;
  if ( $type == 3 ) {
    @result{'type', 'shelf', 'slot', 'olt',
      'onu'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{5})(\d{3})(\d{8})(\d{8})/;
    if ($attr->{TYPE} && $attr->{TYPE} eq 'dhcp') {
      $result{slot} = ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /C220/i ) ? sprintf("%02d", $result{slot}) : sprintf("%02d", $result{slot});
      $result{onu}  = ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /C220/i ) ? sprintf("%02d", $result{onu}) : sprintf("%03d", $result{onu});
      if ($attr->{MODEL_NAME} && $attr->{MODEL_NAME} =~ /C220/i ) {
        $result{slot} =~ s/^0/ /g;
        $result{onu} =~ s/^0/ /g;
      }
    }
    return (($attr->{DEBUG}) ? $type .'#'. $type_name{$result{type}} . '_' : '')
      . ($result{shelf} + $i)
      . '/' . $result{slot}
      . '/' . ($result{olt} + 1)
      . (($attr->{TYPE} && $attr->{TYPE} eq 'dhcp') ? '/' : ':')
      . $result{onu};
  }
  elsif ( $type == 1 ) {
    @result{'type', 'shelf', 'slot', 'olt'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})(\d{8})(\d{8})/;
    $result{slot} = sprintf("%02d", $result{slot}) if ($attr->{TYPE} && $attr->{TYPE} eq 'dhcp');
    return (($attr->{DEBUG}) ? $type .'#'. $type_name{$result{type}} . '_' : '')
      . $result{shelf}
      . '/' . $result{slot}
      . '/' . $result{olt};
  }
  elsif ( $type == 6 ) {
    @result{'type', 'shelf', 'slot'} = map { oct( "0b$_" ) } $bin =~ /^(\d{4})(\d{4})(\d{8})/;
    return $type .'#'. $type_name{$result{type}}
      . '_' . $result{shelf}
      . '/' . $result{slot};
  }
  else {
    print "Unknown type: $type\n";
  }

  return 0;
}

#**********************************************************
=head2 encode_port($type, $self, $slot, $olt) - Decode port

  Arguments:
    $dec

  Returns:
    deparsing string

=cut
#**********************************************************
sub encode_port {
  my ($type, $self, $slot, $olt) = @_;

  my $bin = sprintf( "%04b", $type )
            . sprintf( "%04b", $self-1 )
            . sprintf( "%08b", $slot )
            . sprintf( "%08b", $olt )
            . '00000000';

  return oct( "0b$bin" );
}

#**********************************************************
=head2 _zte_convert_power($power) - Convert power

=cut
#**********************************************************
sub _zte_convert_epon_power {
  my ($power) = @_;

  $power //= 0;

  if($power) {
    if ($power eq 'N/A' || $power =~ /65535/ || $power && $power > 0) {
      $power = '0';
    }
    else {
      $power = sprintf("%.2f", $power);
    }
  }

  return $power;
}

#**********************************************************
=head2 _zte_convert_power();

=cut
#**********************************************************
sub _zte_convert_power{
  my ($power) = @_;

  $power //= 0;

  if ($power eq '0' || $power > 60000) {
    $power = '0';
  }
  else {
    $power = ($power * 0.002 - 30 );
    $power = sprintf("%.2f", $power);
  }
  return $power;
}

#**********************************************************
=head2 _zte_convert_olt_power();

=cut
#**********************************************************
sub _zte_convert_olt_power{
  my ($olt_power) = @_;

  $olt_power //= 0;

  if ($olt_power eq '65535000') {
    $olt_power = '';
  }
  else {
    $olt_power = ($olt_power * 0.001);
    $olt_power = sprintf("%.2f", $olt_power);
  }

  return $olt_power;
}

#**********************************************************
=head2 _zte_convert_description();

=cut
#**********************************************************
sub _zte_convert_description{
  my ($description) = @_;

  $description = convert($description || q{}, {win2utf8 => 1});

  return $description;
}

#**********************************************************
=head2 _zte_convert_epon_description();

=cut
#**********************************************************
sub _zte_convert_epon_description{
  my ($description) = @_;

  if(! defined($description)) {
    return q{};
  }

  if ($description =~ /^.*\$\$(.*)\$\$.*$/) {
    $description = $1;
  }

  $description = convert($description, {win2utf8 => 1});
  return $description;
}

#**********************************************************
=head2 _zte_convert_temperature();

=cut
#**********************************************************
sub _zte_convert_temperature{
  my ($temperature) = @_;

  $temperature //= 0;

  if (2147483647 == $temperature) {
    $temperature = '';
  }
  else {
    $temperature = ($temperature * 0.001);
    $temperature  = sprintf("%.2f", $temperature);
  }

  return $temperature;
}

#**********************************************************
=head2 _zte_convert_epon_temperature();

=cut
#**********************************************************
sub _zte_convert_epon_temperature{
  my ($temperature) = @_;

  $temperature //= 0;

  if ($temperature eq '2147483647') {
    $temperature = '';
  }
  elsif ($temperature) {
    $temperature  = sprintf("%.2f", $temperature);
  }

  return $temperature;
}

#**********************************************************
=head2 _zte_convert_epon_voltage();

=cut
#**********************************************************
sub _zte_convert_epon_voltage{
  my ($voltage) = @_;

  $voltage //= 0;

  $voltage = sprintf("%.2f V", $voltage);

  return $voltage;
}

#**********************************************************
=head2 _zte_convert_voltage();

=cut
#**********************************************************
sub _zte_convert_voltage{
  my ($voltage) = @_;

  $voltage //= 0;

  $voltage = $voltage * 0.02;

  $voltage .= ' V';

  return $voltage;
}

#**********************************************************
=head2 _zte_convert_distance();

=cut
#**********************************************************
sub _zte_convert_distance{
  my ($distance) = @_;

  $distance //= 0;

  if ($distance eq '-1') {
    $distance = '--';
  }
  else {
    $distance = $distance * 0.001;
    $distance .= ' km';
  }
  return $distance;
}

1
