#!/usr/bin/perl

use strict;
use warnings;
use Test::Simple tests => 5;
use Benchmark qw/:all/;
use FindBin '$Bin';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  eval { require Time::HiRes; };
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

our (
  $Bin,
  %conf,
  @MODULES,
  %functions,
  %module,
  %FORM,
  $users,
  $global_begin_time,
  $admin
);

use Abills::SQL;
use Admins;

do 'libexec/config.pl';

my $db    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, \%conf);
my $Admin = Admins->new( $db, \%conf );

changes_bench();


sub changes_bench {
  my $count = 2000;
  my $i=0;
  timethis($count, sub{
    #$Admin->{debug}=1;
    $Admin->changes({
      CHANGE_PARAM => 'PARAM',
      TABLE        => 'config',
      DATA         => {
        PARAM => 'test',
        VALUE => $i++
      }
    })
  });

  return 1;
}


1;