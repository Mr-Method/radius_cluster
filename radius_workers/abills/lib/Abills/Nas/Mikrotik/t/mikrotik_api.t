#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;

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

use Abills::Base qw /_bp/;
use_ok( 'Abills::Nas::Mikrotik' );

our %conf;
our $base_dir;
require_ok("libexec/config.pl");

my $test_host = {
  nas_mng_ip_port => "192.168.1.235:0:8728",
  nas_type        => 'mikrotik',
  nas_mng_user    => 'admin',
  nas_mng_password => ''
};

my $mt = Abills::Nas::Mikrotik->new( $test_host, \%conf, {
    backend => 'api',
    DEBUG   => 5,

  } );

is( ref $mt, 'Abills::Nas::Mikrotik' , 'Got Abills::Nas::Mikrotik object' );

can_ok( 'Abills::Nas::Mikrotik', qw/
    has_access
    get_list
    interfaces_list
    addresses_list
    leases_list
    remove_leases
    add_leases
    remove_all_generated_leases
    check_dhcp_servers
    check_defined_networks
    configure_hotspot
    / );

ok ($mt->has_access(), 'Has access to mikrotik via API');
ok (scalar @{$mt->interfaces_list()}, 'Can get interfaces');

my $addresses = $mt->addresses_list();
ok(scalar @{$addresses}, 'Can get IP addresses');

# Check addresses contains address we are talking
my $got_address = 0;
foreach my $element ( @{$addresses} ) {
  if ($element->{address} =~ $mt->{executor}{host}){ $got_address = 1; last };
}

ok($got_address, 'Addresses contains address we are talking');

# Execute custom command
ok($mt->{executor}->execute(['/ip address print ']), 'Custom command execution');
ok($mt->{executor}->execute(['/ip/hotspot/service-port/print',{},{name => 'ftp'}]));


done_testing();

