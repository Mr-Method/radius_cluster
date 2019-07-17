# billd plugin
#**********************************************************
=head1
  Standart execute
    /usr/abills/libexec/billd paysys_periodic

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
unshift(@INC, '../Abills/'); #/usr/abills/Abills/

our $html = Abills::HTML->new( { CONF => \%conf } );
our (
  $db,
  $admin,
  $Admin,
  %conf,
  %lang,
  $debug,
  $argv,
  $libpath,
  $DATE,
);

require Abills::Misc;
require Abills::Base;
use Users;
$admin = $Admin;
$debug = $argv->{DEBUG} || 1;

our $users = Users->new($db, $admin, \%conf);

do "/usr/abills/language/$conf{default_language}.pl";

load_module('Paysys', $html);
my $version = 7.0;

print "Billd plugin for paysys peridic starting. \n\n";

paysys_periodic_new({DEBUG => $debug, DATE => $DATE});

print "Billd plugin for paysys peridic stoped. \n\n";