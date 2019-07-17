#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

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

our ($db, $admin, %conf, %FORM, $DATE, $TIME);
require_ok 'libexec/config.pl';
#use_ok('Cams');


open(my $null_fh, '>', '/dev/null') or die('Open /dev/null');
select $null_fh;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=abills&passwd=abills";
require_ok( "../cgi-bin/admin/index.cgi" );
select STDOUT;

use Nas;
my $Nas = Nas->new($db, \%conf, $admin);

my $debug = 0;
my $test_comment = "ABills test. you can remove this";

use_ok( 'Abills::Base' );
use_ok( 'Abills::Nas::Mikrotik' );

my $TEST_NAS_ID = 2;

my $test_host = $Nas->info({NAS_ID => $TEST_NAS_ID});

my $mt = Abills::Nas::Mikrotik->new( $test_host,
  undef,
  { DEBUG => $debug, backend => 'ssh' } );

ok( ref $mt eq 'Abills::Nas::Mikrotik', "Constructor returned Abills::Nas::Mikrotik object" );
if ( !ok( $mt->has_access(), "Has access to $test_host->{nas_mng_ip_port}" ) ){
  die ( "Host is not accesible\n" );
}

done_testing();

