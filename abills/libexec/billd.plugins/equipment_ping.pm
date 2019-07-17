=head1 NAME

   equipment ping

   Arguments:

     TIMEOUT

=cut

use Equipment;
use Net::Ping;
our (
  $Admin,
  $db,
  %conf,
  $argv
);

my $Equipment = Equipment->new( $db, $Admin, \%conf );

equipment_ping();

#**********************************************************
=head2 equipment_ping($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub equipment_ping {
  my ($attr) = @_;

  my $timeout = $attr->{TIMEOUT} || '4';

  my $p = Net::Ping->new( 'syn' ) or die "Can't create new ping object: $!\n";

  my $equipment = $Equipment->_list( {
      COLS_NAME => 1,
      PAGE_ROWS => 100000,
      NAS_IP    => '_SHOW',
      STATUS    => '0;1',
      NAS_NAME  => '_SHOW'
    } );

  my %ips;
  foreach my $host (@$equipment) {
    $ips{$host->{nas_ip}} = { NAS_ID => $host->{nas_id}, STATUS => $host->{status} };
  }

  my %syn;
  foreach my $key (keys %ips) {
    my ($ret, undef, $ip) = $p->ping( $key, $timeout );
    if ($ret) {
      $syn{$key} = $ip;
    }
    else {
      print "$key address not found\n";
    }
  }
  while (my ($host, undef, undef) = $p->ack) {
    if ($ips{$host}{STATUS} != 0) {
      $Equipment->_change( { NAS_ID => $ips{$host}{NAS_ID}, STATUS => 0 } );
    }
    print " $host is reachable\n" if ( $debug > 1);
    delete $syn{$host};
  }

  foreach my $host (keys %syn) {
    if ($ips{$host}{STATUS} == 0) {
      $Equipment->_change( { NAS_ID => $ips{$host}{NAS_ID}, STATUS => 1 } );
    }
    print " $host is unreachable\n" if ( $debug > 1);
  }

  $p->close;

  return 1;
}