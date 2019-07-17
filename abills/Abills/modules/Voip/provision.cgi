#!/usr/bin/perl -w
# Provision 

use vars qw( $db $DATE $TIME $var_dir %log_levels $domain_path $html);
#use strict;

BEGIN {
 my $libpath = '../';
 
 my $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath ."Abills/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 

# eval { require Time::HiRes; };
# if (! $@) {
#    Time::HiRes->import(qw(gettimeofday));
#    $begin_time = gettimeofday();
#   }
# else {
#    $begin_time = 0;
#  }
}



require "config.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Nas;
use Voip;

$html = Abills::HTML->new( { IMG_PATH => 'img/',
	                           NO_PRINT => 1,
	                           CONF     => \%conf,
	                           CHARSET  => $conf{default_charset},
	                       });

my $sql = Abills::SQL->connect($conf{dbtype}, 
                               $conf{dbhost}, 
                               $conf{dbname}, 
                               $conf{dbuser}, 
                               $conf{dbpasswd},
                               { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
$db = $sql->{db};

my $version  = '0.4';
my $debug    = 0;
my $log_file = $var_dir."log/wrt_configure.log";
$domain_path = '';

$html->{language}='english';

if ($FORM{test}) {
	print "Content-Type: text/plain\n\n";
	print "Test OK $DATE $TIME";
#	exit;
}

require "Abills/templates.pl";
my $Nas  = Nas->new($db, \%conf);
my $Voip = Voip->new($db, undef, \%conf);
# номер модели
#PN =>  $FORM{PN},
# Mac
#MAC=> $FORM{MAC},
# Serial number
#SN => $FORM{SN}

$Nas->info({ IP             => $FORM{IP} || $ENV{REMOTE_ADDR},
             NAS_IDENTIFIER => "$FORM{SN}", 
          });

if (! $Nas->{NAS_IDENTIFIER} || ! $FORM{SN} ) {
	print "Content-Type: text/plain\n\n";
	print "Wrong nas ($Nas->{NAS_IDENTIFIER} / $FORM{SN})\n";
	exit;
}

print "Content-Type: text/xml\n\n";
my $list = $Voip->user_list({ PROVISION_NAS_ID => $Nas->{NAS_ID},
                              PROVISION_PORT   => '>0',
                              PASSWORD         => '_SHOW',
                              CID              => '_SHOW',
                              SERVICE_STATUS   => '_SHOW',
                              NUMBER           => '_SHOW',
                              COLS_NAME        => 1
                            });

my %info = ();

foreach my $line (@$list) {
  $info{'Password_'. $line->{provision_port} .'_'}  = $line->{password};
  $info{'Auth_ID_'. $line->{provision_port} .'_'}   = $line->{number};
  $info{'Caller_ID_'. $line->{provision_port} .'_'} = $line->{CID};
  $info{'Line_'. $line->{provision_port} .'_Status'}= ($line->{voip_status}) ? 'no' : 'yes'; 
}


print $html->tpl_show(_include('voip_provision_xml', 'Voip'), { %FORM, %info });
