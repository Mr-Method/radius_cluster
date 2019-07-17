=head1 NAME

  equipment macs

  Params:
    SEARCH_MAC

  Arguments:

   CLEAN=1

=cut


use strict;
use warnings;
use Abills::Filters;
use Abills::Base qw(in_array gen_time check_time);
use Nas;
use Equipment;
use Events;
use JSON;

our $SNMP_TPL_DIR = "../Abills/modules/Equipment/snmp_tpl/";

require Abills::Misc;
require Equipment::Graph;
require Equipment::Pon_mng;
require Equipment::Grabbers;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

$Admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );
my $Equipment = Equipment->new( $db, $Admin, \%conf );
#my $Events = Events->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);

if($debug > 2) {
  $Log->{PRINT}=1;
}
else {
  $Log->{LOG_FILE} = $var_dir.'/log/equipment_check.log';
}

if ($argv->{DEL_MAC}){
  $Equipment->mac_log_del({
    DEL_PERIOD => $conf{EQUIPMENT_MAC_EXPIRE},
  });
}
else{
  equipment_check();
}

#**********************************************************
=head2 equipment_check($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_check {

  #my $timeout = $argv->{TOUT} || '5';
  $Log->log_print('LOG_INFO', '', "Equipment check");

  my $search_mac = '';

  if($argv->{SEARCH_MAC}) {
    $search_mac = $argv->{SEARCH_MAC};
  }

#  $Sender->send_message({
#    TO_ADDRESS => '327930625',
#    MESSAGE    => 'message go!',
#    SENDER_TYPE=> 'Telegram',
#    #UID       => 1
#  });

#  $Events->events_add( {
#    # Name for module
#    MODULE      => 'Equipment',
#    # Text
#    COMMENTS    => 'PON',
#    # Link to see external info
#    EXTRA       => 'http://abills.net.ua',
#    # 1..5 Bigger is more important
#    PRIORITY_ID => 1,
#
#  } );
#
#  print "event done\n";

  if($debug > 7) {
    $Equipment->{debug}=1;
  }

  if ($argv->{NAS_IPS}) {
    $LIST_PARAMS{NAS_IP} = $argv->{NAS_IPS};
  }

  my $total_nas = 0;
  my $SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $equipment_list = $Equipment->_list( {
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 100000,
    SNMP_VERSION    => '_SHOW',
    NAS_ID          => '_SHOW',
    MODEL_ID        => '_SHOW',
    VENDOR_NAME     => '_SHOW',
    SNMP_TPL        => '_SHOW',
    TYPE_ID         => '_SHOW',
    NAS_IP          => '_SHOW',
    NAS_NAME        => '_SHOW',
    NAS_MNG_USER    => '_SHOW',
    MNG_HOST_PORT   => '_SHOW',
    NAS_MNG_PASSWORD=> '_SHOW',
    STATUS          => '0',
    %LIST_PARAMS
  } );

  foreach my $equip (@$equipment_list) {

    if(! $equip->{NAS_IP}) {
      if($debug > 0) {
        print "Equipment not found: $equip->{NAS_ID}\n";
      }
      next;
    }
    my $mac_list = $Equipment->mac_log_list({
      NAS_ID       => $equip->{NAS_ID},
      COLS_NAME    => 1,
      PAGE_ROWS    => 100000,
      MAC          => '_SHOW',
      VLAN         => '_SHOW',
      PORT         => '_SHOW',
      UNIX_DATETIME => '_SHOW',
      UNIX_REM_TIME => '_SHOW',
    });

    my %mac_log_hash = ();

    foreach my $list (@$mac_list) {
      $list->{port} =~ s/\./_/g;
      my $key = $list->{mac} . '_' . $list->{vlan} . '_' . $list->{port};
      $mac_log_hash{ $key }{id} = $list->{id};
      $mac_log_hash{ $key }{datetime} = $list->{unix_datetime} || 0;
      $mac_log_hash{ $key }{rem_time} = $list->{unix_rem_time} || 0;
    }

    if(! $argv->{SNMP_COMMUNITY} ) {
      $SNMP_COMMUNITY = ($equip->{NAS_MNG_PASSWORD} || '').'@'.(($equip->{NAS_MNG_IP_PORT}) ? $equip->{NAS_MNG_IP_PORT} : $equip->{NAS_IP});
    }
    $Log->log_print('LOG_INFO', '', "NAS_ID: $equip->{NAS_ID} NAS_NAME: ". ($equip->{NAS_NAME} || q{}));

    my $fdb_list = get_fdb({
      %$equip,
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      NAS_INFO       => $equip,
      DEBUG          => $debug,
      BASE_DIR       => $Bin,
      SKIP_TIMEOUT   => 1,
    });

    my @MAC_LOG_ADD = ();
    my @MAC_LOG_CHG = ();
    my $add_mac_count = 0;
    my $chg_mac_count = 0;
    foreach my $mac_dec (keys %$fdb_list) {
      my $mac = $fdb_list->{$mac_dec}{1} || q{};
      if ($debug > 2) {
        print 'MAC: '. $mac
          # 2 port
          .' Port: '.(($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{2}) ? $fdb_list->{$mac_dec}{2} : '')
          # 3 status
          # 4 vlan
          .' Vlan: '.(($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{4}) ? $fdb_list->{$mac_dec}{4} : '')
          # 5 vlan
          .' Port name: '.(($fdb_list->{$mac_dec} && $fdb_list->{$mac_dec}{5}) ? $fdb_list->{$mac_dec}{5} : '')
          ."\n";
      }

      if($mac eq '00:00:00:00:00:00') {
        next;
      }
      
      my $vlan = $fdb_list->{$mac_dec}{4} || 0;
      if ($vlan =~ /(\d+)\D+/ ) {
        $vlan = $1;
      }
      my %data = (
        NAS_ID => $equip->{NAS_ID},
        MAC    => $mac,
        VLAN   => $vlan,
        PORT   => $fdb_list->{$mac_dec}{2} || 0,
        PORT_NAME   => $fdb_list->{$mac_dec}{5} || '',
      );

#      if($search_mac && $data{MAC} && $data{MAC} =~ /$search_mac/) {
#        my %parameters = (
#          MODULE      => 'Equipment',
#          COMMENTS    => 'MAC GRABBER: '
#            . ' '. ($data{MAC} || q{})
#            . ' '. ($data{NAS_ID} || q{})
#            . ' '. ($data{VLAN} || q{})
#            . ' '. ($data{PORT} || q{})
#            . ' '. ($data{PORT_NAME} || q{}),
#          EXTRA       => 'http://abills.net.ua',
#          PRIORITY_ID => 0,
#        );
#
#        $Events->events_add( \%parameters );
#      }

#      $Equipment->mac_log_add({ %data, DATETIME => 1 });
      my $key = $data{MAC} . '_' . $data{VLAN} . '_' . $data{PORT};
      $key =~ s/\./_/g;
      if (ref $mac_log_hash{ $key } eq 'HASH' &&  $mac_log_hash{ $key }{id}) {
        $chg_mac_count++;
        push @MAC_LOG_CHG, [
          $mac_log_hash{ $key }{id}
        ];
        delete $mac_log_hash{ $key };
      }
      else {
        $add_mac_count++;
        push @MAC_LOG_ADD, [
            $data{MAC} || '',
            $data{NAS_ID} || '',
            $data{VLAN} || '',
            $data{PORT} || 0,
            $data{PORT_NAME} || '',
        ];
      }
    }

    my $time;

    if ($#MAC_LOG_ADD > -1) {
      $time = check_time() if ($debug > 2);
      print "Add NEW MACS COUNT:$add_mac_count" if ($debug > 2);
      $Equipment->mac_log_add( {  MULTI_QUERY => \@MAC_LOG_ADD } );
      print " " . gen_time($time) . "\n" if ($debug > 2);     
    }

    $add_mac_count=0;
    if($#MAC_LOG_CHG > -1) {
      $time = check_time() if ($debug > 2);
      print "UPDATE MACS COUNT:$chg_mac_count" if ($debug > 2);
      $Equipment->mac_log_change( { MULTI_QUERY => \@MAC_LOG_CHG } );
      print " " . gen_time($time) . "\n" if ($debug > 2);
    }

    $chg_mac_count=0;
    @MAC_LOG_CHG = ();
    foreach my $key (keys %mac_log_hash) {
      if ( $mac_log_hash{ $key }{datetime} >= $mac_log_hash{ $key }{rem_time}) {
        $chg_mac_count++;
        push @MAC_LOG_CHG, [
          $mac_log_hash{ $key }{id}
        ];
      }
    }

    if($#MAC_LOG_CHG > -1) {
      $time = check_time() if ($debug > 2);
      print "UPDATE EXPIRED MACS COUNT:$chg_mac_count" if ($debug > 2);
      $Equipment->mac_log_change( { REM_TIME => 1,  MULTI_QUERY => \@MAC_LOG_CHG } );
      print " " . gen_time($time) . "\n" if ($debug > 2);
    }

    $chg_mac_count=0;
    @MAC_LOG_CHG = ();
    $total_nas++;
  }

  print "Total NAS: $total_nas\n\n" if($debug);

  return 1;
}


1
