package Abills::Backend::Plugin::Satellite;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abills::Backend::Plugin::Satellite

=head2 SYNOPSIS

  Plugin to control remote servers

=cut

use base 'Abills::Backend::Plugin::BasePlugin';

our ($base_dir);
if (!$base_dir){
  our $Bin;
  require FindBin;
  FindBin->import('$Bin');
  
  if ($Bin =~ m/\/usr\/abills(\/)/){
    $base_dir = substr($Bin, 0, $-[1]);
  }
}

use Abills::Backend::Plugin::Satellite::API;

use Abills::Backend::Log;
my Abills::Backend::Log $Log;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new{
  my $class = shift;

  my ($CONF) = @_;

  if (!$CONF->{SATELLITE_MODE}){
    die '$CONF->{SATELLITE_MODE} is not set' . "\n";
  }
  
  my $self = {
    conf  => $CONF,
  };
  
  $Log = Abills::Backend::Log->new('FILE', $CONF->{SATELLITE_DEBUG} || 7,
    'Satellite', {
      FILE => $CONF->{SATELLITE_DEBUG_FILE} || ($base_dir || '/usr/abills/') . '/var/log/satellite.log'
    });
  
  bless( $self, $class );

  return $self;
}



#**********************************************************
=head2 init($conf, $attr) -

  Arguments:
    $conf -
      SATELLITE_MODE         - mode for this daemon ('Client', 'Server')
      SATELLITE_SERVER_PORT  - default is 19422
      SATELLITE_SERVER_HOST  - required for client and is default 0.0.0.0 for server
      SATELLITE_SECRET_KEY   - required or $conf{SECRET_KEY}
      
  Returns:
    API
  
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  my %conf = %{$self->{conf}};
  
  $self->{server_port} = $conf{SATELLITE_SERVER_PORT} || 19422;
  
  if ($conf{SATELLITE_MODE} eq 'Server'){
    $self->{server_host} = $conf{SATELLITE_SERVER_HOST} || '0.0.0.0';
    $Log->notice("Starting server");
    $self->init_server($attr);
  }
  else {
    die "No \$conf->{SATELLITE_SERVER_HOST} specified \n" unless ($conf{SATELLITE_SERVER_HOST});
    $self->{server_host} = $conf{SATELLITE_SERVER_HOST};
    $Log->notice("Starting client");
    $self->init_client($attr);
  }
  
  return Abills::Backend::Plugin::Satellite::API->new($self->{conf}, $self);
}

#**********************************************************
=head2 init_server($attr) - starts tcp server

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub init_server {
  my ($self, $attr) = @_;
  
  require Abills::Backend::Plugin::Satellite::Server;
  
  my $server = Abills::Backend::Plugin::Satellite::Server->new($self->{conf}, { LOG => $Log });
  
  $server->init({
    SERVER_PORT => $self->{server_port},
    SERVER_HOST => $self->{server_host}
  });
  
  $self->{server} = $server;
  
  return $self;
}

#**********************************************************
=head2 init_client($attr) - receives services to see and start timers for health check

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub init_client {
  my ($self, $attr) = @_;
  
  require Abills::Backend::Plugin::Satellite::Client;
  my $client = Abills::Backend::Plugin::Satellite::Client->new($self->{conf}, { LOG => $Log });
  
  $client->init({
    SERVER_PORT => $self->{server_port},
    SERVER_HOST => $self->{server_host}
  });
  
  $self->{client} = $client;
  
  return $self;
}


1;