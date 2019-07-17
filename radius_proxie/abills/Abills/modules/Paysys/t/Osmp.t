#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 12;
use Data::Dumper;

our (%FORM, %LIST_PARAMS, %functions, %conf, $html, %lang, @_COLORS,);

BEGIN {
  our $libpath = '../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}
require "libexec/config.pl";
$conf{language} = 'english';
do "language/$conf{language}.pl";
do "/usr/abills/Abills/modules/Paysys/lng_$conf{language}.pl";
use_ok('Paysys');
use_ok('Paysys::systems::Osmp');
use_ok('Conf');
use_ok('Abills::Base', qw/mk_unique_value /);
use Abills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);
my $user_id = $ARGV[0] || '1';

my $random_number = int(rand(1000));
my $Osmp = Paysys::systems::Osmp->new($db, $admin, \%conf, {
        CUSTOM_NAME => $ARGV[1] || '',
        CUSTOM_ID   => $ARGV[2] || '',
      });
# _bp('', $Osmp, {HEADER => 1, TO_CONSOLE => 1});
# checking function check with valid account
my $result = $Osmp->proccess(
  {
    account => "$user_id",
    command => 'check',
    sum     => '1.00',
    txn_id  => "$random_number",
    test    => 1,
  }
);
my $res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '0', 'User Exist(function check)');

# checking function check with invalid account
$result = $Osmp->proccess(
  {
    account => '1232124',
    command => 'check',
    sum     => '1.00',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '5', 'User not Exist(function check)');

# checking function check without one parameter
$result = $Osmp->proccess(
  {
    account => "$user_id",
    command => 'check',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '300', "There isn't attr summ(function check)");

# checking function pay with valid account
$result = $Osmp->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
my $prv_txn_id1 = '';
($res)         = ($result =~ /\<result\>(\d+)\<\/result\>/g);
($prv_txn_id1) = ($result =~ /\<prv_txn\>(\d+)\<\/prv_txn\>/g);
ok($res eq '0', "Payment completed(function pay)");

# checking function pay with invalid account
$result = $Osmp->proccess(
  {
    account => '1232124',
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '5', "Not exist user(function pay)checking with not existed account");

# checking function pay without one parameter
$result = $Osmp->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '300', "There isn't attr sum(function pay)");

# checking function pay with valid account again
$result = $Osmp->proccess(
  {
    account => "$user_id",
    command => 'pay',
    txn_id  => "$random_number",
    sum     => '1.00',
    test    => 1,
  }
);
$res = '';
my $prv_txn_id2 = '';
($res)         = ($result =~ /\<result\>(\d+)\<\/result\>/g);
($prv_txn_id2) = ($result =~ /\<prv_txn\>(\d+)\<\/prv_txn\>/g);
ok($prv_txn_id1 && $prv_txn_id2 &&"$prv_txn_id1" eq "$prv_txn_id2", "Payment exist (function pay) checking with same Transaction");

# checking function cancel
if ($prv_txn_id1) { 
$result = $Osmp->proccess(
  {
    command => 'cancel',
    prv_txn => "$prv_txn_id1",
    test    => 1,
  }
);
$res = '';
($res) = ($result =~ /\<result\>(\d+)\<\/result\>/g);
ok($res eq '0', 'Transaction was canceled(function cancel)');
}
else {
  print "You entered incorrect parameter!!!!!!!!!!!\n";
}