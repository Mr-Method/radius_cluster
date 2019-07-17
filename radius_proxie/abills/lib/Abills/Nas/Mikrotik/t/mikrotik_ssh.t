#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;

my $libpath = '';
BEGIN{
  use FindBin '$Bin';
  $libpath = $Bin . '/../../../../'; # Assuming we are in /usr/abills/lib/Abills/Nas/Mikrotik/t
}

use lib $libpath . '/';
use lib $libpath . '/lib';
use lib $libpath . '/lib/Abills';
use lib $libpath . '/lib/Abills/Nas';
use lib $libpath . '/Abills';
use lib $libpath . '/Abills/mysql';


my $debug = 0;

my $test_comment = "ABills test. you can remove this";

my $test_add_lease_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=dhcp1 disabled=yes comment=\"$test_comment\"";
my $test_add_lease_bad_command = "/ip dhcp-server lease add address=192.168.0.2 mac-address=00:27:22:E8:40:F3 server=dhasdsdfcp1 disabled=yes comment=\"$test_comment\"";
my $remove_lease_command = "/ip dhcp-server lease remove numbers=[find comment=\"$test_comment\"]";

use_ok( 'Abills::Base' );
use_ok( 'Abills::Nas::Mikrotik' );


my $test_host = {
  nas_mng_ip_port => "192.168.1.235:0:22",
  nas_type        => 'mikrotik',
  nas_mng_user    => 'abills_admin',
};

my $mt = Abills::Nas::Mikrotik->new( $test_host,
  undef,
  { DEBUG => $debug, backend => 'ssh' } );

ok( ref $mt eq 'Abills::Nas::Mikrotik', "Constructor returned Abills::Nas::Mikrotik object" );
if ( !ok( $mt->has_access(), "Has access to $test_host->{nas_mng_ip_port}" ) ){
  die ( "Host is not accesible\n" );
}
ok( $mt->execute( "/system identity print" ), "Execute single" );
ok( $mt->execute( [ "/system identity print", "system resource cpu print" ] ), "Execute 2 commands" );
ok( !$mt->execute( [ "/some undefined command" ] ), "Holding errors (Executing bad command)" );

my $ip_addresses = $mt->get_list( 'ip_a' );
ok( scalar ( @{$ip_addresses} ) > 0, "Got non-empty list of IP addresses" );
ok ( ref $ip_addresses->[0] eq 'HASH', "List contains hashes" );

my $dhcp_servers_list = $mt->get_list( 'dhcp_servers' );
ok( scalar ( @{$dhcp_servers_list} ) > 0, "Got non-empty list of DHCP-Servers" );
ok ( ref $dhcp_servers_list->[0] eq 'HASH', "List contains hashes" );

ok( $mt->execute( $test_add_lease_command ), "Added lease" );

my $leases_list = $mt->get_list( 'dhcp_leases' );
ok( scalar ( @{$leases_list} ) > 0, "Got non-empty list of leases" );
ok ( ref $leases_list->[0] eq 'HASH', "List contains hashes" );

ok( $mt->execute( $remove_lease_command ), "Removed test lease" );
ok( $mt->execute( $test_add_lease_bad_command ) == 0, "Added lease with bad dhcp-server name throws error" );

done_testing();

