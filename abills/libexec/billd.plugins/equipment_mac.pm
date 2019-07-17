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
use Abills::Base qw(in_array);
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
my $Events = Events->new($db, $Admin, \%conf);
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
  if ($debug > 7) {
    $Equipment->{debug} = 1;
  }

  my $total_nas = 0;
  my $SNMP_COMMUNITY = $argv->{SNMP_COMMUNITY} || $conf{EQUIPMENT_SNMP_COMMUNITY_RO};
  my $equipment_list = $Equipment->_list( {
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 100000,
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
    if(! $argv->{SNMP_COMMUNITY} ) {
      $SNMP_COMMUNITY = ($equip->{NAS_MNG_PASSWORD} || '').'@'.(($equip->{NAS_MNG_IP_PORT}) ? $equip->{NAS_MNG_IP_PORT} : $equip->{NAS_IP});
    }

    $Log->log_print('LOG_INFO', '', "NAS_ID: $equip->{NAS_ID} NAS_NAME: $equip->{NAS_NAME}");

    my $fdb_list = get_fdb({
      %$equip,
      SNMP_COMMUNITY => $SNMP_COMMUNITY,
      NAS_INFO       => $equip,
      DEBUG          => $debug,
      BASE_DIR       => $Bin,
      #SNMP_TPL       => $attr->{SNMP_TPL},
      #FILTER         => $attr->{FILTER} || ''
    });

    foreach my $mac_dec (keys %$fdb_list) {
      my $mac = $fdb_list->{$mac_dec}{1} || q{};
      if ($debug > 2) {
        print $mac
          # 2 port
          .' Port: '.$fdb_list->{$mac_dec}{2}
          # 3 status
          # 4 vlan
          .'Vlan: '.($fdb_list->{$mac_dec}{4} || '')
          ."\n";
      }

      if($mac eq '00:00:00:00:00:00') {
        next;
      }

      my %data = (
        NAS_ID => $equip->{NAS_ID},
        MAC    => $mac,
        VLAN   => $fdb_list->{$mac_dec}{4} || 0,
        PORT   => $fdb_list->{$mac_dec}{2} || 0,
      );

      if($search_mac && $data{MAC} && $data{MAC} =~ /$search_mac/) {
        my %parameters = (
          MODULE      => 'Equipment',
          COMMENTS    => 'MAC GRABBER: '
            . ' '. ($data{MAC} || q{})
            . ' '. ($data{NAS_ID} || q{})
            . ' '. ($data{VLAN} || q{})
            . ' '. ($data{PORT} || q{}),
          EXTRA       => 'http://abills.net.ua',
          PRIORITY_ID => 0,
        );

        $Events->events_add( \%parameters );
      }

      $Equipment->mac_log_add({ %data, DATETIME => 1 });
    }

    $total_nas++;
  }

  print "Total: $total_nas\n\n" if($debug);
  return 1;
}


1
