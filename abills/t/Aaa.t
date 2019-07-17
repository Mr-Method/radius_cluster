#!/usr/bin/perl

=head1 NAME

  Mac_auth test

=cut

BEGIN {
  use FindBin '$Bin';
  unshift(@INC, $Bin."/../libexec/");

  do "config.pl";

  unshift(@INC,
    $Bin."/../lib/",
    $Bin."/../Abills/$conf{dbtype}");
}

use warnings;
use strict;
use Test::Simple tests => 5;
use Memoize;
use Benchmark qw/:all/;
use threads;

our (
  %conf,
  %AUTH,
  %RAD_REQUEST,
  %RAD_REPLY,
  %RAD_CHECK,
  $begin_time
);

use Abills::Base qw(check_time parse_arguments mk_unique_value);
use Abills::SQL;

$begin_time = check_time();
my $db    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, \%conf);
my $argv  = parse_arguments(\@ARGV);

my $debug = $argv->{debug} || 1;
my $count = $argv->{count} || 1000; #24000; # Test iterations.

if ($argv->{nas}) {
  get_nas_info();
}
elsif ($argv->{get_ip}) {
  #get_ip_();
}
elsif ($argv->{online_add}) {
  #online_add();
}
elsif (defined($argv->{rad_auth})) {
  _rad({ auth => 1 });
}
elsif (defined($argv->{dhcp_test})) {
  _rad({ dhcp_test => 1 });
  #mac_auth();
}
elsif (defined($argv->{rad_acct})) {
  _rad({ acct => 1 });
}
elsif (defined($argv->{unifi})) {
  unifi();
}
elsif(defined($argv->{help})) {
  print "Select test\n";
  help();
}
else {
  _rad();
}

#**********************************************************
=head2 umac_auth()

=cut
#**********************************************************
sub mac_auth{
  print "Mac_auth test\n";

  my $rad_pairs;
  if ( $ARGV[1] ) {
    $rad_pairs = load_rad_pairs( $ARGV[1] );
  }

  %RAD_REQUEST = %{ $rad_pairs };
  $Bin = $Bin .'/../libexec/';
  require "Mac_auth.pm";
  require "rlm_perl.pl";

  post_auth();

  show_reply(\%RAD_REPLY);

  return 1;
}


#**********************************************************
=head2 show_reply($RAD_REPLY)

=cut
#**********************************************************
sub show_reply{
  my($RAD_REPLY)=@_;
  print "RAD_REPLY:\n";

  foreach my $k (sort keys %$RAD_REPLY) {
    my $v = $RAD_REPLY->{$k};
    if ( ref $v eq 'ARRAY' ){
      foreach my $value (@$v) {
        print "  $k -> $value\n";
      }
    }
    else{
      print "  $k -> $v\n";
    }
  }
  print "\n";

  return 1;
}

#**********************************************************
=head2 unifi()

=cut
#**********************************************************
sub unifi {

  my ($username,
   $password,
   $userip,
   $usermac,
  ) =
  ( 'test',
    '123456',
    '192.168.100.11',
    '00:22:33:44:55:66',
  );

  $conf{'UNIFI_IP'} = '91.244.127.232';
  $debug = 0;

  my %RAD = (
        'Acct-Status-Type'   => 1,
        'User-Name'          => $username,
        'Password'           => $password,
        'Acct-Session-Id'    => '_id' || mk_unique_value(10),
        'Framed-IP-Address'  => $userip || '',
        'Calling-Station-Id' => $usermac || '',
        'Called-Station-Id'  => 'ap_mac',
        'NAS-IP-Address'     => $conf{'UNIFI_IP'},
        #'NAS-Port'          => $Dv->{PORT},
        #'Filter-Id'         => $Dv->{FILTER_ID} || $Dv->{TP_FILTER_ID},
        'Connect-Info'       => '_id',
    );

  require Abills::SQL;
  Abills::SQL->import();
  require Nas;
  Nas->import();

  require Auth;
  Auth->import();
  $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { %conf, CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

  my $Auth = Auth->new($db, \%conf);
  my $Nas = Nas->new($db, \%conf);

  if ($debug) {
    $Auth->{debug} = 1;
    $Nas->{debug}  = 1;
  }

  $Nas->info({
    IP     => $conf{'UNIFI_IP'},
    #NAS_ID => $RAD->{'NAS-Identifier'}
  });

  my ($r, $RAD_PAIRS) = $Auth->dv_auth(\%RAD, $Nas, { SECRETKEY => $conf{secretkey} });

  my $text = "Result: ($r) ". (($r) ? 'fail' : 'ok' ) ."\n";
  foreach my $key (keys %$RAD_PAIRS) {
    $text .= "$key -> $RAD_PAIRS->{$key}\n";
  }

  print $text;

  return 1;
}

#**********************************************************
=head2 _rad($attr) - Base AAA test

=cut
#**********************************************************
sub _rad {
  my ($attr)=@_;

  if ($debug > 0) {
    print "Test radius\n";
  }

  my @users_arr = ();
  if ( $argv->{get_db_users} ) {
    require "Users.pm";

    my $users = Users->new($db, undef, \%conf);

    my $list = $users->list({
      LOGIN     => '_SHOW',
      PASSWORD  => '_SHOW',
      DOMAIN_ID => 0,
      PAGE_ROWS => $count,
      COLS_NAME => 1
    });

    foreach my $line (@$list) {
      push @users_arr, {
        'User-Name'      => $line->{login},
        'Password'       => $line->{password},
        'NAS-IP-Address' => '127.0.0.1'
      };
    }
  }
  elsif($argv->{rad_file}) {
    %RAD_REQUEST = %{ load_rad_pairs($argv->{rad_file}) };
  }
  else {
    %RAD_REQUEST = (
      'User-Name'      => 'test',
      'Password'       => '123456',
      'NAS-IP-Address' => '127.0.0.1'
    );
  }

  if($argv->{NAS_IP}) {
    $RAD_REQUEST{'NAS-IP-Address'}=$argv->{NAS_IP};
  }

  $Bin = $Bin .'/../libexec/';
  require "rlm_perl.pl";

  #my $thread_mode = 1;

  if ($attr->{acct}) {
    print " acct \n";
    timethis($count, sub{ acct => accounting(); });
  }
  elsif($argv->{thread_mode}) {
    print "Thread mode  \n";
    my $thread_count = $argv->{thread_mode} || 5;

    timethis($count, sub{
      my @threads = ();
      for my $i (1..$thread_count) {
        push @threads, threads->create(
          sub{
            %RAD_REQUEST = %{ $users_arr[ rand($#users_arr + 1) ] };
            authenticate();
          },
          $i);
      }

      foreach my $thread (@threads) {
        $thread->join();
      }

                        });
  }
  elsif($attr->{dhcp_test}) {
    print "Mac_auth test\n";
    if($#ARGV < 1) {
      print "use Aaa.t dhcp_test Mac_auth.rad $#ARGV\n";
      exit;
    }
    #post_auth();
    mac_auth();
  }
  elsif($argv->{benchmark}) {
    print " benchmark auth count: $count\n";

    my %RAD = %RAD_REQUEST;

    timethis($count, sub{
      if(%RAD) {
          %RAD_REQUEST = %RAD;
      }
      elsif($#users_arr > -1){
        %RAD_REQUEST = %{ $users_arr[ rand( $#users_arr + 1 ) ] };
      }

      authenticate();
    });
  }
  else {
    if($debug) {
      print "Basic\n";
    }

    my $ret = authenticate();
    print "  authenticate: $ret\n";
    ok($ret);
    if(! $ret) {
      show_reply(\%RAD_REPLY);
    }

    $ret = authorize();
    print "  authorize: $ret\n";
    ok($ret);

    $RAD_REQUEST{'Acct-Status-Type'}='Start';
    $RAD_REQUEST{'Acct-Session-Id'}='testsesion_1';
    $ret = accounting();
    print "  accounting 'Start': $ret\n";
    ok($ret);

    $RAD_REQUEST{'Acct-Status-Type'}='Interim-Update';
    $ret = accounting();
    print "  accounting 'Interim-Update': $ret\n";
    ok($ret);

    $RAD_REQUEST{'Acct-Status-Type'}='Stop';
    $ret = accounting();
    print "  accounting 'Stop': $ret\n";
    ok($ret);
  }

  if ($argv->{show_result}) {
    show_reply(\%RAD_REPLY);
  }

  return 1;
}

#**********************************************************
=head2 load_rad_pairs($filename); - Load file from file

=cut
#**********************************************************
sub load_rad_pairs {
  my ($filename) = @_;

  if (! $filename || ! -f $filename) {
    print "File not found '$filename'.\n User rad_file=\n";
    exit;
  }

  print "Load rad file: $filename\n" if ($debug > 0);

  my $content   = '';
  my %rad_pairs = ();

  open(my $fh, '<', $filename) or die "Can;t load '$filename' $!";
    while(<$fh>) {
      $content .= $_;
    }
  close($fh);

  my @rows = split(/[\r\n]+/, $content);

  foreach my $line (@rows) {
    my ($key, $val) = split(/\s+\+?=\s+/, $line, 2);
    if (! $key) {
      next;
    }
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    $val =~ s/^\s+//;
    $val =~ s/\s+$//;
    $val =~ s/\"$//;
    $val =~ s/^\"//;
    $rad_pairs{$key}=$val;
  }

  if ($debug > 2) {
    foreach my $key (sort keys %rad_pairs) {
      print "  $key -> $rad_pairs{$key}\n";
    }
  }

  return \%rad_pairs;
}


#**********************************************************
=head2 get_nas_info() - test nas

=cut
#**********************************************************
sub get_nas_info {
  require Nas;
  Nas->import();

  my $Nas = Nas->new($db, \%conf);
  my %NAS_PARAMS = ( IP => '127.0.0.1' );

  cmpthese( $count, {
    #nas_new    => sub{ $Nas = $Nas->info2({ %NAS_PARAMS, SHORT => 1 }) },
    nas_short  => sub{ $Nas = $Nas->info({ %NAS_PARAMS, SHORT => 1 });  },
    nas        => sub{ $Nas = $Nas->info({ %NAS_PARAMS  });   }
  });

  return 1;
}


#**********************************************************
#
#**********************************************************
sub help  {

print << "[END]";

nas      - Nas get
get_ip   - Get IP
rad_auth - RAD Auth
  benchmark - Make banchmark
  get_db_users - Use db users for auth
  NAS_IP  - Nas IP radius param NAS-IP-Address
rad_acct - RAD Acct
rad_file - RAD File
show_result - Show RAD result
unifi    - unifi test

dhcp_test   - test dhcp (Mac_auth.pm)
thread_mode - Thread mode

debug=   - Debug mode
count=   - Test Count
help     - help

[END]

}

1