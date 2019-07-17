=head1 NAME

 create ISC DHCP conf file

=head1 ARGUMENTS

  CONFIG=/etc/dhcp.conf
  DEBUG=1..5
  STATIC_ONLY=1

=cut

use strict;
use warnings FATAL => 'all';

use Socket;
use Abills::Base qw(int2ip);
use Abills::HTML;
require Abills::Misc;

our (
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  %FORM,
  $argv
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Nas = Nas->new($db, \%conf, $admin);

isc_dhcp_config();

#**********************************************************
=head2 isc_dhcp_config() - make_config

=cut
#**********************************************************
sub isc_dhcp_config {

  our $html = Abills::HTML->new(
    {
      CONF => \%conf,
    }
  );

  my $static_networks;

  if ($argv->{STATIC_ONLY}) {
    $static_networks = 1;
  }

  $html->{language} = '';
  require Abills::Templates;

  my $debug = 0;
  my $filename = $conf{INTERNET_ISC_DHCP_CONFIG};

  if ($argv->{DEBUG}) {
    $debug = $argv->{DEBUG};
    if ($debug > 6) {
      $Nas->{debug} = 1;
    }
  }

  if ($argv->{CONFIG}) {
    $filename = $argv->{CONFIG};
  }

  if (!$filename) {
    print 'ERROR: $conf{INTERNET_ISC_DHCP_CONFIG} is empty';
    exit;
  }

  my $networks = $Nas->nas_ip_pools_list({
    COLS_NAME  => 1,
    COLS_UPPER => 1,
    IP         => '_SHOW',
    STATIC     => $static_networks,
    NETMASK    => '_SHOW',
    GATEWAY    => '_SHOW',
    NAME       => '_SHOW',
    FIRST_IP   => '_SHOW',
    LAST_IP    => '_SHOW',
    PAGE_ROWS  => 60000,
  });

  _error_show($Nas);

  my $subnet_tpls //= '';

  foreach my $subnet (@{$networks}) {
    $subnet->{RANGE} = 'range ' . $subnet->{FIRST_IP} . ' ' . $subnet->{LAST_IP} . ';';

    my $address_int = 0 + $subnet->{IP} & 0 + $subnet->{NETMASK};
    $subnet->{SUBNET} = int2ip($address_int);
    $subnet->{NETMASK} = int2ip($subnet->{NETMASK});
    $subnet->{GATEWAY} = int2ip($subnet->{GATEWAY}) if ($subnet->{GATEWAY});
    $subnet_tpls .= $html->tpl_show(_include('internet_isc_dhcp_conf_subnet', 'Internet'), { %$subnet }, { OUTPUT2RETURN => 1 }) . "\n";
  }

  my $hosts = $Internet->list({
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
    INTERNET_LOGIN => '_SHOW',
    CID            => '*',
    IP_NUM         => '>0',
    GROUP_BY       => 'internet.id',
    PAGE_ROWS      => 100000,
  });
  _error_show($Internet);

  my $hosts_tpls //= '';

  foreach my $host (@{$hosts}) {
    $host->{IP} = int2ip($host->{IP_NUM});
    $hosts_tpls .= $html->tpl_show(_include('internet_isc_dhcp_conf_host', 'Internet'), { %$host }, { OUTPUT2RETURN => 1 });
  }

  my $conf_main = $html->tpl_show(_include('internet_isc_dhcp_conf_main', 'Internet'),
    {
      SUBNETS => $subnet_tpls,
      HOSTS   => $hosts_tpls,
      DATE    => $DATE
    },
    { OUTPUT2RETURN => 1 }
  ) . "\n";

  if ($debug > 7) {
    print $conf_main;
  }
  else {
    open(my $fh, '>', $filename) or die "ERROR: Can`t open filename. Edit " . '$conf{INTERNET_ISC_DHCP_CONFIG}.' . " $!\n";
    print $fh $conf_main;
    close $fh;
  }

  if ($debug > 1) {
    print 'The configuration file was successfully created' . "\n";
  }

  return 1;
}

1;