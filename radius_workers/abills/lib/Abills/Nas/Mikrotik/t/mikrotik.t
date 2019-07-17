#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 10;

BEGIN{
  unshift ( @INC, "../../" );
  unshift ( @INC, "../../misc/mikrotik" );
}

my $debug = 0;
my $test_host = '192.168.0.11';

my $test_comment = "ABills test. you can remove this";
my $test_mac = '12:34:56:78:90:CC';
my %test_lease = (ip => '192.168.2.9', mac => $test_mac, tp_tp_id => '2', network => '1');

require_ok( 'Abills::Base' );
require_ok( 'Abills::Nas::Mikrotik' );

my $mikrotik = Abills::Nas::Mikrotik->new( { nas_mng_ip_port => "$test_host:0:22", }, undef, { DEBUG => $debug } );

ok( ref $mikrotik eq 'Abills::Nas::Mikrotik', "Constructor returned Abills::Nas::Mikrotik object" );
if ( !ok( $mikrotik->check_access(), "Has access to $test_host" ) ){
  die ( "Host is not accesible\n" );
}

# Add lease
ok ( $mikrotik->add_leases( [ \%test_lease ], { SKIP_DHCP_NAME => 1, VERBOSE => $debug, SHOW_RESULT => 1 } ),
  "Successfully added new lease" );

# Check lease is really present
my $leases_list = $mikrotik->leases_list();
ok( is_correct_list( $leases_list ), "Returned correct list for leases" );
my $lease_id = get_id( $leases_list, 'mac-address', $test_mac );

if ( ok( $lease_id != -1, "Added lease has been found on mikrotik" ) ){
  # Remove it
  ok( $mikrotik->remove_leases( [ $lease_id ] ), "Removed lease with id $lease_id" );
};

# get list of ip addresses
my $ip_addresses_list = $mikrotik->get_list( 'ip_a' );

# check it's size is greater than 0;
ok( is_correct_list( $leases_list ), "Returned correct list for ip addresses" );

# check it contains host ip address
ok ( get_id( $ip_addresses_list, 'address', $test_host, { REGEXP => 1 } ) != -1,
  "Found address we are communicating with" );

sub get_id{
  my ($list, $uniq_key, $val, $attr) = @_;

  unless ( defined $uniq_key && $val ){
    print " !!! Error: incorrect usage " . caller;
  }
  unless ( exists $list->[0]->{$uniq_key} ){
    my $all_keys = join( ", ", keys %{$list->[0]} );
    print " !!! Incorrect unique value : $uniq_key";
    print "    Keys present: " . $all_keys;
    return -1;
  }

  if ( $attr->{REGEXP} ){
    foreach my $line ( @{$list} ){
      print "($line->{$uniq_key} eq $val); \n" if ($debug);
      return $line->{id} if ( uc $line->{$uniq_key} =~ uc $val);
    }
  }
  else{
    foreach my $line ( @{$list} ){
      print "($line->{$uniq_key} eq $val); \n" if ($debug);
      return $line->{id} if ( uc $line->{$uniq_key} eq uc $val);
    }
  }
  return -1;
}

sub is_correct_list{
  my ($list) = @_;
  return (scalar @{$list} > 0) && ref $list->[0] eq 'HASH';
}

done_testing();

