=head1
  Name: equipment ping

=cut


use strict;
use warnings;

use Abills::Filters;
use Abills::Base qw(in_array load_pmodule2);
use Nas;
use Equipment;
use JSON;
use RRDTool::OO;
use Data::Dumper;

our $SNMP_TPL_DIR = "../Abills/modules/Equipment/snmp_tpl/";

require Equipment::Graph;
require Equipment::Pon_mng;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir
);

load_pmodule2('SNMP');

SNMP::initMib();
SNMP::addMibDirs($Bin."/../Abills/MIBs/private", $Bin."/../Abills/MIBs");
SNMP::addMibFiles(glob($Bin."/../Abills/MIBs/private".'/*'));
$Admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );

my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $sess;

my $Log = Log->new($db, $Admin);
if($debug > 2) {
  $Log->{PRINT}=1;
}
else {
  $Log->{LOG_FILE} = $var_dir.'/log/equipment_check.log';
}

equipment_check();

#**********************************************************
=head2 equipment_check($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub equipment_check {

  if($debug > 7) {
    $Equipment->{debug}=1;
  }

  if ($argv->{NAS_IPS}) {
    $LIST_PARAMS{NAS_IP} = $argv->{NAS_IPS};
  }
  if ($argv->{DEBUG} && $argv->{DEBUG} > 7) {
    $Equipment->{debug} = 1;
  }

  my $SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};

  my $equipment_list = $Equipment->_list( {
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    NAS_ID    => '_SHOW',
    MODEL_ID  => '_SHOW',
    NAS_IP    => '_SHOW',
    STATUS    => '0',
    %LIST_PARAMS
  } );

  foreach my $equip (@$equipment_list) {

    my %ses_params;
    $ses_params{UseSprintValue} = ($argv->{POLL}) ? 1 : 0;

    $sess = SNMP::Session->new(
      DestHost => $equip->{nas_ip},
      Community=> $SNMP_COMMUNITY,
      Version  => 2,
      UseEnums => 1,
      Retries  => 2,
      %ses_params
     );

    my $models = $Equipment->model_list({
      COLS_NAME => 1,
      SYS_OID   => '_SHOW',
      MODEL_ID  => $equip->{model_id},
      PORTS     => '_SHOW'
    });

    my $ports = $Equipment->port_list({
      NAS_ID         => $equip->{nas_id},
      PORT           => '_SHOW',
      UPLINK         => 1,
      COLS_NAME      => 1,
      SKIP_DEL_CHECK => 1
    });

    my $sections = $Equipment->snmp_tpl_list({ COLS_NAME => 1, MODEL_ID => $equip->{model_id}, SECTION => '_SHOW' });
    my $stats = $Equipment->graph_list({ COLS_NAME => 1, NAS_ID => $equip->{nas_id} });

    if ($argv->{FIX}) {
      my $sysoid = $sess->get([ 'sysObjectID', 0 ]);
      if ($sysoid ne $models->[0]->{sys_oid}) {
        my $correct = $Equipment->model_list({ COLS_NAME => 1, SYS_OID => $sysoid });
        if ($debug < 2) {
          if ($correct) {
            $Equipment->_change({ NAS_ID => $equip->{nas_id}, MODEL_ID => $correct->[0]->{id} });
            $Log->log_print('LOG_INFO', $equip->{nas_ip}, "NAS_ID:$equip->{nas_id} Change model ID to $correct->[0]->{id} ");
          }
          else {
            $Log->log_print('LOG_INFO', $equip->{nas_ip}, "NAS_ID:$equip->{nas_id} Unknown model. sysObjectID: $sysoid");
          }
        }
        else {
          $Log->log_print('LOG_INFO', $equip->{nas_ip}, "NAS_ID:$equip->{nas_id} has wrong model sysObjectID");
        }
      }
    }
    
	if ($argv->{POLL} && $sections) {
      foreach my $sect (@$sections) {
        if ($sect->{section} eq 'INFO' || $sect->{section} eq 'PORTS'
          || $sect->{section} =~ /PON/) {
          snmp_info({
            MODEL_ID => $equip->{id},
            NAS_ID   => $equip->{nas_id},
            NAS_IP   => $equip->{nas_ip},
            SECT     => $sect->{section}
          });
        }
      }
    }
    if ($argv->{VLAN}) {
      vlan({ NAS_ID => $equip->{nas_id} });
    }

    if ($argv->{STATS} && $stats) {
      stats({ NAS_ID => $equip->{nas_id} });
    }

    if ($argv->{FDB}) {
      my @rem_ports = (1..$models->[0]->{ports});
      foreach my $p (@$ports) {
        @rem_ports = grep { $_ != $p->{port} } @rem_ports;
      }

      fdb({
        PORTS => \@rem_ports,
        NAS_ID=> $equip->{nas_id}
      });
      }
    
    if ($argv->{FDB2}) {
      my @rem_ports = (1..$models->[0]->{ports});
      foreach my $p (@$ports) {
        @rem_ports = grep { $_ != $p->{port} } @rem_ports;
      }

      fdb2({
        PORTS   => \@rem_ports,
        NAS_INFO=> $equip,
        NAS_ID  => $equip->{nas_id}
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 snmp_info($attr)

=cut
#**********************************************************      	
sub snmp_info {
  my ($attr) = @_;
  my $jres = $Equipment->snmp_tpl_list({
    COLS_NAME => 1,
    MODEL_ID  => $attr->{MODEL_ID},
    SECTION   => $attr->{SECT}
  });

  if ($jres->[0]->{parameters}) {
    my $json_arr = decode_json($jres->[0]->{parameters});
    my @snmp_vars;
    foreach my $var (@$json_arr) {
      push @snmp_vars, [ $var->[0] ];
    }
    my $vars = SNMP::VarList->new( @snmp_vars );
    my @vals = $sess->bulkwalk( 0, 1, $vars );
    my %arr;

    foreach my $var (@{$vals[0]}) {
      foreach my $k (0..@snmp_vars) {
        push  @{$arr{$var->[1]}}, '';
      }
      $var->[2] =~ tr/"//d;
      $arr{$var->[1]}[0] = $var->[2];
    }

    foreach my $var (1..@vals) {
      foreach my $v (@{$vals[$var]}) {
        if (@{$vals[0]} == 1) {
          $v->[1] = 0;
        }
        elsif (!$v->[1]) {
          $v->[0] =~ /\w+\.(\d+)$/gi;
          $v->[1] = $1;
        }
        $v->[2] =~ tr/"//d;
        if ($arr{$v->[1]}) {
          $arr{$v->[1]}[$var] = $v->[2];
        }
      }
    }
    my $port_to_json = encode_json(\%arr);
    my %data = ( NAS_ID => $attr->{NAS_ID}, SECTION => $attr->{SECT} );
    if ($debug > 6) {
      print  Dumper  \@vals;
    }
    else {
      $Equipment->info_add({ %data, INFO_TIME => 'NOW()', RESULT => $port_to_json });
    }
  }
  else {
    $Log->log_print('LOG_INFO', $attr->{NAS_IP}, "OID's or SECTION for NAS:$attr->{NAS_ID} not defined!");
  }

  return 1;
}

#**********************************************************
=head2 stats($attr)

=cut
#********************************************************** 
sub stats {
  my ($attr) = @_;

  my $params = $Equipment->graph_list({
    COLS_NAME   => 1,
    NAS_ID      => $attr->{NAS_ID},
    PORT        => '_SHOW',
    MEASURE_TYPE=> '_SHOW',
    PARAM       => '_SHOW'
  });

  my %ports;
  foreach my $var (@$params) {
    my $val = $sess->get("$var->{param}.$var->{port}");
    push (@{$ports{$var->{port}}}, [ $var->{param}, $val, $var->{measure_type} ]);
  }

  foreach my $port (keys %ports) {
    my @datasource;
    foreach my $pr (@{$ports{$port}}) {
      push @datasource, { DATA => $pr->[1], SOURCE => $pr->[0], TYPE => $pr->[2] };
    }
    add_graph({ NAS_ID => $attr->{NAS_ID}, PORT => $port, TYPE => 'COUNTER', DATA => \@datasource });
  }

  return 1;
}

#**********************************************************
=head2 fdb($attr)

  Arguments:
    $attr
      NAS_ID

=cut
#********************************************************** 
sub fdb{
  my ($attr) = @_;

  $Log->log_print('LOG_INFO', '', "FDB NAS_ID: $attr->{NAS_ID}");

  my @fdb_vals = $sess->bulkwalk(0, 1, [ 'dot1qTpFdbPort' ]);
  my @fdb_arr;

  foreach my $var (@{$fdb_vals[0]}) {
    if (grep { $var->[2] eq $_ } @{$attr->{PORTS}}) {
      my @whithvid = split(/[.\s]/, $var->[1]);
      my $vid = $whithvid[0];
      my @k;

      foreach my $vr (1..@whithvid - 1) {
        push @k, sprintf( '%.2x', $whithvid[$vr]);
      }

      push @fdb_arr, [ $var->[2], join(":", @k), $vid ];

      my %data = (
        NAS_ID => $attr->{NAS_ID},
        MAC    => join(":", @k),
        VLAN   => $vid,
        PORT   => $var->[2],
      );

      $Equipment->mac_log_add({ %data, DATETIME => 1 });
    }
  }

  return 1;
}

#**********************************************************
=head2 vlan($attr)

=cut
#********************************************************** 
sub vlan{
  my ($attr) = @_;
  my @vals;

  @vals = $sess->bulkwalk(0, 1, [ 'dot1qVlanStatus' ]);
  my %vlan_arr;
  foreach my $var (@{$vals[0]}) {
    my @unt_ports;
    my @tag_ports;
    if ($var->[2] eq "permanent") {
      my $vid = substr($var->[1], index($var->[1], ".") + 1);
      my $index = unpack( "B64", $sess->get("dot1qVlanCurrentUntaggedPorts.$var->[1]"));
      my $offset = 0;
      my $result = index($index, 1, $offset);
      while ($result != - 1) {
        $result = index($index, 1, $offset);
        $offset = $result + 1;
        push @unt_ports, $offset if ( $offset > 0 );
      }
      $index = unpack( "B64", $sess->get("dot1qVlanCurrentEgressPorts.$var->[1]"));
      $offset = 0;
      $result = index($index, 1, $offset);
      while ($result != - 1) {
        $result = index($index, 1, $offset);
        $offset = $result + 1;
        push @tag_ports, $offset if ( $offset > 0 );
      }
      my $vname = $sess->get("dot1qVlanStaticName.$vid");
      $vname =~ s/\0//g;
      $vlan_arr{$vid} = [ $vname, \@unt_ports, \@tag_ports ];
    }
  }
  my $to_json = encode_json(\%vlan_arr);
  my %data = ( NAS_ID => $attr->{NAS_ID}, SECTION => 'VLAN' );
  if ($debug > 6) {
    print Dumper  \%vlan_arr;
  }
  else {
    $Equipment->info_add({ %data, RESULT => $to_json });
  }

  return 1;
}

#**********************************************************
=head2 fdb($attr)

  Arguments:
    $attr
      NAS_ID
      NAS_INFO

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub fdb2 {
  my ($attr) = @_;

  $Log->log_print('LOG_INFO', '', "FDB2 NAS_ID: $attr->{NAS_ID}");

  my $perl_scalar = undef; #_get_snmp_oid( $attr->{NAS_INFO}->{snmp_tpl} );
  my $oid = '.1.3.6.1.2.1.17.4.3.1';

  if ($perl_scalar && $perl_scalar->{FDB_OID}){
    $oid = $perl_scalar->{FDB_OID};
  }

  my $nas_type = '';
  if ( $attr->{NAS_INFO}->{type_id} && $attr->{NAS_INFO}->{type_id} == 4 ){
    $nas_type = equipment_pon_init($attr);
  }

  my $get_fdb = $nas_type . '_get_fdb';
  my %fdb_hash = ();

  if ( ! $Equipment->{STATUS} ) {
    if (defined( &{$get_fdb} )) {
      %fdb_hash = &{ \&$get_fdb }({
        SNMP_COMMUNITY => $attr->{SNMP_COMMUNITY},
        NAS_INFO       => $attr->{NAS_INFO},
        SNMP_TPL       => $attr->{SNMP_TPL},
        FILTER         => $attr->{FILTER} || ''
      });
    }
    else {
      my $value = snmp_get(
        {
          %{$attr},
          OID     => $oid,
          WALK    => 1,
          TIMEOUT => 4,
          DEBUG   => $FORM{DEBUG} || 2
        }
      );

      my ($expr_, $values, $attribute);
      my @EXPR_IDS = ();

      if ($perl_scalar && $perl_scalar->{FDB_EXPR}) {
        $perl_scalar->{FDB_EXPR} =~ s/\%\%/\\/g;
        ($expr_, $values, $attribute) = split( /\|/, $perl_scalar->{FDB_EXPR} || '' );
        @EXPR_IDS = split( /,/, $values );
      }

      if (!$value) {
        #$html->message('err', $lang{ERROR}, "Can't get FDB", { ID => 421 });
        return 1;
      }

      foreach my $line (@{ $value }) {
        print $line;
        #my ($oid, $value);
        next if (!$line);
        my $vlan;
        my $mac_dec;
        my $port;
      }
    }
  }
      #  foreach my $var (@{$fdb_vals[0]}) {
#    if (grep { $var->[2] eq $_ } @{$attr->{PORTS}}) {
#      my @whithvid = split(/[.\s]/, $var->[1]);
#      my $vid = $whithvid[0];
#      my @k;
#
#      foreach my $vr (1. .@whithvid - 1) {
#        push @k, sprintf( '%.2x', $whithvid[$vr]);
#      }
#
#      push @fdb_arr, [ $var->[2], join(":", @k), $vid ];
#
#      my %data = (
#        NAS_ID => $attr->{NAS_ID},
#        MAC    => join(":", @k),
#        VLAN   => $vid,
#        PORT   => $var->[2],
#      );
#
#      $Equipment->mac_log_add({ %data, DATETIME => 1 });
#    }
#  }

  return 1;
}


1
