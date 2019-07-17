=head1 NAME

 billd plugin

 DESCRIBE: PON load onu info

 Arguments:

   TIMEOUT
   RELOAD  - Reload onu

=cut

use strict;
use warnings;
use Abills::Filters;
use SNMP_Session;
use SNMP_util;
use Equipment;
use Events;
use Data::Dumper;
use Abills::Base qw(load_pmodule2 in_array check_time gen_time);
use threads;
our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
  $OS,
  $var_dir
);

my $running_threads = 10;
our $Equipment = Equipment->new($db, $Admin, \%conf);
my $Events = Events->new($db, $Admin, \%conf);

do 'Abills/Misc.pm';
#unshift( @INC, '/usr/abills/Abills/modules/' );
#load_module('Equipment');

require Equipment::Grabbers;
require Equipment::Pon_mng;
require Equipment::Graph;

if ($argv->{NAS_IDS}) {
  _equipment_pon_load($argv->{NAS_IDS});
}
elsif($argv->{multi}) {
  _equipment_pon_multi();
}
else {
  _equipment_pon();
}


#**********************************************************
=head2 _equipment_pon($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub _equipment_pon {

  if($debug > 6) {
    $Equipment->{debug} = 1;
  }
  my $equipment_list = $Equipment->_list({
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0',
    TYPE_NAME => '4',
  });

  foreach my $line (@$equipment_list) {
    #    my $zz = `/usr/abills/libexec/billd equipment_pon NAS_ID=$line->{nas_id}`;
    _equipment_pon_load($line->{nas_id});
  }

  return 1;
}
#**********************************************************
=head2 _equipment_pon_load($nas_id)

=cut
#**********************************************************
sub _equipment_pon_load  {
  my ($nas_id) = @_;

  my $pon_begin_time = check_time();
  our $SNMP_TPL_DIR = "/usr/abills/Abills/modules/Equipment/snmp_tpl/";
  $db = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef }, \%conf );
  if ( !$db->{db} ) {
    print "Error: SQL connect error\n";
    exit;
  }

  my $admin_ = Admins->new( $db, \%conf );
  $admin_->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );
  $Equipment = Equipment->new($db, $admin_, \%conf);

  if($debug > 6) {
    $Equipment->{debug} = 1;
  }

  my $Equipment_list = $Equipment->_list( {
    NAS_ID           => $nas_id,
    NAS_NAME         => '_SHOW',
    MODEL_ID         => '_SHOW',
    REVISION         => '_SHOW',
    TYPE             => '_SHOW',
    SYSTEM_ID        => '_SHOW',
    NAS_TYPE         => '_SHOW',
    MODEL_NAME       => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    STATUS           => '_SHOW',
    NAS_IP           => '_SHOW',
    MNG_HOST_PORT    => '_SHOW',
    MNG_USER         => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    SNMP_TPL         => '_SHOW',
    LOCATION_ID      => '_SHOW',
    VENDOR_NAME      => '_SHOW',
    SNMP_VERSION     => '_SHOW',
    TYPE_NAME        => '',
    COLS_NAME        => 1
  } );

  my $nas_info = $Equipment_list->[0];
  $Equipment->model_info( $nas_info->{model_id} );
  if(! $nas_info->{nas_mng_password}) {
    print "NAS_ID: $nas_info->{nas_id} COMMINITY not defined\n";
    $nas_info->{nas_mng_password} = 'public';
    #next;
  }
  my $SNMP_COMMUNITY = "$nas_info->{nas_mng_password}\@" . (($nas_info->{nas_mng_ip_port}) ? $nas_info->{nas_mng_ip_port} : $nas_info->{nas_ip});

#  if($SNMP_COMMUNITY =~ /(.+):(.+)/) {
#    $SNMP_COMMUNITY = $1;
#    my $SNMP_PORT = $2 || 161;
#    if (! in_array($SNMP_PORT, [22])) {
#      $SNMP_COMMUNITY .= ':'.$SNMP_PORT.':5';
#      $SNMP_COMMUNITY .= "";
#    }
#    else {
#      $SNMP_COMMUNITY .= ':161:5';
#    }
#  }
#  else {
#    $SNMP_COMMUNITY .= ':161:5';
#  }

  #  $SNMP_COMMUNITY = "$MNG_PASSWORD\@$MNG_HOST\:$second_port:5:::2";
  my $onu_counts = 0;

  if ($nas_info->{status} eq 0) {
    $nas_info->{NAME} = $nas_info->{vendor_name};
    my $nas_type = equipment_pon_init({ NAS_INFO => $nas_info });
    if (!$nas_type) {
      return 0;
    }

    my $onu_database_list = $Equipment->onu_list({
      NAS_ID       => $nas_id,
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000,
      ONU_GRAPH    => '_SHOW',
      COMMENTS     => '_SHOW',
    });

    my $created_onu = ();
    foreach my $onu (@$onu_database_list){
      $created_onu->{ $onu->{onu_snmp_id} }->{ONU_GRAPH} = $onu->{onu_graph};
      $created_onu->{ $onu->{onu_snmp_id} }->{ONU_DESC}  = $onu->{comments} || '';
      $created_onu->{ $onu->{onu_snmp_id} }->{ID}        = $onu->{id};
    }

    my $get_list_fn = $nas_type . '_onu_list';

    if ( defined( &{$get_list_fn} ) ) {
      my $olt_ports = ();
      my $port_list = $Equipment->pon_port_list({
        COLS_NAME  => 1,
        COLS_UPPER => 1,
        NAS_ID     => $nas_id
      });

      #Add ports
      if ($argv->{RELOAD}) {
        if($debug > 2) {
          print "Reload ports: $Equipment->{TOTAL}\n";
        }

        foreach my $line ( @$port_list ) {
          if($debug > 1) {
            print "Delete onu port: $line->{ID} \n";
          }

          $Equipment->onu_del( 0, { PORT_ID => $line->{ID} } );
          $Equipment->pon_port_del($line->{ID});
        }
        $Equipment->{TOTAL} = 0;
      }

      if(! $Equipment->{TOTAL}) {
        equipment_pon_get_ports({
          VERSION        => $nas_info->{snmp_version} || 1,
          SNMP_COMMUNITY => $SNMP_COMMUNITY,
          NAS_ID         => $nas_id,
          NAS_TYPE       => $nas_type,
          MODEL_NAME     => $Equipment->{MODEL_NAME},
          SNMP_TPL       => $Equipment->{SNMP_TPL}
        });

        $port_list = $Equipment->pon_port_list({
          COLS_NAME  => 1,
          COLS_UPPER => 1,
          NAS_ID     => $nas_id
        });
      }

      foreach my $line (@$port_list){
        $olt_ports->{$line->{snmp_id}} = $line;
      }

      #my $olt_ports = equipment_pon_get_ports({SNMP_COMMUNITY => $SNMP_COMMUNITY, NAS_ID => $nas_id, NAS_TYPE => $nas_type, MODEL_NAME => $Equipment->{MODEL_NAME}, SNMP_TPL => $Equipment->{SNMP_TPL}});
      my $onu_list = &{ \&$get_list_fn }($olt_ports, {
        VERSION        => $nas_info->{snmp_version} || 1,
        SNMP_COMMUNITY => $SNMP_COMMUNITY,
        TIMEOUT        => $argv->{TIMEOUT} || 5,
        SKIP_TIMEOUT   => 1,
        DEBUG          => $debug,
        MODEL_NAME     => $Equipment->{MODEL_NAME}
      });

      $onu_counts = $#{ $onu_list } + 1;

      my @MULTI_QUERY = ();
      my @ONU_ADD     = ();
      #print Dumper $onu_list;
      foreach my $onu (@$onu_list) {
        if ($created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}) {
          if($debug > 3) {
            print "$nas_type TYPE => $onu->{PON_TYPE} \n";
          }

          my $snmp = &{ \&{$nas_type} }({TYPE => $onu->{PON_TYPE}});
#          if ($created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} && $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC} ne $onu->{ONU_DESC}){
#            my $set_desc_fn = $nas_type . '_set_desc';
#            if ( defined( &{$set_desc_fn} ) ){
#              #print "CHANGE $onu->{ONU_SNMP_ID} TYPE: \"$onu->{PON_TYPE}\" DESC: \"$onu->{ONU_DESC}\" OID: \"$snmp->{ONU_DESC}->{OIDS}.$onu->{ONU_SNMP_ID}\"";
#              &{ \&$set_desc_fn }({ SNMP_COMMUNITY => $SNMP_COMMUNITY,
#                      ONU_ID         => $onu->{ONU_ID},
#                      PON_TYPE       => $onu->{PON_TYPE},
#                      OID            => $snmp->{ONU_DESC}->{OIDS}.'.'.$onu->{ONU_SNMP_ID},
#                      DESC           => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_DESC}
#                  });
#            }
#          }
          my @onu_graph_types = split(',', $created_onu->{ $onu->{ONU_SNMP_ID} }->{ONU_GRAPH});
          foreach my $graph_type (@onu_graph_types) {
            if ($graph_type eq 'SIGNAL' && ($snmp->{ONU_RX_POWER}->{OIDS} || $snmp->{OLT_RX_POWER}->{OIDS})) {
              my @onu_graph_data = ();
              push @onu_graph_data, {DATA => $onu->{ONU_RX_POWER} || 0, SOURCE => $snmp->{ONU_RX_POWER}->{NAME} || q{}, TYPE => 'GAUGE'};
              push @onu_graph_data, { DATA => $onu->{OLT_RX_POWER} || 0, SOURCE => $snmp->{OLT_RX_POWER}->{NAME} || q{OLT_RX_POWER}, TYPE => 'GAUGE' };
              add_graph({NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => 'SIGNAL', DATA => \@onu_graph_data});
            }
            elsif ($graph_type eq 'TEMPERATURE' && $snmp->{TEMPERATURE}->{OIDS}) {
              my @onu_graph_data = ();
              push @onu_graph_data, {DATA => $onu->{TEMPERATURE} || 0, SOURCE => $snmp->{TEMPERATURE}->{NAME}, TYPE => 'GAUGE'};
              add_graph({NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => 'TEMPERATURE', DATA => \@onu_graph_data});
            }
            elsif ($graph_type eq 'SPEED' && ($snmp->{ONU_IN_BYTE}->{OIDS} || $snmp->{ONU_OUT_BYTE}->{OIDS})) {
              my @onu_graph_data = ();
              push @onu_graph_data, {DATA => $onu->{ONU_IN_BYTE} || 0, SOURCE => $snmp->{ONU_IN_BYTE}->{NAME}, TYPE => 'COUNTER'};
              push @onu_graph_data, {DATA => $onu->{ONU_OUT_BYTE} || 0, SOURCE => $snmp->{ONU_OUT_BYTE}->{NAME}, TYPE => 'COUNTER'};
              add_graph({NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => 'SPEED', DATA => \@onu_graph_data});
            }
          }

          push @MULTI_QUERY, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS},
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT},
            $onu->{PORT_ID},
            $onu->{ONU_MAC_SERIAL},
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}
          ];
          #$Equipment->onu_change( { ID => $created_onu->{ $onu->{ONU_SNMP_ID} }->{ID}, NAS_ID => $nas_id, %{$onu} } );
          delete  $created_onu->{ $onu->{ONU_SNMP_ID} };
        }
        else {
          #$Equipment->onu_add( { NAS_ID => $nas_id, %{$onu} } );
          push @ONU_ADD, [
            $onu->{OLT_RX_POWER} || '',
            $onu->{ONU_RX_POWER} || '',
            $onu->{ONU_TX_POWER} || '',
            $onu->{ONU_STATUS} || 0,
            $onu->{ONU_IN_BYTE} || 0,
            $onu->{ONU_OUT_BYTE} || 0,
            $onu->{ONU_DHCP_PORT} || '',
            $onu->{PORT_ID} || '',
            $onu->{ONU_MAC_SERIAL} || '',
            $onu->{ONU_DESC} || '',
            $onu->{ONU_ID},
            $onu->{ONU_SNMP_ID}
          ];
        }

        pon_alert($onu->{OLT_RX_POWER});
      }

      if ($#ONU_ADD > -1) {
        $Equipment->onu_add( {  MULTI_QUERY => \@ONU_ADD } );
      }
      if($#MULTI_QUERY > -1) {
        $Equipment->onu_change( { MULTI_QUERY => \@MULTI_QUERY } );
      }
#      foreach my $snmp_id (keys %{ $created_onu }) {
#        $Equipment->onu_del( $created_onu->{ $snmp_id }->{ID} ) if ($created_onu->{ $snmp_id }->{ID});
#      }
    }
  }

  print "NAS_TYPE : $nas_info->{NAME}, MODEL_NAME: $Equipment->{MODEL_NAME}, NAS_IP: $nas_info->{nas_ip}, NAS_ID: $nas_id, ONU: $onu_counts " . gen_time( $pon_begin_time ) . "\n" if ($debug);

  return 1;
}

#**********************************************************
=head2 wait_ps($threads, $max_threads) - Wait until ps end for next thread

  Arguments:
    $threads     - thread id arrays
    $max_threads - Max thread running

  Return:
     1 - wait
     0 - run


=cut
#**********************************************************
sub wait_ps {
  my ($threads, $max_threads) = @_;

  my $running_ps=0;

  foreach my threads $th (@$threads) {
    my $running = $th->is_running();
    if($running) {
      $running_ps++
    }
    #else {
    #  $running_ps--;
    #}
  }

  if($running_ps > $max_threads) {
    #print "Sleep: Running: $running_ps Total: $#{ $threads }\n";
    sleep 1;
    #run
    return 1;
  }

  #Finish
  return 0;
}

#**********************************************************
=head2 _equipment_pon_multi()

=cut
#**********************************************************
sub _equipment_pon_multi {

  my @threads = ();

  my $equipment_list = $Equipment->_list({
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0',
    TYPE_NAME => '4',
  });

  foreach my $line (@$equipment_list) {
    my threads $t = threads->create(\&_equipment_pon_load, $line->{nas_id});
    push @threads, $t;
    $t->detach();

    while (wait_ps(\@threads, $running_threads)) {

    }
  }

  while (wait_ps(\@threads, 0)) {
    print "Wait finish\n" if($debug);
  }

  return 1;
}


#**********************************************************
=head2 pon_alert($attr)

=cut
#**********************************************************
sub pon_alert {
  my($parameter) = @_;

  if(! $parameter) {
    return 0;
  }

  my %parameters = (
    # Name for module
    MODULE      => 'Equipment',
    # Text
    COMMENTS    => 'PON ALERT: '. $parameter,
    # Link to see external info
    EXTRA       => 'http://abills.net.ua',
    # 1..5 Bigger is more important
    PRIORITY_ID => 2,
  );

  if(!$parameter || $parameter == 65535) {
    return 0;
  }
  elsif($parameter > 0) {
    return 0;
  }
  elsif ($parameter > -8 || $parameter < -30) {
    #$parameter = $html->color_mark($parameter, 'text-red' );
  }
  elsif($parameter > -10 || $parameter < -27) {
    $parameters{PRIORITY_ID}=1;
  }
  else {
    return 0;
  }


  $Events->events_add( \%parameters );


  return 1;
}

1
