#!/usr/bin/perl -w

=head1 NAME

 Paysys tests

=cut

use strict;
use warnings;
use Test::More tests => 8;
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
use_ok('Paysys::systems::24_non_stop');
use_ok('Conf');
use_ok('Abills::Base', qw/mk_unique_value /);
use Abills::Init qw/$db $admin $users/;
use Paysys;
my $Conf = Conf->new($db, $admin, \%conf);
my $user_id = $ARGV[0] || '1';

my $random_number = int(rand(1000));

my $_24_NS = Paysys::systems::24_non_stop->new($db, $admin, \%conf, {
    CUSTOM_NAME => $ARGV[1] || '',
    CUSTOM_ID   => $ARGV[2] || '',
  });

my $user_exist_responce = $_24_NS->proccess(
  {
    ACT         => 1,
    PAY_ACCOUNT => 1,
    SERVICE_ID  => 1,
    PAY_ID      => $random_number,
    SIGN        => '',
    test        => 1,
  }
);

my $res = '';
($res) = ($user_exist_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
ok($res eq '21', 'User Exist(function ACT 1)');

my $user_not_exist_responce = $_24_NS->proccess(
  {
    ACT         => 1,
    PAY_ACCOUNT => 1234554321,
    SERVICE_ID  => 1,
    PAY_ID      => $random_number,
    SIGN        => '',
    test        => 1,
  }
);
($res) = ($user_not_exist_responce =~ /\<status_code\>(-\d+)\<\/status_code\>/g);
ok($res && $res eq '-40', 'User Not Exist(function ACT 1)');

my $success_payment_responce = $_24_NS->proccess(
  {
    ACT         => 4,
    PAY_ACCOUNT => 1,
    SERVICE_ID  => 1,
    PAY_ID      => $random_number,
    SIGN        => '',
    PAY_AMOUNT  => 1.00,
    test        => 1,
  }
);

#_bp("", $success_payment_responce, {TO_CONSOLE => 1});
($res) = ($success_payment_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
ok($res && $res eq '22', 'Success payment(function ACT 4)');

my $confirm_responce = $_24_NS->proccess(
  {
    ACT         => 7,
    PAY_ACCOUNT => 1,
    SERVICE_ID  => 1,
    PAY_ID      => $random_number,
    SIGN        => '',
    PAY_AMOUNT  => 1.00,
    test        => 1,
  }
);

($res) = ($confirm_responce =~ /\<status_code\>(\d+)\<\/status_code\>/g);
ok($res && $res eq '11', 'Confirm payment(function ACT 7)');