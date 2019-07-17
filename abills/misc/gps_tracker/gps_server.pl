#!/usr/bin/perl -w
=head1 NAME

  GPS Server

=head2 FILENAME

  gps_server.pl

=head2 AUTHOR

  Anykey

=head2 SYNOPSIS

=cut
use strict;
use warnings;

use vars qw( %conf
  $DATE
  $TIME
  );

BEGIN {
  use FindBin '$Bin';

  my $libpath = "$Bin/../";
  require "$libpath/libexec/config.pl";
  unshift(@INC,
    "$libpath/",
    "$libpath/Abills",
    "$libpath/lib/",
    "$libpath/Abills/$conf{dbtype}"
  );
}

require Log;
Log->import('log_add');
my $Log = Log->new(undef, \%conf);

use Abills::Base;
use Abills::Server;

require Abills::SQL;
my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});

use GPS;
#passing undef for $admin
my $Gps = GPS->new($db, undef, \%conf);

use IO::Socket::INET;
# auto-flush on socket
$| = 1;

my $debug = 1;
my $prog_name = "GPS Tracker Server";
my $version = 0.1;

my $ARGS = parse_arguments(\@ARGV);

# демонизация и ведение лога
if (defined($ARGS->{'-d'})) {
  my $pid_file = daemonize();
  # ведение лога
  $Log->log_print('LOG_EMERG', '', "$prog_name Daemonize... $pid_file");
}
#Стоп процесса
elsif (defined($ARGS->{stop})) {
  stop_server();
  exit;
}
#проверка не запущен ли уже
elsif (make_pid() == 1) {
  exit;
}

if (defined($ARGS->{DEBUG})) {
  print "Debug mode on\n";
  $debug = $ARGS->{DEBUG};

  if ($debug >= 7){ $Gps->{debug} = 1 };
}

#Читаем порт сервера
my $port = $ARGS->{PORT} || '8790';

my $log_file = '/tmp/gps_tracker.log';
if (defined $ARGS->{LOG_FILE}) {
  $log_file = $ARGS->{LOG_FILE};
}
$Log->{LOG_FILE} = $log_file;

#if ($debug >= 3) {
#  $Log->{PRINT} = 1;
#}

# creating a listening socket
my $socket = IO::Socket::INET->new (
  LocalHost => '0.0.0.0',
  LocalPort => $port,
  Proto     => 'tcp',
  Listen    => 5,
  Reuse     => 1
);

die "cannot create socket $!\n" unless ($socket);
print "server waiting for client connection on port $port\n";

log_debug(localtime(), "SERVER STARTED", 1);

while(1)
{
  # waiting for a new client connection
  my $client_socket = $socket->accept();

  # get information about a newly connected client
  my $client_address = $client_socket->peerhost();
  my $client_port = $client_socket->peerport();
  log_debug( "Connection", localtime() . ". Connection from $client_address:$client_port\n", 1 );

  # read up to 2048 (max GET length) characters from the connected client
  my $data = "";
  $client_socket->recv($data, 2048);

  log_debug("Raw HTTP", $data, 4);

  my $FORM = parse_http_request($data);
  if ($FORM->{id} ne ''){
    my $mappings = get_traccar_mappings();
    my $unified_data = unify_data($FORM, $mappings);

    my $response = write_to_db($unified_data, $client_address);

    # write response data to the connected client
    $client_socket->send("HTTP/1.1 200 OK \n\n");
  }

  # notify client that response has been sent
  shutdown($client_socket, 1);
}

$socket->close();


=head2  - get_admin_id_by_tracker_id
=cut
sub get_admin_id_by_tracker_id {
  my ($gps_id) = @_;
  #Refactored
  return $Gps->tracked_admin_id_by_imei($gps_id);
}

=head2 write_to_db


=cut
sub write_to_db {
  my ($attr, $ip_address) = @_;

  log_debug("Client ID", $attr->{GPS_IMEI}, 1 );

#  log_debug("DATA TO SEND", [ keys %{$attr} ], 2);

  my $admin_id = get_admin_id_by_tracker_id($attr->{GPS_IMEI});

  unless ($admin_id){
    log_debug("WRONG GPS ID","Administrator with such ID not found. ID is $attr->{GPS_IMEI}", 1);
    write_unregistered({ %$attr, ( IP => $ip_address ) });
    return " Unregistered ";
  }

  $attr->{AID} = $admin_id;

  $Gps->location_add($attr);

  return " OK ";
}

=head2 - write_unregistered

  Save unregistered tracker information to DB

=cut
sub write_unregistered {
  my ($attr) = @_;

  $Gps->unregistered_trackers_add( $attr );

  return 1;
}

=head2 parse_http_request


=cut
sub parse_http_request {
  my ($http_request) = @_;
  my $FORM = { };

  # Cut query from header;
  my $buffer = [ split(/\n/, $http_request) ]->[0];
  $buffer =~ s/^.*\?//;
  $buffer =~ s/\s.*$//;

  my @pairs = split(/&/, $buffer);
  $FORM->{__BUFFER} = $buffer if ($#pairs > -1);

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair, 2);
    if (defined($value)) {
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $value =~ s/<!--(.|\n)*-->//g;
      $value =~ s/<([^>]|\n)*>//g;
    }
    else {
      $value = '';
    }
    $FORM->{$side} = $value;
  }

  return $FORM;
}

=head2 - get_traccar_mappings
 mappings are used to map data from different sources to one default view
 traccar was first implemented client, so we are using it's scheme as default
=cut
sub get_traccar_mappings {

=pod
  This is representation of data got from traccar;
  $VAR1 = {
    'speed' => '0.0',
    'lon' => '25.079458951950073',
    'batt' => '48.0',
    'lat' => '48.569440841674805',
    'altitude' => '354.0',
    'bearing' => '8.0859375',
    'id' => '617323',
    'timestamp' => '1452233539'
  };
=cut


  return {
    'GPS_IMEI'  => 'id',
    'GPS_TIME' => 'timestamp',
    'COORD_X'   => 'lat',
    'COORD_Y'   => 'lon',
    'SPEED'     => 'speed',
    'BEARING'   => 'bearing',
    'ALTITUDE'  => 'altitude',
    'BATT'      => 'batt'
  };
}

=head2 - unify_data


=cut
sub unify_data {
  my ($FORM, $mappings) = @_;

  my $data = { };

  for my $key (keys %{$mappings}) {
#    log_debug("INPUT_DATA", "$key -> $mappings->{$key} -> $FORM->{$mappings->{$key}} ", 3);
    $data->{$key} = $FORM->{$mappings->{$key}};
  }

  return $data;
}

=head2 - log_debug


=cut
sub log_debug {
  my ($name, $str, $level) = @_;

  my $log_line = '';

  if (ref $str eq 'ARRAY') {
    $str = join ", ", @{$str};
  }

  if ($debug >= $level) {
    $log_line .= "$name : $str \n";
  }

  $Log->log_print('LOG_INFO', $prog_name, $log_line, { LOG_FILE => $log_file } );
}

1;
