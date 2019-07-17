package Abills::Sender::Browser;
use strict;
use warnings FATAL => 'all';

use AnyEvent::Socket;
use AnyEvent::Handle;
use Abills::Misc;

use Abills::Base qw/_bp in_array/;

use JSON qw//;

my $PING_REQUEST = '{"TYPE":"PING"}';
my $PING_RESPONCE = '{"TYPE":"PONG"}';

my JSON $json = JSON->new->utf8;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF, $attr) = @_;

  my $connection_host = $CONF->{WEBSOCKET_HOST} || '127.0.0.1:19444';

  my ($host, $port) = split( ':', $connection_host );
  my $self = {
    conf            => $CONF,
    connection_host => $connection_host,
    host            => $host,
    port            => $port,
  };

  # Because of sync calls need to wait for connection
  my $connection_wait = AnyEvent->condvar;
  tcp_connect $host, $port, sub {
      my ($fh) = @_;
      $connection_wait->send( AnyEvent::Handle->new( fh => $fh, no_delay => 1 ) );
    };

  #Wait until got connection
  $self->{fh} = $connection_wait->recv;

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 is_connected() - check if connected to internal WebSocket server

=cut
#**********************************************************
sub is_connected {
  my ($self) = @_;

  my $responce = $self->_synchronous_request( { MESSAGE => $PING_REQUEST } );

  return 0 unless ($responce);
  return $responce =~ /$PING_RESPONCE/;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr -
      UID|AID  - string, receiver ( TODO: '*' to send to all of this type)
      MESSAGE  - string, text of message
      
      NON_SAFE - boolean, will use instant request (without confirmation)
     
      ASYNC    - coderef, asynchronous callback

  Returns:
    1 if sended;

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;

  my $receiver_type = (exists $attr->{AID}) ? 'ADMIN' : 'CLIENT';
  my $receiver_id = $attr->{AID} || $attr->{UID};

  # Has no one to send message to
  return undef unless ($receiver_id);

  if (ref $attr->{MESSAGE} eq 'HASH'){
    if ($attr->{NON_SAFE}){
      $attr->{MESSAGE}{SILENT} = 1;
    }
    
    $attr->{MESSAGE} = $json->encode($attr->{MESSAGE});
  }

  my %payload = (
    TYPE => 'MESSAGE',
    TO   => $receiver_type,
    ID   => $receiver_id,
    DATA => $attr->{MESSAGE}
  );

  return $self->_request($attr, \%payload);
}

#**********************************************************
=head2 connected_admins()

  Returns:
    list - aids of connected admins

=cut
#**********************************************************
sub connected_admins {
  my $self = shift;

  my %request = (
    TYPE      => 'REQUEST_LIST',
    LIST_TYPE => 'ADMINS',
  );

  my $responce = $self->json_request( { MESSAGE => $json->encode( \%request ) } );

  #TODO: check for errors
  my $connected = $responce->{LIST};

  return $connected;
}

#**********************************************************
=head2 has_connected_admin($aid) - check if certain admin is present in connected sockets

  Arguments:
    $aid - admin ID

  Returns:
    boolean - if connected

=cut
#**********************************************************
sub has_connected_admin {
  my $self = shift;
  my ( $aid ) = @_;

  my $admins = $self->connected_admins();

  return in_array( $aid, $admins );
}

#**********************************************************
=head2 call($aid, $message) - send message and receive responce

  Arguments:
    $aid     - Admin ID
    $message - json
      DATA

  Returns:
    hash - responce

=cut
#**********************************************************
sub call {
  my $self = shift;
  my ($aid, $message, $attr) = @_;

  $attr->{MESSAGE} = {
    TYPE => 'MESSAGE',
    TO   => 'ADMIN',
    ID   => $aid,
    DATA => $message,
  };

  return $self->json_request( $attr );
}

#**********************************************************
=head2 json_request($attr) - simple alias to get perl structure as result

  Arguments:
    $attr - hash_ref
      MESSAGE - JSON string

  Returns:
    hash_ref - result
    undef on timeout

=cut
#**********************************************************
sub json_request {
  my $self = shift;
  my ($attr) = @_;
  
  if (ref $attr->{MESSAGE} eq 'HASH' && $attr->{NON_SAFE}) {
      $attr->{MESSAGE}->{SILENT} = 1;
  }
  
  if ($attr->{ASYNC}){
    my $cb = $attr->{ASYNC};
    
    # Override function to make it receive perl structure
    $attr->{ASYNC} = sub {
      my $res = shift;
      $cb->($res ? safe_json_decode($res) : $res);
    };
  }
  
  $attr->{RETURN_RESULT} = 1;
  my $responce = $self->_request( $attr, $attr->{MESSAGE} );
  
  return $responce ? safe_json_decode( $responce ) : 0;
}


#**********************************************************
=head2 _request($attr) - Request types wrapper

  Arguments:
    $attr -
      NON_SAFE
      ASYNC
      RETURN_RESULT
      
  Returns:
    
    
=cut
#**********************************************************
sub _request {
  my ($self, $attr, $payload) = @_;
  
  $payload = $json->encode( $payload ) if (ref $payload);
  
  if ( $attr->{NON_SAFE} ) {
    return $self->_instant_request({
      MESSAGE => $payload
    });
  }
  elsif ( $attr->{ASYNC} && ref $attr->{ASYNC} ) {
    $self->_asynchronous_request({
      MESSAGE  => $payload,
      CALLBACK => $attr->{ASYNC},
    });
    return;
  }
  
  my $sended = $self->_synchronous_request( {
    MESSAGE => $payload
  } );
  
  return ($attr->{RETURN_RESULT}) ? $sended : defined $sended;
  
  return;
}

#**********************************************************
=head2 _asynchronous_request($attr) - will write to socket and run callback, when receive result

  Arguments:
    $attr - hash_ref
      MESSAGE  - text will be send to backend server
      CALLBACK - function($result)
        $result will be
          string - if server responded with message
          ''     - if server accepted message, but not responded nothing
          undef  - if timeout

  Returns:
    undef
    

=cut
#**********************************************************
sub _asynchronous_request {
  my ($self, $attr) = @_;
  
  my $callback_func = $attr->{CALLBACK};
  my $message = $attr->{MESSAGE};
  
  my AnyEvent::Handle $handle = $self->{fh};
  
  # Setup recieve callback
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;
      
      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;
      
      $callback_func->( $readed );
    }
  );
  
  $handle->push_write( $message );
  
  return 1;
}

#**********************************************************
=head2 _synchronous_request($attr)

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    string - if server responded with message
    ''     - if server accepted message, but not responded nothing
    undef  - if timeout

=cut
#**********************************************************
sub _synchronous_request {
  my ($self, $attr) = @_;
  
  my $message = $attr->{MESSAGE} || return;
  my AnyEvent::Handle $handle = $self->{fh};
  
  # Setup recieve callback
  my $operation_end_waiter = AnyEvent->condvar;
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;

      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;

      $operation_end_waiter->send( $readed );
    }
  );
  
  # Set timeout to 2 seconds
  my $timeout_waiter = AnyEvent->timer(
    after => 2,
    cb    => sub {
      _bp("Abills::Sender::Browser", "$self->{host} Timeout" , { TO_CONSOLE => 1}) if ($self->{debug});
      $operation_end_waiter->send(undef);
    }
  );
  
  $handle->push_write( $message );

  # Result will come here when other end responses or on timeout
  return $operation_end_waiter->recv;
};

#**********************************************************
=head2 _instant_request($attr) - will not wait for timeout, but no warranties for receive

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    1
    
=cut
#**********************************************************
sub _instant_request {
  my $self = shift;
  my ($attr) = @_;

  $self->{fh}->on_read(
    sub {
      shift->{rbuf} = undef;
    }
  );
  
  $self->{fh}->push_write($attr->{MESSAGE});
  
  return 1;
}

#**********************************************************
=head2 safe_json_decode($json_string)

=cut
#**********************************************************
sub safe_json_decode {
  my $str = shift;
  return eval{ $json->decode($str) } || return "Error parsing JSON: $@. \n Got: " . ($str // '');
}

1;