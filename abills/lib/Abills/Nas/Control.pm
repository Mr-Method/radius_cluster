package Abills::Nas::Control;

#***********************************************************
=head1 NAME

  NAS controlling functions
    get_acct_info
    hangup
    check_activity

=cut
#***********************************************************

use strict;
use warnings;
use BER;
use SNMP_Session;
use SNMP_util;
use Socket;
use Radius;
use Abills::Defs;
use Abills::Base qw(ip2int cmd);
use parent 'Exporter';
use FindBin '$Bin';
use Log;

our @EXPORT = qw(
  hangup
  telnet_cmd
  telnet_cmd2
  telnet_cmd3
  hangup_snmp
  rsh_cmd
  hascoa
  setspeed
  );

our @EXPORT_OK = qw(
  hangup
  telnet_cmd
  telnet_cmd2
  telnet_cmd3
  hangup_snmp
  rsh_cmd
  hascoa
  setspeed
  );

my $USER_NAME = '';
my $debug = 0;
our $base_dir;
my $Log;
my $CONF;
my $db;

sub new{
  my $class = shift;
  $db = shift;
  ($CONF) = @_;

  my $self = { };

  bless( $self, $class );

  if ( $db ){
    $Log = Log->new( $db, $CONF );
  }

  if(! $base_dir) {
    $base_dir = '/usr/abills/';
  }

  return $self;
}

#***********************************************************
=head1 hangup($Nas, $attr);

  Hangup active port (user,cids)

  Arguments:
    $NAS_HASH_REF - NAS information
    $PORT         - NAS port
    $USER         - User LOGIN
    $attr         - Extra atttributes
      SESSION_ID
      ACCT_SESSION_ID
      CALLING_STATION_ID
      FRAMED_IP_ADDRESS
      UID
      NETMASK
      FILTER_ID
      CID
      LOG         - Log object

  Returns:

=cut
#***********************************************************
sub hangup{
  my $self = shift;
  my ($Nas, $PORT, $USER, $attr) = @_;

  my $nas_type = $Nas->{NAS_TYPE} || '';
  my %params   = ();
  if ( ref $attr eq 'HASH' ){
    %params = %$attr;
    $params{SESSION_ID} = $attr->{ACCT_SESSION_ID};
  }

  $params{PORT}       = $PORT;
  $params{USER}       = $USER;
  $USER_NAME          = $USER;
  if ( $nas_type eq 'exppp' ){
    hangup_exppp( $Nas, $attr );
  }
  elsif ( -f "Nas/$nas_type" . '.pm' ){
    do "Nas/$nas_type" . '.pm';
    my $fn = 'hangup_' . $nas_type;
    if ( defined( $fn ) ){
      $fn->( $Nas, \%params );
    }
  }
  elsif ( $nas_type eq 'pm25' ){
    hangup_pm25( $Nas, \%params );
  }
  elsif ( $nas_type eq 'radpppd' ){
    hangup_radpppd( $Nas, \%params );
  }
  elsif ( $nas_type eq 'mikrotik' ){
    my ($ip, $mng_port, $second_port) = split( /:/, $Nas->{NAS_MNG_IP_PORT}, 3 );
    #IPN Hangup if COA port 0
    if ( ! $mng_port && $second_port && $second_port > 0 ){
      $Nas->{NAS_MNG_IP_PORT} = "$ip:$second_port";
      hangup_ipcad( $Nas, \%params );
    }
    else{
      hangup_radius( $Nas, \%params );
    }
  }
  elsif ( $nas_type eq 'chillispot' ){
    $Nas->{NAS_MNG_IP_PORT} = "$Nas->{NAS_IP}:3799" if (!$Nas->{NAS_MNG_IP_PORT});
    hangup_radius( $Nas, \%params );
  }
  elsif ( $nas_type eq 'usr' ){
    hangup_snmp(
      $Nas, $PORT,
      {
        OID   => '.1.3.6.1.4.1.429.4.10.13.' . $PORT,
        TYPE  => 'integer',
        VALUE => 9
      }
    );
  }
  elsif ( $nas_type eq 'cisco' ){
    hangup_cisco( $Nas, \%params );
  }
  elsif ( $nas_type eq 'unifi' ){
    hangup_unifi( $Nas, \%params )
  }
  elsif ( $nas_type eq 'cisco_isg' ){
    hangup_cisco_isg( $Nas, \%params );
  }
  elsif ( $nas_type eq 'mpd' ){
    hangup_mpd( $Nas, \%params );
  }
  elsif ( $nas_type eq 'mpd4' ){
    hangup_mpd4( $Nas, \%params );
  }
  elsif ( $nas_type eq 'mpd5' ){
    hangup_mpd5( $Nas, \%params );
  }
  elsif ( $nas_type eq 'openvpn' ){
    hangup_openvpn( $Nas, \%params );
  }
  elsif ( $nas_type eq 'ipcad'
    || $nas_type eq 'mikrotik_dhcp'
    || $nas_type eq 'dhcp'
    || $nas_type eq 'dlink_pb'
    || $nas_type eq 'dlink'
    || $nas_type eq 'edge_core'
    || $nas_type eq 'gpon'
    || $nas_type eq 'epon'
  ){
    hangup_ipcad( $Nas, \%params );
  }
  elsif ( $nas_type eq 'patton' ){
    hangup_patton29xx( $Nas, \%params );
  }
  elsif ( $nas_type eq 'pppd' || $nas_type eq 'lepppd' ){
    hangup_pppd( $Nas, \%params );
  }
  # http://sourceforge.net/projects/radcoad/
  elsif ( $nas_type eq 'pppd_coa' ){
    hangup_pppd_coa( $Nas, \%params );
  }
  elsif ( $nas_type eq 'accel_ppp' || $nas_type eq 'accel_ipoe' ){
    hangup_radius( $Nas, \%params );
  }
  elsif ( $nas_type eq 'redback' ){
    hangup_radius( $Nas, \%params );
  }
  elsif ( $nas_type eq 'mx80' ){
    $params{RAD_PAIRS}->{'Acct-Session-Id'}=$params{SESSION_ID};
    hangup_radius( $Nas, \%params );
  }
  elsif ( $nas_type eq 'lisg_cst' ){
    hangup_radius( $Nas, \%params );
  }
  else{
    return 1;
  }

  return 0;
}

#***********************************************************
=head2 get_stats($nas, $PORT, $attr) - Get stats

=cut
#***********************************************************
sub get_stats{
  my (undef, $Nas, $PORT) = @_;

  my $nas_type = $Nas->{NAS_TYPE};
  my %stats;
  if ( $nas_type eq 'usr' ){
    %stats = stats_usrns( $Nas, $PORT );
  }
  elsif ( $nas_type eq 'patton' ){
    %stats = stats_patton29xx( $Nas, $PORT );
  }
  elsif ( $nas_type eq 'pm25' ){
    %stats = stats_pm25( $Nas, $PORT );
  }
  else{
    return 0;
  }

  return \%stats;
}

#***********************************************************
=head2 telnet_cmd($hostname, $commands, $attr)

=cut
#***********************************************************
sub telnet_cmd{
  my ($hostname, $commands) = @_;
  my $port = 23;

  if ( $hostname =~ /:/ ){
    ($hostname, $port) = split( /:/, $hostname, 2 );
  }

  #my $debug = ($attr->{DEBUG}) ? 1 : 0;
  #my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;

  my $dest = sockaddr_in( $port, Socket::inet_aton( "$hostname" ) );
  my $SH;

  if ( !socket( $SH, PF_INET, SOCK_STREAM, getprotobyname( 'tcp' ) ) ){
    print "ERR: Can't init '$hostname:$port' $!";
    return 0;
  }

  if ( !CORE::connect( $SH, $dest ) ){
    print "ERR: Can't connect to '$hostname:$port' $!";
    return 0;
  }

  $Log->log_print( 'LOG_DEBUG', "$USER_NAME", "Connected to $hostname:$port", { ACTION => 'CMD' } );

  #my $sock   = $SH;
  my $MAXBUF = 512;
  my $input = '';
  my $len = 0;
  my $text = '';
  my $inbuf = '';
  my $res = '';

  my $old_fh = select( $SH );
  $| = 1;
  select( $old_fh );

  $SH->autoflush( 1 );

  foreach my $line ( @{$commands} ){
    my ($waitfor, $sendtext) = split( /\t/, $line, 2 );
    my $wait_len = length( $waitfor );
    $input = '';

    if ( $waitfor eq '-' ){
      send( $SH, "$sendtext\n", 0, $dest ) or die $Log->log_print( 'LOG_INFO', "$USER_NAME", "Can't send: '$text' $!",
          { ACTION => 'CMD' } );
    }

    do {
      eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n ����������
        alarm 5;
        recv( $SH, $inbuf, $MAXBUF, 0 );
        alarm 0;
      };

      # ���� ����� �� ����-���� $timeout
      if ( $@ ){
        last;
      }

      $input .= $inbuf;
      $len = length( $inbuf );
    } while ($len >= $MAXBUF || $len < $wait_len);

    $Log->log_print( 'LOG_DEBUG', "$USER_NAME", "Get: \"$input\"\nLength: $len", { ACTION => 'CMD' } );
    $Log->log_print( 'LOG_DEBUG', "$USER_NAME", " Wait for: '$waitfor'", { ACTION => 'CMD' } );

    if ( $input =~ /$waitfor/ig ){
      # || $waitfor eq '') {
      $text = $sendtext;
      $Log->log_print( 'LOG_DEBUG', "$USER_NAME", "Send: $text", { ACTION => 'CMD' } );
      send( $SH, "$text\n", 0, $dest ) or die $Log->log_print( 'LOG_INFO', "$USER_NAME", "Can't send: '$text' $!",
          { ACTION => 'CMD' } );
    }

    $res .= "$input\n";
  }

  close( $SH );
  return $res;
}

#**********************************************************
=head2 telnet_cmd2($host, $commands, $attr)

=cut
#**********************************************************
sub telnet_cmd2{
  my ($host, $commands, $attr) = @_;
  my $port = 23;

  if ( $host =~ /:/ ){
    ($host, $port) = split( /:/, $host, 2 );
  }

  use IO::Socket;
  use IO::Select;
  my $res;

  my $timeout = defined( $attr->{'TimeOut'} ) ? $attr->{'TimeOut'} : 5;
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    TimeOut  => $timeout
  ) or $Log->log_print( 'LOG_DEBUG', "$USER_NAME", "ERR: Can't connect to '$host:$port' $!", { ACTION => 'CMD' } );

  $Log->log_print( 'LOG_DEBUG', '', "Connected to $host:$port" );

  foreach my $line ( @{$commands} ){
    my ($waitfor, $sendtext) = split( /\t/, $line, 2 );

    $Log->log_print( 'LOG_DEBUG', "$USER_NAME", " Wait for: '$waitfor' Send: '$sendtext'", { ACTION => 'CMD' } );

    $socket->send( "$sendtext" );
    while (<$socket>) {
      $res .= $_;
    }
  }

  close( $socket );

  return $res;
}

#***********************************************************
=head2 telnet_cmd($hostname, $commands, $attr)

=cut
#***********************************************************
sub telnet_cmd3{
  my ($hostname, $commands, $attr) = @_;
  my $port = 23;

  if ( $hostname =~ /:/ ){
    ($hostname, $port) = split( /:/, $hostname, 2 );
  }

  if ( $attr->{LOG} ){
    $Log = $attr->{LOG};
  }
  #  my $debug = ($attr->{DEBUG}) ? 1 : 0;
  #  my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;

  my $dest = sockaddr_in( $port, inet_aton( "$hostname" ) );
  my $SH;

  if ( !socket( $SH, PF_INET, SOCK_STREAM, getprotobyname( 'tcp' ) ) ){
    print "ERR: Can't init '$hostname:$port' $!";
    return 0;
  }

  if ( !CORE::connect( $SH, $dest ) ){
    print "ERR: Can't connect to '$hostname:$port' $!";
    return 0;
  }

  $Log->log_print( 'LOG_DEBUG', "$USER_NAME", "Connected to $hostname:$port", { ACTION => 'CMD' } );

  my $MAXBUF = 512;
  my $input = '';
  #my $len    = 0;
  #my $text   = '';
  my $inbuf = '';
  #my $res    = '';

  my $old_fh = select( $SH );
  $| = 1;
  select( $old_fh );

  $SH->autoflush( 1 );
  my $i = 0;
  foreach my $line ( @{$commands} ){
    my ($waitfor, $sendtext) = split( /\t/, $line, 2 );
    $input = '';
    $i++;

    while (1) {
      if ( $debug > 0 ){
        print $i . "\n";
      }

      eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n �????
        alarm 5;
        recv( $SH, $inbuf, $MAXBUF, 0 );
        $input .= $inbuf;
        alarm 0;
      };
      if ( $@ ){
        if ( $debug > 0 ){
          print "Error:";
          print $@;
          print "-----\n";
        }
        last;
      }

      if ( $input =~ /$waitfor/g ){
        last;
      }
      $i++
    };

    send( $SH, "$sendtext\n", 0, $dest ) or die "Can't send: '$sendtext' $!";

    if ( $debug > 0 ){
      print "Input: '$input'\n";
      print "Send: '$sendtext'\n";
    }
  }

  close( $SH );

  return $input;
}


#***********************************************************
=head2 stats_pm25($NAS, $PORT) - Get stats from Livingston Portmaster

=cut
#***********************************************************
sub stats_pm25{
  my ($NAS, $attr) = @_;

  my %stats = (
    in  => 0,
    out => 0
  );

  my $PORT = $attr->{PORT};
  my $PM25_PORT = $PORT + 2;
  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';

  my ($in) = snmpget( $SNMP_COM . '@' . $NAS->{NAS_IP}, ".1.3.6.1.2.1.2.2.1.10.$PM25_PORT" );
  my ($out) = snmpget( $SNMP_COM . '@' . $NAS->{NAS_IP}, ".1.3.6.1.2.1.2.2.1.16.$PM25_PORT" );

  if ( !defined( $in ) ){
    $stats{error} = 1;
  }
  elsif ( int( $in ) + int( $out ) > 0 ){
    $stats{in} = int( $in );
    $stats{out} = int( $out );
  }

  return %stats;
}

#***********************************************************
# HANGUP pm25
# hangup_pm25($SERVER, $PORT)
#***********************************************************
sub hangup_pm25{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  my @commands = ();
  push @commands, "login:\t$NAS->{NAS_MNG_USER}";
  push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
  push @commands, ">\treset S$PORT";
  push @commands, ">exit";

  my $result = telnet_cmd( "$NAS->{NAS_IP}", \@commands );
  print $result;

  return 0;
}

#***********************************************************
=head2 stats_usrns($NAS, $PORT) - Get stats from USR Netserver 8/16

=cut
#***********************************************************
sub stats_usrns{
  my ($NAS, $attr) = @_;

  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
  my $PORT = $attr->{PORT};
  my %stats = ();
  #USR trafic taker
  my $in = snmpget( "$SNMP_COM\@$NAS->{NAS_IP}", "interfaces.ifTable.ifEntry.ifInOctets.$PORT" );
  my $out = snmpget( "$SNMP_COM\@$NAS->{NAS_IP}", "interfaces.ifTable.ifEntry.ifOutOctets.$PORT" );

  $stats{in} = int( $in );
  $stats{out} = int( $out );

  return %stats;
}

####################################################################
# Standart FreeBSD ppp
#************************************************************
# get accounting information from FreeBSD ppp using remove accountin
# scrips
# stats_ppp($NAS)
#************************************************************
sub stats_ppp{
  my ($NAS) = @_;

  use IO::Socket;
  my $port = 30006;

  my %stats = ();
  my ($ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 2 );
  $port = $mng_port || 0;

  my $remote = IO::Socket::INET->new(
    Proto    => "tcp",
    PeerAddr => $ip,
    PeerPort => $port
  ) or print "cannot connect to pppcons port at $NAS->{NAS_IP}:$port $!\n";

  while (<$remote>) {
    my ($radport, $in, $out, $tun) = split( / +/, $_ );
    $stats{ $NAS->{NAS_IP} }{$radport}{in} = $in;
    $stats{ $NAS->{NAS_IP} }{$radport}{out} = $out;
    $stats{ $NAS->{NAS_IP} }{$radport}{tun} = $tun;
  }

  return %stats;
}


#**********************************************************
=head2 hangup_snmp($NAS, $attr) Base SNMP set hangup function

=cut
#**********************************************************
sub hangup_snmp{
  my ($NAS, $attr) = @_;

  my $oid   = $attr->{OID};
  my $type  = $attr->{TYPE} || 'integer';
  my $value = $attr->{VALUE};

  $Log->log_print( 'LOG_DEBUG', '', "SNMPSET: $NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP} $oid $type $value",
    { ACTION => 'CMD' } );
  my $result = snmpset( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", "$oid", "$type", $value );

  if ( $SNMP_Session::errmsg ){
    $Log->log_print( 'LOG_ERR', '', "$SNMP_Session::suppress_warnings / $SNMP_Session::errmsg", { ACTION => 'CMD' } );
  }

  return $result;
}

#***********************************************************
=head2 hangup_radius($NAS, $attr) - hangup_radius

  Arguments:
    $NAS   -
    $attr  -
      USER
      FRAMED_IP_ADDRESS
      SESSION_ID
      RAD_PAIRS          - Use custom radius pairs form disconnect
      COA                - Change request type to CoA
      DEBUG

  Radius-Disconnect messages
    rfc2882

=cut
#***********************************************************
sub hangup_radius {
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  if (!$NAS->{NAS_MNG_IP_PORT}) {
    print "Radius Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID} USER: $USER\n";
    return 'ERR:';
  }

  my ($ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 3 );
  $mng_port = 1700 if (!$mng_port);
  my $nas_password = $NAS->{NAS_MNG_PASSWORD} || q{};
  $Log->log_print( 'LOG_DEBUG', $USER,
    "HANGUP: User-Name=$USER Framed-IP-Address=".($attr->{FRAMED_IP_ADDRESS} || q{})
      ." NAS_MNG: $ip:$mng_port '$nas_password'"
    , { ACTION => 'CMD', NAS => $NAS } );

  my $type;
  my $r = Radius->new(
    Host   => $ip.':'.$mng_port,
    Secret => $nas_password,
    Debug  => $attr->{DEBUG} || 0
  ) or return "Can't connect '".$ip.':'.$mng_port."' $!";

  $CONF->{'dictionary'} = $base_dir.'/lib/dictionary' if (!$CONF->{'dictionary'});

  if (!-f $CONF->{'dictionary'}) {
    print "Can't find radius dictionary: $CONF->{'dictionary'}";
    return 0;
  }

  $r->load_dictionary( $CONF->{'dictionary'} );

  my %rad_pairs = ();

  if ($attr->{RAD_PAIRS}) {
    %rad_pairs = %{ $attr->{RAD_PAIRS} };
  }
  else {
    if ($attr->{SESSION_ID}) {
      $rad_pairs{'Acct-Session-Id'} = $attr->{SESSION_ID} if ($USER);
      $rad_pairs{'User-Name'} = $USER if ($USER);
    }
    else {
      $rad_pairs{'Framed-IP-Address'} = $attr->{FRAMED_IP_ADDRESS} if ($attr->{FRAMED_IP_ADDRESS});
    }
  }

  while(my ($k, $v) = each %rad_pairs) {
    print " $k Value => $v \n" if ($attr->{DEBUG});
    $r->add_attributes( { Name => $k, Value => $v } );
  }

  my $request_type = ($attr->{COA}) ? 'COA' : 'POD';

  if ( $attr->{COA} ){
    $r->send_packet( COA_REQUEST ) and $type = $r->recv_packet;
  }
  else{
    $r->send_packet( POD_REQUEST ) and $type = $r->recv_packet;
  }

  my $result;
  if ( !defined $type ){
    # No responce from COA/POD server
    my $message = "No responce from $request_type server '$NAS->{NAS_MNG_IP_PORT}'";
    $result .= $message;
    $Log->log_print( 'LOG_DEBUG', "$USER", $message, { ACTION => 'CMD' } );
  }

  for my $rad ( $r->get_attributes ){
    $result .= "  $rad->{'Name'} -> $rad->{'Value'}\n";
  }

  if ( $attr->{DEBUG} ){
    print "Radius Return: $type\n Result: ". ($result || 'Empty');
  }

  $r = undef;

  return $result;
}

#***********************************************************
=head2 hangup_mikrotik_telnet($NAS, $attr)

=cut
#***********************************************************
sub hangup_mikrotik_telnet{
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  my @commands = ();

  push @commands, "Login:\t$NAS->{NAS_MNG_USER}";
  push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
  push @commands, ">/interface pptp-server remove [find user=$USER]";
  push @commands, ">quit";

  my $result = telnet_cmd2( "$NAS->{NAS_IP}", \@commands );

  print $result;
}

#***********************************************************
=head2 hangup_ipcad($NAS_IP, $PORT, $USER_NAME, $attr)

=cut
#***********************************************************
sub hangup_ipcad{
  my ($NAS, $attr) = @_;

  my $result    = '';
  my $ip        = $attr->{FRAMED_IP_ADDRESS} || 0;
  my $PORT      = $attr->{PORT};
  my $netmask   = $attr->{NETMASK} || $attr->{netmask} || 32;
  my $FILTER_ID = $attr->{FILTER_ID} || '';
  my $nas_type  = $NAS->{NAS_TYPE};

  if ( $netmask ne '32' ){
    my $ips = 4294967296 - ip2int( $netmask );
    $netmask = 32 - length( sprintf( "%b", $ips ) ) + 1;
  }

  require Ipn_Collector;
  Ipn_Collector->import();
  my $Ipn = Ipn_Collector->new( $db, $CONF );

  $Ipn->acct_stop( { %{$attr},
      CID => $attr->{CID} || $attr->{CALLING_STATION_ID} || 'nas_hangup'
    } );

  if ( $Ipn->{errno} ){
    print "Error: [ $Ipn->{errno} ] $Ipn->{errstr} \n";
  }

  if ( $nas_type eq 'dhcp'
       || $nas_type eq 'mikrotik_dhcp'
       || $nas_type eq 'dlink_pb'
       || $nas_type eq 'dlink'
       || $nas_type eq 'edge_core'
     ){
    $Ipn->query2( "DELETE FROM dhcphosts_leases WHERE ip=INET_ATON('$ip')", 'do' );
  }

  my $num = 0;
  if ( $attr->{UID} && $CONF->{IPN_FW_RULE_UID} ){
    $num = $attr->{UID} || 0;
  }
  else{
    my @ip_array = split( /\./, $ip, 4 );
    $num = $ip_array[3] || 0;
  }

  my $rule_num = $CONF->{IPN_FW_FIRST_RULE} || 20000;
  $rule_num = $rule_num + 10000 + $num;

  if ( $NAS->{NAS_MNG_IP_PORT} ){
    ($ENV{NAS_IP_ADDRESS}, $ENV{NAS_MNG_PORT}) = split( /:/, $NAS->{NAS_MNG_IP_PORT} );
    $ENV{NAS_MNG_USER} = $NAS->{NAS_MNG_USER};
    $ENV{NAS_MNG_IP_PORT} = $NAS->{NAS_MNG_IP_PORT};
    $ENV{NAS_ID} = $NAS->{NAS_ID};
    $ENV{NAS_TYPE} = $NAS->{NAS_TYPE};
  }

  my $uid = $attr->{UID};

  if ( $CONF->{IPN_FILTER} ){
    my $cmd = $CONF->{IPN_FILTER};
    $cmd =~ s/\%STATUS/HANGUP/g;
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%FILTER_ID/$FILTER_ID/g;
    $cmd =~ s/\%UID/$uid/g;
    $cmd =~ s/\%PORT/$PORT/g;
    $cmd =~ s/\%MASK/$netmask/g;

    system( $cmd );
    print "IPN FILTER: $cmd\n" if ($attr->{DEBUG} && $attr->{DEBUG} > 5);
  }

  if ( $CONF->{IPN_FW_STOP_RULE} ){
    my $cmd = $CONF->{IPN_FW_STOP_RULE};
    $cmd =~ s/\%IP/$ip/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%NUM/$rule_num/g;
    $cmd =~ s/\%LOGIN/$USER_NAME/g;
    $cmd =~ s/\%MASK/$netmask/g;
    $cmd =~ s/\%OLD_TP_ID/$attr->{OLD_TP_ID}/g;

    $Log->log_print( 'LOG_DEBUG', '', "$cmd", { ACTION => 'CMD' } );
    if ( $attr->{DEBUG} && $attr->{DEBUG} > 4 ){
      print $cmd . "\n";
    }
    $result = system( $cmd );
  }

  return  $result;
}

#***********************************************************
# hangup_openvpn
#***********************************************************
sub hangup_openvpn{
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  my @commands = (">INFO:OpenVPN Management Interface Version 1 -- type 'help' for more info\tkill $USER",
    "SUCCESS: common name '$USER' found, 1 client(s) killed\texit");

  my $result = telnet_cmd( "$NAS->{NAS_MNG_IP_PORT}", \@commands );
  $Log->log_print( 'LOG_DEBUG', $USER, "$result", { ACTION => 'CMD' } );

  return 0;
}

#***********************************************************
=head2 hangup_cisco_isg($NAS, $PORT, $attr) - HANGUP Cisco ISG

   ip rcmd rcp-enable
   ip rcmd rsh-enable
   no ip rcmd domain-lookup
   ! ip rcmd remote-host ���_�����_��_cisco IP_address_���_���_�����_�_��������_�����������_������ ���_�����_��_�����_�����_�����_����������_������ enable
   ! ��������
   ip rcmd remote-host admin 192.168.0.254 root enable

=cut
#***********************************************************
sub hangup_cisco_isg{
  my ($NAS, $attr) = @_;

  my $exec    = '';
  my $command = '';
  my $user    = $attr->{USER};

  my ($nas_mng_ip, $coa_port, $ssh_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 3);

  if(! $coa_port) {
    $coa_port = 1700;
  }
  if(! $ssh_port) {
    $ssh_port = 22;
  }

  #RSH Version
  if ( $attr->{RSH_HANGUP} && $NAS->{NAS_MNG_USER} ){
    my $cisco_user = $NAS->{NAS_MNG_USER};
    $command = "/usr/bin/rsh -l $cisco_user $nas_mng_ip clear ip subscriber ip $attr->{FRAMED_IP_ADDRESS}";
    $Log->log_print( 'LOG_DEBUG', $user, $command, { ACTION => 'CMD' } );
    $exec = cmd($command);
  }

  # RADIUS POD Version
  else{
    my $type;
    my $r = Radius->new(
      Host   => "$nas_mng_ip:$coa_port",
      Secret => "$NAS->{NAS_MNG_PASSWORD}"
    ) or return "Can't connect '$NAS->{NAS_MNG_IP_PORT}' $!";

    $CONF->{'dictionary'} = '/usr/abills/lib/dictionary' if (!$CONF->{'dictionary'});
    $r->load_dictionary( $CONF->{'dictionary'} );

    $r->add_attributes( { Name => 'User-Name', Value => "$attr->{USER}" } );
    $r->add_attributes( { Name => 'Cisco-Account-Info', Value => "S$attr->{FRAMED_IP_ADDRESS}" } );
    $r->add_attributes( { Name => 'Cisco-AVPair', Value => "subscriber:command=account-logoff" } );

    $r->send_packet( 43 ) and $type = $r->recv_packet;

    my %RAD_PAIRS = ();
    for my $rad ( $r->get_attributes ){
      $RAD_PAIRS{ $rad->{'Name'} } = $rad->{'Value'};
    }

    if ( $RAD_PAIRS{'Error-Cause'} ){

      #log_print('LOG_WARNING', "$RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}");
      print "$RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}";
      print %RAD_PAIRS;
    }

    #print "Can't find 'NAS_MNG_USER'\n";
  }

  return $exec;
}

#***********************************************************
=head2 hangup_cisco($NAS, $attr) - HANGUP Cisco


 Cisco config  for rsh functions:
   ip rcmd rcp-enable
   ip rcmd rsh-enable
   no ip rcmd domain-lookup
   ! ip rcmd remote-host ���_�����_��_cisco IP_address_���_���_�����_�_��������_�����������_������  ��_�����_��_�����_�����_�����_����������_������ enable
   ! ��������
   ip rcmd remote-host admin 192.168.0.254 root enable

=cut
#***********************************************************
sub hangup_cisco{
  my ($NAS, $attr) = @_;
  my $exec;
  my $command = '';
  my $user = $attr->{USER};
  my $PORT = $attr->{PORT};

  my ($nas_mng_ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 2 );

  #POD Version
  if ( $mng_port && $mng_port == 1700 ){
    hangup_radius( $NAS, $attr );
  }
  #Rsh version
  elsif ( $NAS->{NAS_MNG_USER} ){
    my $cisco_user = $NAS->{NAS_MNG_USER};
    if ( $PORT > 0 ){
      $| = 1;
      $command = "(/bin/sleep 5; /bin/echo 'y') | /usr/bin/rsh -4 -l $cisco_user $nas_mng_ip clear line $PORT";
      $Log->log_print( 'LOG_DEBUG', "$user", "$command", { ACTION => 'CMD' } );
      $exec = `$command`;
      return $exec;
    }

    $command = "/usr/bin/rsh -l $cisco_user $nas_mng_ip show users | grep -i \" $user \" ";

    #| awk '{print \$1}';";
    $Log->log_print( 'LOG_DEBUG', "$command" );
    my $out = `$command`;

    if ( $out eq '' ){
      print 'Can\'t get VIRTUALINT. Check permissions';
      return 'Can\'t get VIRTUALINT. Check permissions';
    }

    my $VIRTUALINT;

    if ( $out =~ /\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)/ ){
      $VIRTUALINT = $1;
      my $tty = $2;
      my $line = $3;
      my $cuser = $4;
      my $chost = $5;

      print "$VIRTUALINT, $tty, $line, $cuser, $chost";
    }

    $command = "echo $VIRTUALINT echo  | sed -e \"s/[[:alpha:]]*\\([[:digit:]]\\{1,\\}\\)/\\1/\"";
    $Log->log_print( 'LOG_DEBUG', "$command" );
    $PORT = `$command`;
    $command = "/usr/bin/rsh -4 -n -l $cisco_user $nas_mng_ip clear interface Virtual-Access $PORT";
    $Log->log_print( 'LOG_DEBUG', $user, "$command", { ACTION => 'CMD' } );
    $exec = `$command`;
  }
  else{
    #SNMP version
    my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
    my $INTNUM = snmpget( "$SNMP_COM\@$nas_mng_ip", ".1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}" );
    $Log->log_print( 'LOG_DEBUG', "$user",
      "SNMP: $SNMP_COM\@$nas_mng_ip .1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}", { ACTION => 'CMD' } );
    $exec = snmpset( "$SNMP_COM\@$NAS->{NAS_IP}", ".1.3.6.1.2.1.2.2.1.7.$INTNUM", 'integer', 2 );
    $Log->log_print( 'LOG_DEBUG', "$user", "SNMP: $SNMP_COM\@$nas_mng_ip .1.3.6.1.2.1.2.2.1.7.$INTNUM integer 2",
      { ACTION => 'CMD' } );
  }

  return $exec;
}

#***********************************************************
# HANGUP dslmax
# hangup_dslmax($SERVER, $PORT)
#***********************************************************
sub hangup_dslmax{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  #cotrol
  my @commands = ();
  push @commands, "word:\t$NAS->{NAS_MNG_PASSWORD}";
  push @commands, ">\treset S$PORT";
  push @commands, ">exit";

  my $result = telnet_cmd( "$NAS->{NAS_IP}", \@commands );

  print $result;

  return 0;
}

#####################################################################
# Exppp functions
#***********************************************************
# HANGUP ExPPP
# hangup_exppp($SERVER, $PORT)
#***********************************************************
sub hangup_exppp{
  my ($NAS, $PORT) = @_;

  my ($ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 2 );

  my $ctl_port = $mng_port + $PORT;
  my $PPPCTL = '/usr/sbin/pppctl';
  undef = `$PPPCTL -p "$NAS->{NAS_MNG_PASSWORD}" $ip:$ctl_port down`;

  return 0;
}

#***********************************************************
# HANGUP MPD
# hangup_mpd4($SERVER, $PORT)
#***********************************************************
sub hangup_mpd4{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  my $ctl_port = "pptp$PORT";
  if ( $attr->{ACCT_SESSION_ID} ){
    if ( $attr->{ACCT_SESSION_ID} =~ /\d+\-(.+)/ ){
      $ctl_port = $1;
    }
  }

  my @commands = ("\t", "Username: \t$NAS->{NAS_MNG_USER}", "Password: \t$NAS->{NAS_MNG_PASSWORD}",
    "\\[\\] \tbundle $ctl_port", "\] \tclose", "\] \texit");

  my $result = telnet_cmd( "$NAS->{NAS_MNG_IP_PORT}", \@commands );

  return $result;
}

#***********************************************************
=head1 hangup_mpd5($NAS, $PORT, $USER, $attr) - HANGUP MPD

=cut
#***********************************************************
sub hangup_mpd5{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  #my $USER = $attr->{USER};

  if ( !$NAS->{NAS_MNG_IP_PORT} ){
    print "MPD Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID}\n";
    return "Error";
  }

  my ($hostname, $radius_port, $telnet_port) = ('127.0.0.1', '3799', '5005');

  ($hostname, $radius_port, $telnet_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 3 );

  if ( !$attr->{LOCAL_HANGUP} ){
    $NAS->{NAS_MNG_IP_PORT} = "$hostname:$radius_port";
    return hangup_radius( $NAS, $attr );
  }

  $hostname = '127.0.0.1';
  my $ctl_port = "L-$PORT";
  if ( $attr->{ACCT_SESSION_ID} ){
    if ( $attr->{ACCT_SESSION_ID} =~ /^\d+\-(.+)/ ){
      $ctl_port = $1;
    }
  }

  $Log->log_print( 'LOG_DEBUG', $USER_NAME,
    " HANGUP: SESSION: $ctl_port NAS_MNG: $NAS->{NAS_MNG_IP_PORT} '$NAS->{NAS_MNG_PASSWORD}'", { ACTION => 'CMD' } );

  my @commands = ("\t", "Username: \t$NAS->{NAS_MNG_USER}", "Password: \t$NAS->{NAS_MNG_PASSWORD}",
    "\\[\\] \tlink $ctl_port", "\] \tclose", "\] \texit");

  if ( $attr->{IFACE} ){
    $commands[3] = "\\[\\] \tiface $attr->{IFACE}";
  }

  my $result = telnet_cmd( "$hostname:$telnet_port", \@commands, { DEBUG => 1 } );

  return $result;
}

#***********************************************************
# HANGUP MPD
# hangup_mpd($SERVER, $PORT)
#***********************************************************
sub hangup_mpd{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};
  my $ctl_port = "pptp$PORT";
  my @commands = ("\]\tlink $ctl_port", "\]\tlink $ctl_port", "\]\tclose", "\]\texit");

  my $result = telnet_cmd( "$NAS->{NAS_MNG_IP_PORT}", \@commands );

  print $result;

  return 0;
}

#####################################################################
# radppp functions
#***********************************************************
# HANGUP radpppd
# hangup_radpppd($SERVER, $PORT)
#***********************************************************
sub hangup_radpppd{
  my (undef, $PORT) = @_;

  my $RUN_DIR = '/var/run';
  my $CAT = '/bin/cat';
  my $KILL = '/bin/kill';

  my $PID_FILE = "$RUN_DIR/PPP$PORT.pid";
  my $PPP_PID = `$CAT $PID_FILE`;
  my $res = `$KILL -1 $PPP_PID`;

  return $res;
}

#***********************************************************
# Get stats for pppd connection from firewall
#
# get_pppd_stats ($SERVER, $PORT, $IP)
#***********************************************************
sub stats_pppd{
  my ($NAS, $PORT) = @_;

  my $firstnumber = 1000;
  my $step = 10;
  my $innum = $firstnumber + $PORT * $step;
  my $outnum = $firstnumber + $PORT * $step + 5;

  my %stats = ();

  $stats{ $NAS->{NAS_IP} }{$PORT}{in} = 0;
  $stats{ $NAS->{NAS_IP} }{$PORT}{out} = 0;

  # 01000    369242     53878162 count ip from any to any in via 217.196.163.253
  open( my $FW, '|-', "/usr/sbin/ipfw $innum $outnum" ) || die "Can't open '/usr/sbin/ipfw' $!\n";
  while (<$FW>) {
    my ($num, undef, $bytes, undef) = split( / +/, $_, 4 );
    if ( $innum == $num ){
      $stats{$NAS->{NAS_IP}}{$PORT}{in} = $bytes;
    }
    elsif ( $outnum == $num ){
      $stats{$NAS->{NAS_IP}}{$PORT}{in} = $bytes;
    }
  }
  close( $FW );

  return 1;
}

#***********************************************************
# HANGUP pppd
# hangup_pppd($SERVER, $PORT)
# add next string to  /etc/sudoers:
#
# apache   ALL = NOPASSWD: /usr/abills/misc/pppd_kill
#
#***********************************************************
sub hangup_pppd{
  my ($NAS, $attr) = @_;
  my $IP = $attr->{FRAMED_IP_ADDRESS};
  my $result = '';

  if ( $NAS->{NAS_MNG_IP_PORT} =~ /:/ ){
    my ($ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 2 );
    use IO::Socket;

    my $remote = IO::Socket::INET->new(
      Proto    => "tcp",
      PeerAddr => "$ip",
      PeerPort => $mng_port
    ) or die "cannot connect to pppd disconnect port at $ip:$mng_port $!\n";

    print $remote "$IP\n";
    $result = <$remote>;
    print "Hanguped: $IP\n" if ($debug > 1);
  }
  else{
    $result = system( "/usr/bin/sudo /usr/abills/misc/pppd_kill $IP" );
  }

  return $result;
}

#***********************************************************
# HANGUP Patton 29xx
#***********************************************************
sub hangup_patton29xx{
  my ($NAS, $attr) = @_;
  my $exec = '';

  my $PORT = $attr->{PORT};
  # Get active sessions
  my %active = ();
  my @arr = snmpwalk( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3" );
  foreach my $line ( @arr ){
    if ( $line =~ /(\d+):6/ ){
      $active{$1} = 1;
    }
  }

  #Get iface
  @arr = snmpwalk( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.9" );
  foreach my $line ( @arr ){
    if ( $line =~ /(\d+):(\d+)/ ){
      if ( $2 == $PORT && $active{$1} ){
        $exec = snmpset( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3.$1", 'integer', 10 );

        #print " IFACE: $iface INDEX $1 IN: $in OUT: $out\n";
        last;
      }
    }
  }

  return $exec;
}

#***********************************************************
# Get stats from Patton RAS 29xx
#
#***********************************************************
sub stats_patton29xx{
  my ($NAS, $attr) = @_;

  my $PORT = $attr->{PORT};

  my %stats = (
    in  => 0,
    out => 0
  );

  # Get active sessions
  my %active = ();
  my @arr = snmpwalk( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3" );
  foreach my $line ( @arr ){
    if ( $line =~ /(\d+):6/ ){
      $active{$1} = 1;
    }
  }

  #Get iface
  @arr = snmpwalk( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.9" );
  foreach my $line ( @arr ){
    if ( $line =~ /(\d+):(\d+)/ ){
      if ( $2 == $PORT && $active{$1} ){
        $stats{out} = snmpget( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.36.$1" );
        $stats{in} = snmpget( "$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.37.$1" );

        $Log->log_print( 'LOG_DEBUG', '', "IFACE: $line INDEX $1 IN: $stats{in} OUT: $stats{out}",
          { ACTION => 'CMD' } );
        last;
      }
    }
  }

  return %stats;
}

#***********************************************************
# hangup_hangup_pppd_coa
#
# Radius-Disconnect messages for radcoad
# rfc3576
#***********************************************************
sub hangup_pppd_coa{
  my ($NAS, $PORT, $attr) = @_;

  my ($ip, $mng_port) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 2 );
  $Log->log_print( 'LOG_DEBUG', '', " HANGUP: NAS_MNG: $ip:$mng_port '$NAS->{NAS_MNG_PASSWORD}'", { ACTION => 'CMD' } );

  my $type;
  my $result = 0;
  my $r = Radius->new(
    Host   => "$NAS->{NAS_MNG_IP_PORT}",
    Secret => "$NAS->{NAS_MNG_PASSWORD}"
  ) or return "Can't connect '$NAS->{NAS_MNG_IP_PORT}' $!";

  $CONF->{'dictionary'} = '/usr/abills/lib/dictionary' if (!$CONF->{'dictionary'});

  $r->load_dictionary( $CONF->{'dictionary'} );

  $r->add_attributes( { Name => 'Framed-Protocol', Value => 'PPP' }, { Name => 'NAS-Port', Value => "$PORT" } );
  $r->add_attributes( { Name => 'Framed-IP-Address', Value =>
      "$attr->{FRAMED_IP_ADDRESS}" } ) if ($attr->{FRAMED_IP_ADDRESS});
  $r->send_packet( POD_REQUEST ) and $type = $r->recv_packet;

  if ( !defined $type ){
    # No responce from POD server
    $result = 1;
    $Log->log_print( 'LOG_DEBUG', '', "No responce from POD server '$NAS->{NAS_MNG_IP_PORT}' ", { ACTION => '' } );
  }

  my $nas_type = $attr->{NAS_TYPE};
  if ( $nas_type eq 'pppd_coa' || $nas_type eq 'accel_ppp' ){
    return 1;
  }

  return $result;
}

#***********************************************************
# Set speed for port
# setspeed($NAS_HASH_REF, $PORT, $USER, $UPSPEED, $DOWNSPEED, $attr);
#***********************************************************
sub setspeed{
  my ($Nas, $PORT, undef, $UPSPEED, $DOWNSPEED, $attr) = @_;

  my $nas_type = $Nas->{NAS_TYPE};

  if ( $nas_type eq 'pppd_coa' || $nas_type eq 'accel_ppp' || $nas_type eq 'accel_ipoe' ){
    return setspeed_pppd_coa( $Nas, $PORT, $UPSPEED, $DOWNSPEED, $attr );
  }
  else{
    return -1;
  }

  return 0;
}

#***********************************************************
=head2  hascoa($NAS); - Check CoA support

=cut
#***********************************************************
sub hascoa{
  my ($NAS) = @_;

  my $nas_type = $NAS->{NAS_TYPE};

  if ( $nas_type eq 'pppd_coa' ){
    return 1;
  }
  elsif ($CONF->{coa_send} && $nas_type =~ /$CONF->{coa_send}/ ){
    return 1;
  }

  return 0;
}

#***********************************************************
# setspeed_pppd_coa
#
# Radius-CoA messages for radcoad
# rfc3576
#***********************************************************
sub setspeed_pppd_coa{
  my ($NAS, $PORT, $UPSPEED, $DOWNSPEED, $attr) = @_;

  my ($ip, $mng_port, undef) = split( /:/, $NAS->{NAS_MNG_IP_PORT}, 3 );
  $Log->log_print( 'LOG_DEBUG', '', " SETSPEED: NAS_MNG: $ip:$mng_port '$NAS->{NAS_MNG_PASSWORD}'" );

  if ( !$mng_port ){
    $mng_port = 3799;
  }

  my $type;
  my $result = 0;
  my $r = Radius->new(
    Host   => "$ip:$mng_port",
    Secret => "$NAS->{NAS_MNG_PASSWORD}"
  ) or return "Can't connect '$ip:$mng_port' $!";

  $CONF->{'dictionary'} = '/usr/abills/lib/dictionary' if (!$CONF->{'dictionary'});

  $r->load_dictionary( $CONF->{'dictionary'} );

  $r->add_attributes( { Name => 'Framed-Protocol', Value => 'PPP' },
    { Name => 'NAS-Port', Value => "$PORT" },
    { Name => 'PPPD-Upstream-Speed-Limit', Value => "$UPSPEED" },
    { Name => 'PPPD-Downstream-Speed-Limit', Value => "$DOWNSPEED" } );

  $r->add_attributes( { Name => 'Framed-IP-Address', Value =>
      "$attr->{FRAMED_IP_ADDRESS}" } ) if ($attr->{FRAMED_IP_ADDRESS});
  $r->send_packet( COA_REQUEST ) and $type = $r->recv_packet;

  if ( !defined $type ){
    # No responce from CoA server
    #log_print('LOG_DEBUG',
    print "No responce from CoA server '$NAS->{NAS_MNG_IP_PORT}'";
    return 1;
  }

  return $result;
}

#***************************************************************
=head2 hangup_unifi($NAS, $PORT, $USER, $attr) - Hangup unifi

=cut
#***************************************************************
sub hangup_unifi {
  my ($NAS, $attr) = @_;

  my $USER = $attr->{USER};
  if ( !$NAS->{NAS_MNG_IP_PORT} ){
    print "Radius Hangup failed. Can't find NAS IP and port. NAS: $NAS->{NAS_ID} USER: $USER\n";
    return 'ERR:';
  }

  require Unifi::Unifi;
  Unifi->import();

  my $Unifi = Unifi->new( $CONF );
  $Unifi->{unifi_url} = 'https://' . $NAS->{NAS_MNG_IP_PORT};
  $Unifi->{login} = $NAS->{NAS_MNG_USER};
  $Unifi->{password} = $NAS->{NAS_MNG_PASSWORD};

  my $result = $Unifi->deauthorize( { MAC => $attr->{CID} || $attr->{CALLING_STATION_ID} } );

  return $result;
}

#***************************************************************
=head2 rsh_cmd($command, $attr) - rsh cmd

  Arguments:
    $command
    $attr
       NAS_MNG_USER
       NAS_MNG_IP_PORT

  Results:
    command result

=cut
#***************************************************************
sub rsh_cmd{
  my ($cmd, $attr) = @_;

  if ( !$cmd ){
    return 0;
  }

  my $mng_port;
  my $mng_user = $attr->{NAS_MNG_USER} || '';
  my $ip;
  ($ip, $mng_port) = split( /:/, $attr->{NAS_MNG_IP_PORT}, 2 );

  $cmd =~ s/\\\"/\"/g;

  my $command = "/usr/bin/rsh -o StrictHostKeyChecking=no -l $mng_user $ip \"$cmd\"";
  if ($Log) {
    $Log->log_print( 'LOG_DEBUG', '', "$command", { ACTION => 'CMD' } );
  }
  my $result = cmd( $command, { RESULT_ARRAY => 1, %{$attr} } );
  return $result;
}

1
