=head1 NAME

   equipment ping

   Arguments:

     TIMEOUT
     NAS_IP

=cut


use warnings;
use strict;
use Equipment;
use Net::Ping;
use Events::API;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $base_dir,
  $debug,
);

my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $Events = Events::API->new( $db, $Admin, \%conf );

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

  if($argv->{NAS_IP}) {
    $LIST_PARAMS{NAS_IP}=$argv->{NAS_IP};
  }

  my $ping = Net::Ping->new( 'syn' ) or die "Can't create new ping object: $!\n";

  if($debug > 6) {
    $Equipment->{debug}=1;
  }

  my $equipment = $Equipment->_list( {
    NAS_IP    => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME => 1,
    PAGE_ROWS => 100000,
    STATUS    => '0;3',
    NAS_NAME  => '_SHOW',
  } );

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $datetime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

  my %ips = ();
  foreach my $host (@$equipment) {
    if(! $host->{nas_ip}) {
      next;
    }

    $ips{$host->{nas_ip}} = {
      NAS_ID   => $host->{nas_id},
      STATUS   => $host->{status},
      NAS_NAME => $host->{nas_name} || q{}
    };
  }

  my %syn;
  my %ret_time;
  foreach my $host_ip (keys %ips) {
    if($debug > 5) {
      print "Try to ping: $host_ip\n";
    }

    my ($ret, $duration, $ip) = $ping->ping( $host_ip, $timeout );
    if ($ret) {
      $syn{$host_ip} = $ip;
      $ret_time{$host_ip} = $duration;
    }
    else {
      print "$host_ip address not found\n";
    }
  }

  my $message = '';
  while (my ($host, undef, undef) = $ping->ack) {
    if ($ips{$host}{STATUS} == 1) {
      $message .= "$ips{$host}{NAS_NAME}($host) _{AVAILABLE}_\n";
    }
    $Equipment->_change({
      NAS_ID        => $ips{$host}{NAS_ID},
      STATUS        => 0,
      LAST_ACTIVITY => $datetime
    });

    $Equipment->ping_log_add({
      DATE     => $datetime,
      NAS_ID   => $ips{$host}{NAS_ID},
      STATUS   => 1,
      DURATION => $ret_time{$host},
    });

    print " $host is reachable\n" if ( $debug > 1);
    delete $syn{$host};
  }

  my $fping_installed = qx/which fping/;
  my $host_fping = '';
  if ( $fping_installed ne "" ) {
    foreach $host_fping (keys %syn) {
      print "$host_fping status 0. start fping if exist\n" if ( $debug > 1 );
      my $fping = system "fping -C 2 -q $host_fping";
      print "FPING return status = $fping for HOST $host_fping\n" if ( $debug > 1 );
      if ( $fping != 0 ) {
        print "$host_fping do not response\n" if ( $debug > 1 );
        $Equipment->_change( { NAS_ID => $ips{$host_fping}{NAS_ID}, STATUS => 3 } );
        $message .= "$ips{$host_fping}{NAS_NAME}($host_fping) _{UNAVAILABLE}_\n";
        $Equipment->ping_log_add({
          DATE     => $datetime,
          NAS_ID   => $ips{$host_fping}{NAS_ID},
          STATUS   => 0,
          DURATION => $timeout,
        });
      }
      else {
        print "Updating host $host_fping STATUS to AVAILABLE\n" if ( $debug > 1 );
        $Equipment->_change( { NAS_ID => $ips{$host_fping}{NAS_ID}, STATUS => 0 } );
        $message .= "$ips{$host_fping}{NAS_NAME}($host_fping) _{AVAILABLE}_\n";
        $Equipment->ping_log_add({
          DATE     => $datetime,
          NAS_ID   => $ips{$host_fping}{NAS_ID},
          STATUS   => 1,
          DURATION => $timeout,
        });
      }
     }
    }
  else {
   foreach my $host (keys %syn) {
      if ($ips{$host}{STATUS} == 0) {
      my $ping_icmp = Net::Ping->new("icmp");
      next if $ping_icmp->ping($host, 2);
      sleep(1);
      $ping_icmp->close();
	    print "$host do not response\n";

      $Equipment->_change( { NAS_ID => $ips{$host}{NAS_ID}, STATUS => 3 } );
      $message .= "$ips{$host}{NAS_NAME}($host) _{UNAVAILABLE}_\n";
    }

    $Equipment->ping_log_add({
      DATE     => $datetime,
      NAS_ID   => $ips{$host}{NAS_ID},
      STATUS   => 0,
      DURATION => $timeout,
    });
    print " $host is unreachable\n" if ( $debug > 1);
    $ping->close;
  }
}

  if ($message) {
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $datestr = sprintf("%02d:%02d:%02d %02d.%02d.%04d", $hour, $min, $sec, $mday, $mon + 1, $year + 1900);
    $message = $datestr . "\n$message";
    generate_new_event( "$message" );
  }

  return 1;
}

#**********************************************************
=head2 generate_new_event($comments)

  Arguments:
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($comments) = @_;

  #  print "EVENT: $name, $comments \n";
  print $comments . "\n" if ($argv->{DEBUG});

  $Events->add_event({
    MODULE      => "Equipment",
    PRIORITY_ID => 5,
    STATE_ID    => 1,
    TITLE       => '_{WARNING}_',
    COMMENTS    => $comments,
  });
  
  return 1;
}

1
