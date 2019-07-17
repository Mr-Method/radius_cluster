=head1 NAME

  SNMP cmd

=cut

use strict;
use warnings FATAL => 'all';
use SNMP_Session;
use SNMP_util;
use BER;
use Abills::Base qw(in_array);

our(
  $html,
  %lang
);


#**********************************************************
=head2 snmp_get($attr); - Set SNMP value

  Arguments:
    $attr
      SNMP_COMMUNITY
      OID             - oid
      WALK            - walk mode
      SILENT          - DOn't generate exception
      TIMEOUT         - Request timeout (Default: 2)
      SKIP_TIMEOUT    -
      VERSION         - SNMP version (1 default or v2c)
      DEBUG

  Returns:
      result string
      ot result array for WALK mode

=cut
#**********************************************************
sub snmp_get {
  my ($attr) = @_;
  my $value;

  #$SNMP_util::Max_log_level      = 'none';
  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg           = undef;

  my $debug = 0;
  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my $timeout = $attr->{TIMEOUT} || 2;
  my $retries = $attr->{RETRIES} || 2;
  my $version = $attr->{VERSION} || 1;

  my ($snmp_community, $port, undef, $port3)=split(/:/, $attr->{SNMP_COMMUNITY} || q{});
  if($port3) {
    $port = $port3;
  }
  elsif (! $port || in_array($port, [ 21, 22, 23, 1700, 3977 ])) {
    $port = 161;
  }

  $snmp_community.=':'.$port.":$timeout:$retries:1:$version";

  if ($debug > 2) {
    print "$attr->{SNMP_COMMUNITY} -> $attr->{OID} <br>";
  }

  if ($debug > 5) {
    return [];
  }

  if ($attr->{WALK}) {
    if(! $attr->{OID}) {
      print "Unknown oid\n";
      return [];
    }

    my @value_arr = ();

    eval {
      local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required
      if (! $attr->{SKIP_TIMEOUT} && $timeout) {
        alarm $timeout * $retries;
      }

      @value_arr = SNMP_util::snmpwalk($snmp_community, $attr->{OID});
      alarm 0;
    };

    if ($@) {
      print "timed out ($timeout): $attr->{OID}\n" if(! $attr->{SILENT});
      return [] unless $@ eq "alarm\n";                  # propagate unexpected errors
    }
    else {
      print "NO errors\n" if ($debug>2);
    }

    $value = \@value_arr;
  }
  else {
    $value = SNMP_util::snmpget($snmp_community, $attr->{OID});
  }

  if ($SNMP_Session::errmsg && ! $attr->{SILENT}) {
    my $message = "OID: $attr->{OID}\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n";
    if ($html) {
      $html->message('err', $lang{ERROR}, $message);
    }
    else {
      print $message;
    }
  }

  return $value;
}


#**********************************************************
=head2 snmp_set($attr); - Set SNMP value

  Arguments:
    $attr
      SNMP_COMMUNITY  - {community_name}@{ip_address}[:port]
      TIMEOUT         - Timeout
      OID             - array ( OID, type, value, OID, type, value, ...)
      SILENT
      VERSION
      DEBUG

    Returns:
      TRUE or FALSE

    Example:
      snmp_set({
         SNMP_COMMUNITY => 'private@10.10.10.11',
         OID            => [
          .1.3.6.1.4.1.35265.1.22.3.4.1.20.1.8.69.76.84.88.98.2.72.24, 'i', 4,
          .1.3.6.1.4.1.35265.1.22.3.4.1.3.1.8.69.76.84.88.98.2.72.24, 'i', 0,
          .1.3.6.1.4.1.35265.1.22.3.4.1.4.1.8.69.76.84.88.98.2.72.24, 'u', 1
         ],
         VERSION        => 'v2c',
         DEBUG          => 1
      });

=cut
#**********************************************************
sub snmp_set {
  my ($attr) = @_;
  #my $value;
  my $result = 1;

  #$SNMP::Util::Max_log_level      = 'none';
  my $timeout = $attr->{TIMEOUT} || 2;
  my $retries = $attr->{RETRIES} || 2;
  my $version = $attr->{VERSION} || 1;

  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg = undef;
  my $debug = 0;
  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my ($snmp_community, $port, undef, $port3)=split(/:/, $attr->{SNMP_COMMUNITY} || q{});
  if($port3) {
    $port = $port3;
  }
  elsif (! $port || in_array($port, [ 21, 22, 23, 1700, 3977 ])) {
    $port = 161;
  }
  $snmp_community.=':'.$port.":$timeout:$retries:1:$version";

  my $info = '';
  for(my $i=0; $i<= $#{ $attr->{OID} }; $i+=3) {
    $info .= ' '. $attr->{OID}->[$i] .' '.$attr->{OID}->[$i+1] .' -> '.  $attr->{OID}->[$i+2]. "\n";
  }

  if ($debug > 2) {
    print "$attr->{SNMP_COMMUNITY} ($snmp_community) ->\n$info <br>";
  }

  if ($debug > 5) {
    return '';
  }

  if (! SNMP_util::snmpset($snmp_community, @{ $attr->{OID} })) {
    #print "Set Error: \n$info\n";
    $result = 1;
  }

  if ($SNMP_Session::errmsg && ! $attr->{SILENT}) {
    my $message = "OID: $info\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n";
    if ($html) {
      $html->message('err', $lang{ERROR}, $message);
    }
    else {
      print $message;
    }

    $result = 0;
  }

  return $result;
}


1;
