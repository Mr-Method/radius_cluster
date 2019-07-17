=head1 NAME

  User IP managment

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(ip2int int2ip);

our(
  $admin,
  $db,
  $html,
  %conf,
  %lang
);

#**********************************************************
=head2 internet_get_static_ip($pool_id) - Get static ip from pool

  Arguments:
    $pool_id   - IP pool ID
    $attr
      SILENT
      IPV6

  Returns:
    IP address

=cut
#**********************************************************
sub get_static_ip {
  my ($pool_id, $attr) = @_;
  my $ip = '0.0.0.0';

  my $Internet = Internet->new($db, $admin, \%conf);
  my $Nas      = Nas->new($db, \%conf, $admin);

  my $Ip_pool  = $Nas->ip_pools_info($pool_id);

  if($attr->{IPV6}) {
    return $Ip_pool->{IPV6_PREFIX}, $Ip_pool->{IPV6_MASK}, $Ip_pool->{IPV6_TEMPLATE},
      $Ip_pool->{IPV6_PD}, $Ip_pool->{IPV6_PD_MASK}, $Ip_pool->{IPV6_PD_TEMPLATE};
  }

#  if($Nas->{TOTAL} < 1) {
#    return -1;
#  }
#  els
  if(_error_show($Ip_pool, { ID => 117, MESSAGE => 'IP POOL:'. $pool_id })) {
    return '0.0.0.0';
  }

  my $start_ip = ip2int($Ip_pool->{IP});
  my $end_ip   = $start_ip + $Ip_pool->{COUNTS};

  my %users_ips = ();

  my $list = $Internet->list({
    PAGE_ROWS => 1000000,
    IP        => ">=$Ip_pool->{IP}",
    SKIP_GID  => 1,
    GROUP_BY  => 'internet.id',
    COLS_NAME => 1
  });

  foreach my $line (@$list) {
    $users_ips{ $line->{ip_num} } = 1;
  }

  for (my $ip_cur = $start_ip ; $ip_cur <= $end_ip ; $ip_cur++) {
    if (! $users_ips{ $ip_cur }) {
      return int2ip($ip_cur);
    }
  }
  
  if ($Ip_pool->{NEXT_POOL_ID}){
    return get_static_ip($Ip_pool->{NEXT_POOL_ID});
  }

  $html->message('err', $lang{ERROR}, $lang{ERR_NO_FREE_IP_IN_POOL});

  return $ip;
}


1;