#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

BEGIN {
  use FindBin '$Bin';

  my $inner_pos = 0;

  my @folders = split ('/', $Bin);

  foreach my $folder (@folders){
    last if ($folder eq 'abills');
    $inner_pos += 1;
  }

  my $libpath = "$Bin/" . "../" x $inner_pos;

  unshift ( @INC, $libpath,
   $libpath . 'Abills/',
   $libpath . 'Abills/mysql/',
   $libpath . 'Abills/Control/',
   $libpath . 'lib/'
  );
}

our (%conf);

require "libexec/config.pl";

use Admins;
use Abills::SQL;
use Abills::Base qw(parse_arguments _bp);

use Abills::Nas::Mikrotik;
use Nas;
use Dhcphosts;

# System initialization
my $db = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf } );
my $admin = Admins->new( $db, \%conf );
$admin->info( $conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
  { IP => '127.0.0.1', SHORT => 1 } );

# Modules initialisation
my $Nas = Nas->new( $db, \%conf );
my $Dhcphosts = Dhcphosts->new( $db, $admin, \%conf );

# Local globals
my %ARGS = ();
my $debug = 0;

my $networks_list = [ ];

exit main() ? 0 : 1;

#**********************************************************
=head2 main() - Parse arguments, check parameters, etc

=cut
#**********************************************************
sub main{
  %ARGS = %{ parse_arguments( \@ARGV ) };
  die ( "Need NAS_IDS" ) unless ($ARGS{NAS_IDS});

  $debug = $ARGS{DEBUG} if ( defined $ARGS{DEBUG} );
  $ARGS{VERBOSE} = $ARGS{VERBOSE} || 0;

  if ( $ARGS{NAS_IDS} =~ /-/ ){
    die( "Setting NAS_ID via range is not implemented" );
  }

  #  $Nas->{debug} = 1;
  my $nas_list = $Nas->list( { NAS_ID => $ARGS{NAS_IDS}, DISABLED => '0', COLS_NAME => 1 } );

  unless ( defined $nas_list && scalar( @{$nas_list} ) > 0 ){
    die ( " !!! NAS not found" );
  }

  prepare();

  my $result = 0;
  foreach my $nas ( @{$nas_list} ){
    # Skip non-mikrotik NASes
    next unless ($nas->{nas_type} =~ 'mikrotik');

    my Abills::Nas::Mikrotik $mikrotik = Abills::Nas::Mikrotik->new( $nas, \%conf, { DEBUG => $debug } );
    unless ( $mikrotik->has_access() ){
      print ( "!!! $nas->{nas_name} (ID: $nas->{nas_id}) is not accessible\n" );
      return 0;
    };

    my $operation_type = 'Syncing';
    if ( $ARGS{CLEAN} ){
      $operation_type = "Removing all generated";
      $result = ( $mikrotik->remove_all_generated_leases() );
    }
    elsif ( $ARGS{RECONFIGURE} ){
      $operation_type = "Reconfiguring all generated";
      $result = ( $mikrotik->remove_all_generated_leases() && sync_leases( $mikrotik, $nas ) );
    }
    else{
      $result = sync_leases( $mikrotik, $nas, \%ARGS );
    }

    print ( "$operation_type leases for NAS $nas->{nas_id} fininished " );
    print ( ($result) ? "successfully" : "with errors !!! " );
    print "\n\n";
  }

  return $result;
}

#**********************************************************
=head2 prepare($attr) - get all shared params

  Arguments:
    $attr - hash_ref

  Returns:
    1;
=cut
#**********************************************************
sub prepare{

  $networks_list = $Dhcphosts->networks_list(
    {
      DISABLE   => 0,
      NAME      => '_SHOW',
      PAGE_ROWS => 10000,
      SORT      => 2,
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME => 1
    }
  );
  if (!$networks_list || scalar @$networks_list < 1 ){
    die "No dhcphosts networks configured \n";
  };

  return 1;
}

#**********************************************************
=head2 sync_leases($attr)

  Arguments:
  $nas - hash_ref (line from DB list)
  $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub sync_leases{
  my ($mikrotik, $nas, $attr) = @_;

  my $nas_id = $nas->{nas_id};
  $networks_list = $mikrotik->check_dhcp_servers( $networks_list, $attr );

  my $db_leases = db_leases_list( $nas_id );
  return 0 if ( scalar @{$db_leases} <= 0 );

  my $mikrotik_leases = $mikrotik->leases_list( $attr );

  # Sort mikrotik leases by MAC
  my %mikrotik_leases_by_mac = ();
  foreach my $line ( @{$mikrotik_leases} ){
    $mikrotik_leases_by_mac{lc $line->{"mac-address"}} = $line;
  }

  my %db_leases_by_mac = ();
  foreach my $line ( @{$db_leases} ){
    $db_leases_by_mac{lc $line->{mac}} = $line;
  }

  # Compare leases from mikrotik and DB
  my @mikrotik_to_delete_leases_ids = ();
  my @mikrotik_to_add_leases = ();
  foreach my $host_mac ( keys ( %db_leases_by_mac ) ){
    print "$host_mac - ipn_activated $db_leases_by_mac{$host_mac}->{ipn_activate} \n" if ($ARGS{VERBOSE} > 1);
    if ( !defined $mikrotik_leases_by_mac{$host_mac} ){
      print "Mikrotik don't have lease $host_mac\n" if ($ARGS{VERBOSE});
      push ( @mikrotik_to_add_leases, $db_leases_by_mac{$host_mac} );
    }
    #    if ( !$db_leases_by_mac{$host_mac}->{active} ){
    #      # If disabled, delete allow lease, cause will be added with negative addrress-list
    #      print "Mikrotik have allowing lease $host_mac that should be disabled. \n" if ($ARGS{VERBOSE});
    #      push ( @mikrotik_to_delete_leases_ids, $db_leases_by_mac{$host_mac}->{id} );
    #      push ( @mikrotik_to_add_leases, $db_leases_by_mac{$host_mac} );
    #    }
    delete $db_leases_by_mac{$host_mac};
    delete $mikrotik_leases_by_mac{$host_mac};
  }

  # Delete all other leases
  foreach my $lease_mac ( keys ( %mikrotik_leases_by_mac ) ){
    push ( @mikrotik_to_delete_leases_ids, $mikrotik_leases_by_mac{$lease_mac}->{id} );
  }

  _bp( "Leases to delete", \@mikrotik_to_delete_leases_ids, { TO_CONSOLE => 1, EXIT => 0 } ) if ($debug);
  _bp( "Leases to add", \@mikrotik_to_add_leases, { TO_CONSOLE => 1, EXIT => 0 } ) if ($debug);

  return 1 if ($debug > 6);

  my $number_to_remove = scalar @mikrotik_to_delete_leases_ids;
  my $number_to_add = scalar @mikrotik_to_add_leases;

  print "Removing $number_to_remove leases \n" if ($ARGS{VERBOSE});
  my $remove_result = $mikrotik->remove_leases( \@mikrotik_to_delete_leases_ids, \%ARGS );

  print "Adding $number_to_add new leases \n" if ($ARGS{VERBOSE});
  my $add_result = $mikrotik->add_leases( \@mikrotik_to_add_leases, \%ARGS );

  return ($remove_result && $add_result);
}

#**********************************************************
=head2 current_leases_list($nas_id) - Get leases from Dhcphosts for given NAS

  Arguments:
    $nas_id - NAS_ID
    $attr

  Returns:
    list

=cut
#**********************************************************
sub db_leases_list{
  my ($nas_id) = @_;

  # Get leases from DB
  my @db_leases = ();
  foreach my $network ( @{$networks_list} ){
    #        $Dhcphosts->{debug} = 1;
    my $network_hosts_list = $Dhcphosts->hosts_list(
      {
        NETWORK      => '_SHOW',
        NETWORK_NAME => '_SHOW',
        STATUS       => '_SHOW',
        USER_DISABLE => 0,
        LOGIN        => '_SHOW',
        TP_TP_ID     => '_SHOW',
        TP_NAME      => '_SHOW',
        IPN_ACTIVATE => 1,
        MAC          => '_SHOW',
        IP           => '_SHOW',
        NAS_ID       => $nas_id,
        NAS_NAME     => '_SHOW',
        OPTION_82    => '_SHOW',
        DELETED      => 0,
        #  CREDIT       => '_SHOW',
        #  HOSTNAME     => '_SHOW',
        #  PORTS        => '_SHOW',
        #  VID          => '_SHOW',
        #  BOOT_FILE    => '_SHOW',
        #  NEXT_SERVER  => '_SHOW',
        #  %PARAMS,
        COLS_NAME    => 1,
        PAGE_ROWS    => 100000,
      }
    );

    unless ( defined $network_hosts_list ){
      print " !!! No hosts configured for NAS_ID: $nas_id \n";
      return [ ];
    }

    push @db_leases, @{$network_hosts_list};
  };

  _bp( "Network leases", \@db_leases, { TO_CONSOLE => 1 } ) if ($debug);

  return \@db_leases;
}

#**********************************************************
=head2 add_single_lease($ip, $mac)

  Arguments:
    $ip, $mac -

  Returns:

=cut
#**********************************************************
sub add_single_lease{
  my ($ip, $mac) = @_;

}

#**********************************************************
=head2 disable_single_lease($mac)

  Arguments:
    $mac -

  Returns:

=cut
#**********************************************************
sub disable_single_lease{
  my ($mac) = @_;

}


1;