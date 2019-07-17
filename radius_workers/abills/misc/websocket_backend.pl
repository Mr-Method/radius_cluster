#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

our (%conf);
our @MODULES;
BEGIN {
  use FindBin '$Bin';

  my $libpath = $Bin . '/../'; #assuming we are in /usr/abills/misc/
  require "$libpath/libexec/config.pl";
  
  unshift( @INC,
    "$libpath",
    "$libpath/Abills",
    "$libpath/lib",
    "$libpath/Abills/modules",
    "$libpath/Abills/$conf{dbtype}"
  );
}

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Impl::Perl;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use JSON;
use Encode;

use Abills::Base;
use Abills::Server;
use Log;

use Abills::Base qw/_bp/;

use Admins;
use Users;

require Abills::SQL;
my $db = Abills::SQL->connect(
  $conf{dbtype},
  $conf{dbhost},
  $conf{dbname},
  $conf{dbuser},
  $conf{dbpasswd},
  {
    CHARSET => $conf{dbcharset}
  }
);

my $Admins = Admins->new( $db, \%conf );
my $Users = Users->new( $db, $Admins, \%conf );

# This can be never defined, but should be global
my $Voip = undef;

my $json = JSON->new->utf8;

# Connection handles_store
my %aid_client_ids = ();
my %aid_client_id_index = ();
my %client_id_aid = ();
my %client_handles = ();

my %calls_statuses = ();

# Cache
my %admin_by_number = ();
my %admin_by_sid = ();

#Delimiters
my $EOL = "\015\012";
my $EOR = $EOL;

# Global object for building frames
my $main_frame = Protocol::WebSocket::Frame->new;

# All handlers are destroyed with scope
# So this should be global
my $astman_guard = undef;
my $guard_timer = undef;

my $log_user = ' WebSocket ';
my $default_log_file = '/tmp/abills_websocket.log';
my $ARGS = parse_arguments( \@ARGV );

# Setting up Log and debug level
my $debug = $ARGS->{DEBUG} || 0;
my $Log = Log->new( $db, \%conf, { DEBUG_LEVEL => $debug } );
$Log->{LOG_FILE} = $ARGS->{LOG_FILE} || $default_log_file;

#Starting
if ( defined( $ARGS->{'-d'} ) ) {
  print "Daemonizing \n";
  my $pid_file = daemonize();
  # ведение лога
  $Log->log_print( 'LOG_INFO', $log_user, "Websocket Daemonize... $pid_file" );
}

# Stoppping
elsif ( defined( $ARGS->{stop} ) ) {
  print "Stopping \n";
  stop_server();
  exit;
}

# Checking if already started
elsif ( make_pid() == 1 ) {
  exit;
}

# Start servers
if ( $conf{EVENTS_ASTERISK} ) {
  require Voip;
  Voip->import();
  $Voip = Voip->new( $db, $Admins, \%conf );

  $astman_guard = connect_to_asterisk();
}

# Starting websocket server
$Log->log_print( 'LOG_INFO', $log_user, "Starting WebSocket server" );
AnyEvent::Socket::tcp_server 0, 19443, \&new_websocket_client;

# Starting websocket server
$Log->log_print( 'LOG_INFO', $log_user, "Starting internal commands server" );
AnyEvent::Socket::tcp_server '127.0.0.1', 19444, \&new_internal_client;

#Start our server
$Log->log_print( 'LOG_INFO', $log_user, "Waiting for events" );
AnyEvent::Impl::Perl::loop;

#**********************************************************
=head2 new_websocket_server()

=cut
#**********************************************************
sub new_websocket_client {
  my ($socket_pipe_handle, $host, $port) = @_;

  my $client_id = "$host:$port";
  $Log->log_print( 'LOG_DEBUG', $log_user, "Client connection : $client_id" );

  my $handshake = Protocol::WebSocket::Handshake::Server->new;

  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1
  );

  # On message
  $handle->on_read(
    sub {
      my $this_client_handle = shift;

      my $chunk = $this_client_handle->{rbuf};
      $this_client_handle->{rbuf} = undef;

      # If it is handshake, do all protocol related stuff
      if ( !$handshake->is_done ) {
        do_handshake( $this_client_handle, $chunk, $handshake );
        if ( my $aid = authenticate( $chunk ) ) {
          if ($aid == -1) {
            drop_client($client_id, 'Unauthorized') ;
          }
          else {
            save_aid_handle( $this_client_handle, $client_id, $aid );
            $Log->log_print( 'LOG_INFO', $log_user, "$client_id . Total : " . ( scalar keys %client_handles ) . " connections" );
          }
        }
        return;
      }
      else {
        on_websocket_message( $this_client_handle, $client_id, $chunk );
      }
    }
  );

  $handle->on_error(
    sub {
      my $read_handle = shift;
      #TODO: TODO: remove aid handle from connections hash
      $Log->log_print( 'LOG_CRIT', $log_user, "Error happened with $client_id " );
      $read_handle->push_shutdown;
      $Log->log_print( 'LOG_CRIT', " Removing : " . remove_client( $client_id ) );
      undef $handle;
    }
  )
};

#**********************************************************
=head2 new_internal_client()

=cut
#**********************************************************
sub new_internal_client {
  my ($socket_pipe_handle, $host, $port) = @_;

  my $client_id = "$host:$port";
  $Log->log_print( 'LOG_DEBUG', $log_user, "Internal connection : $client_id" );

  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1
  );

  # On message
  $handle->on_read(
    sub {
      my $this_client_handle = shift;

      my $chunk = $this_client_handle->{rbuf};
      $this_client_handle->{rbuf} = undef;

      my $parsed_chunk = parse_message( $chunk );

      #TODO: error codes

      unless ( $parsed_chunk->{TYPE} ) {
        $this_client_handle->push_write( '{"TYPE":"ERROR", "ERROR":"INCORRECT REQUEST"}' );
        return;
      }

      if ( $parsed_chunk->{TYPE} eq 'PING' ) {
        $this_client_handle->push_write( '{"TYPE":"PONG"}' )
      }
      elsif ( $parsed_chunk->{TYPE} eq 'MESSAGE' ) {
        $this_client_handle->push_write( process_internal_message( $parsed_chunk ));
      }
      elsif ( $parsed_chunk->{TYPE} eq 'REQUEST_LIST' ) {
        $this_client_handle->push_write( process_list_request( $parsed_chunk ));
      }
      else {
        $this_client_handle->push_write( '{"TYPE":"ERROR", "ERROR":"UNKNOWN MESSAGE TYPE"}' )
      }
      
      $this_client_handle->push_write("\n");
    }
  );

  $handle->on_eof(
    sub {
      my $this_client_handle = shift;
      $this_client_handle->push_shutdown;
      $this_client_handle = undef;
    }
  );

  $handle->on_error(
    sub {
      my $read_handle = shift;
      $Log->log_print( 'LOG_CRIT', $log_user, "Error happened with internal $client_id " );
      $read_handle->push_shutdown;
      undef $handle;
    }
  )
}

#**********************************************************
=head2 on_websocket_message($read_handle)

=cut
#**********************************************************
sub on_websocket_message {
  my ( $this_client_handle, $client_id, $chunk) = @_;

  my $frame = Protocol::WebSocket::Frame->new;

  $frame->append( $chunk );

  while (my $message = $frame->next) {

    if ( !exists $client_handles{$client_id} ) {
      $Log->log_print( 'LOG_NOTICE', $log_user, "Dropping unregistered client $client_id" );
      my $dropped = drop_client( $client_id, 'Unathorized' );
      $Log->log_print ( 'LOG_ERR', $log_user, "Error dropping $client_id" ) if (!$dropped);
    }

    print Encode::encode_utf8($message);
    print ' \n';

    # Client breaks connection
    if ( $message eq "\x{3}\x{fffd}" ) {
      $Log->log_print( 'LOG_NOTICE', $log_user, "Client $client_id breaks connection" );
      $this_client_handle->destroy;
      $this_client_handle = undef;
      drop_client( $client_id, "Client $client_id breaks connection" );
      next;
    };

    my $decoded_message = parse_message( $message );

    if ( defined $decoded_message && $decoded_message->{TYPE} ) {

      if ( $decoded_message->{TYPE} eq 'CLOSE_REQUEST' ) {
        drop_client( $client_id, 'by client request' );
      }
      elsif ( $decoded_message->{TYPE} eq 'PONG' ) {
        # Do nothing TODO: Treat as alive
        return;
      }
      elsif ( $decoded_message->{TYPE} eq 'RESPONCE' ) {
        # Do nothing TODO: Treat as alive
        return;
      }
      else {
        my %response = (DATA => $decoded_message);
        my $response_text = $json->encode( process_message( \%response ) );
        $this_client_handle->push_write( $frame->new( $response_text )->to_bytes );
      }
    }
  }

}


#**********************************************************
=head2 authenticate($read_handle, $chunk, $host, $port)

  Authentificate admin by cookies

=cut
#**********************************************************
sub authenticate {
  my ($chunk) = @_;

  if ( $chunk && $chunk =~ /^Cookie: .*$/m ) {

    my (@sids) = $chunk =~ /sid=([a-zA-Z0-9]*)/gim;

    return -1 unless (scalar @sids);

    my $aid = 0;
    foreach my $sid ( @sids ) {
      $Log->log_print( 'LOG_DEBUG', $log_user, "Will try to authentificate admin with sid $sid" );

      # Try to retrieve from cache
      $aid = $admin_by_sid{$sid};

      # If not found, look in DB
      if ( $aid ) {
        return $aid;
      }
      else {
        my $admin_with_this_sid = $Admins->online_info( { SID => $sid, COLS_NAME => 1 } );
        if ( $Admins->{TOTAL} ) {
          $aid = $admin_with_this_sid->{AID};
          $admin_by_sid{$sid} = $aid;
          return $aid;
        }
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 do_handshake()

=cut
#**********************************************************
sub do_handshake {
  my ($this_client_handle, $chunk, $handshake) = @_;

  $handshake->parse( $chunk );

  if ( $handshake->is_done ) {
    $this_client_handle->push_write( $handshake->to_string );
    return 1;
  }

  return 0;
}

#**********************************************************
=head2 parse_message($message)

  Safe JSON parsing

=cut
#**********************************************************
sub parse_message {
  my ($message) = @_;

  my $parsed_message = undef;
  eval { $parsed_message = $json->decode( $message ) };
  if ( $@ ) {
    $Log->log_print( 'LOG_EMERG', $log_user, "Failed to parse message : " . $message );
    $parsed_message = { DATA => $message };
  }

  return $parsed_message;
}


#**********************************************************
=head2 save_aid_handle()

=cut
#**********************************************************
sub save_aid_handle {
  my ($handle, $client_id, $aid) = @_;

  $client_handles{$client_id} = $handle;
  $client_id_aid{$client_id} = $aid;

  if (exists $aid_client_ids{$aid}){
    my $last = $aid_client_ids{$aid}{last}++;
    $aid_client_ids{$aid}{$last} = $client_id;

    #Saving reverse client_id -> index
    $aid_client_id_index{$aid}{$client_id} = $last;
  }
  else {
    $aid_client_ids{$aid} = { 0 => $client_id, last => 0 };

    #Saving reverse client_id -> index
    $aid_client_id_index{$aid}{$client_id} = 0;
  }


  return 1;
}

#**********************************************************
=head2 get_aid_handles() - Returns all open handles for admin

  Arguments :
    $aid - administrator aid to get handles for

  Returns :
    arr_ref - all opened handles
    array   - same if called in list context

=cut
#**********************************************************
sub get_aid_handles {
  my ($aid) = @_;
  
  if ($aid eq '*'){
    return get_aids_handles([ sort keys %aid_client_ids ]);
  }
  
  my @indexes = sort keys %{$aid_client_ids{$aid}};
  
  # delete 'last'
  pop @indexes;

  my @handles = map { $client_handles{$aid_client_ids{$aid}{$_}} } @indexes;

  return wantarray ? @handles : \@handles;
}

#**********************************************************
=head2 get_aids_handles() - Returns all open handles for aids

  Arguments :
    $aids - administrator aids to get handles for

  Returns :
    arr_ref - all opened handles
    array   - same if called in list context

=cut
#**********************************************************
sub get_aids_handles {
  my ($aids) = @_;

  my @handles = map { get_aid_handles( $_ ) }  @{$aids};

  return wantarray ? @handles : \@handles;
}


#**********************************************************
=head2 drop_client($client_id, $reason)

  Tell client we want to end session before finishing

=cut
#**********************************************************
sub drop_client {
  my ($client_id, $reason) = @_;
  my $handle = $client_handles{$client_id};
  $reason ||= "unknown";

  if ( defined $handle ) {
    $handle->push_write( $main_frame->new( '{"TYPE" : "close", "REASON" : "' . $reason . '"}' )->to_bytes );
    $handle->push_write( $main_frame->new( type => 'close' )->to_bytes );
    $handle->push_shutdown;
  }

  if ( exists ( $client_handles{$client_id} ) ) {
    remove_client( $client_id )
  }

  return 1;
}

#**********************************************************
=head2 remove_client($client_id)

  Destroy and remove known client

=cut
#**********************************************************
sub remove_client {
  my ($client_id) = @_;
  $Log->log_print( 'LOG_CRIT', $log_user, "Remove $client_id " );

  my $aid = $client_id_aid{$client_id};

  if (exists $aid_client_ids{$aid}){
    my $this_client_id_handle_aid_index = $aid_client_id_index{$aid}{$client_id};
    delete $aid_client_ids{$aid}{$this_client_id_handle_aid_index};
    delete $aid_client_id_index{$aid}{$client_id};
    delete $client_id_aid{$client_id};
  }

  if ( $client_handles{$client_id} ) {
    $client_handles{$client_id}->destroy;
    delete $client_handles{$client_id};
    return 1;
  }

  undef $client_handles{$client_id};
  return 0;
}

#**********************************************************
=head2 process_message($message)

  Separate function for parsing message

=cut
#**********************************************************
sub process_message {
  my ($message) = @_;

  # Simple echo


  return $message->{DATA};
}

#**********************************************************
=head2 process_internal_message() - proxy request

=cut
#**********************************************************
sub process_internal_message {
  my ($message) = @_;

  my $responce = '';

  # Check who is reciever
  if ( $message->{TO} eq 'ADMIN' ) {
    # Need to know what we are sending;
    my $decoded_message = parse_message( $message->{DATA} );

    $responce = notify_admin( $message->{ID}, $message->{DATA}, { TYPE => $decoded_message->{TYPE} } );
    
    if ($decoded_message->{SILENT}){
      $Log->log_print('LOG_DEBUG', ' Internal ', 'Silent message');
      return "\n";
    }
  }
  elsif ( $message->{TO} eq 'CLIENT' ) {
    #TODO: client connections
    $responce = '{"TYPE":"ERROR", "ERROR":"NOT IMPLEMENTED"}';
  }

  return $responce;
};

#**********************************************************
=head2 process_list_request()

=cut
#**********************************************************
sub process_list_request {
  my ($message) = @_;

  my $list_type = $message->{LIST_TYPE};

  my @result_list = ();

  return q{{"TYPE":"ERROR", "ERROR":"UNDEFINED 'LIST_TYPE'"}} unless ($list_type);

  if ( $list_type eq 'ADMINS' ) {
    @result_list = keys %aid_client_ids;
  }

  my %responce = (
    TYPE => "RESULT",
    LIST => \@result_list
  );

  return $json->encode( \%responce );
}

#**********************************************************
=head2 connect_to_asterisk()

  Setting up Asterisk connection. Will die on error.
  All events will be passed to process_asterisk_event()

=cut
#**********************************************************
sub connect_to_asterisk {
  eval { require Asterisk::AMI };
  if ( $@ ) {
    $Log->log_print( 'LOG_CRIT', $log_user, "Can't load Asterisk::AMI perl module" );
    die "Can't load Asterisk::AMI perl module";
  }
  Asterisk::AMI->import();

  $Log->log_print( 'LOG_INFO', $log_user, "Connecting to asterisk " );

  my $connection_tries = 0;

  my $try_to_connect_again_in = sub {
    my $seconds = shift;

    $Log->log_print( 'LOG_NOTICE', $log_user,
      "Set timer in $seconds seconds to reestablish connection to Asterisk " );

    $guard_timer = AnyEvent->timer(
      after => $seconds,
      cb    => sub {
        $Log->log_print( 'LOG_NOTICE', $log_user, "Trying to connect again " );
        $connection_tries++;
        $astman_guard = connect_to_asterisk();
      }
    );

  };

  return Asterisk::AMI->new(
    PeerAddr   => $conf{ASTERISK_AMI_IP},
    PeerPort   => $conf{ASTERISK_AMI_PORT},
    Username   => $conf{ASTERISK_AMI_USERNAME},
    Secret     => $conf{ASTERISK_AMI_SECRET},
    Events     => 'on', # Give us something to proxy
    Timeout    => 0, # TODO: non-blocking DBI, to avoid timeouts
    #    UseSSL     => 1,
    Handlers   => { Newchannel => \&process_asterisk_event,
                    Hangup     => \&process_asterisk_softhangup,
                    Newstate   => \&process_asterisk_newstate }, # Install handler for new calls
    Keepalive  => 3, # Send a keepalive every 3 seconds
    on_connect => sub {
      $Log->log_print( 'LOG_INFO', $log_user, "Connected to Asterisk::AMI " );
      $connection_tries = 0;
    },
    on_error   => sub {
      $Log->log_print( 'LOG_CRIT', $log_user, "Error occured on Asterisk::AMI socket : $_[1]" );;
      if ( $connection_tries < 10 ) {
        &{$try_to_connect_again_in}( 3 );
      }
      else {
        die "Unable to connect to Asterisk ";
      }
    },
    on_timeout => sub {
      $Log->log_print( 'LOG_CRIT', $log_user, "Connection to Asterisk timed out" );
      if ( $connection_tries < 10 ) {
        &{$try_to_connect_again_in}( 1 );
      }
      else {
        die "Unable to connect to Asterisk ";
      }
    }
  );
}

#**********************************************************
=head2 get_admin_by_sip_number()

=cut
#**********************************************************
sub get_admin_by_sip_number {
  my ($sip_number) = @_;

  # Retrieve from cache if possible
  if ( exists $admin_by_number{$sip_number} ) {
    return $admin_by_number{$sip_number};
  }

  my $admins_for_number_list = $Admins->list( { SIP_NUMBER => $sip_number, AID => '_SHOW', COLS_NAME => 1 } );
  if ( $admins_for_number_list && ref $admins_for_number_list eq 'ARRAY' && scalar @{$admins_for_number_list} > 0 ) {
    # Get first matched administrator aid
    my $aid = $admins_for_number_list->[0]->{aid};

    # Save to cache
    $admin_by_number{$sip_number} = $aid;

    return $aid;
  }
  else {
    # Return undef
    return;
  }
}

#**********************************************************
=head2 process_asterisk_event($asterisk, $event)

  Default handler for asterisk AMI events

=cut
#**********************************************************
sub process_asterisk_event {
  my ($asterisk, $event) = @_;

  if ( $event->{Event} && $event->{Event} eq 'Newchannel' ) {

    my $called_number = $event->{Exten};
    my $caller_number = $event->{CallerIDNum};

    # CALLCENTER CODE
    if(in_array('Callcenter', \@MODULES)){
      if($event->{CallerIDNum} ne '' && $event->{Exten} ne ''){
        use Callcenter;
        my $Callcenter = Callcenter->new($db, $Admins, \%conf);
          
        my ($call_id, undef) = split('\.', $event->{Uniqueid});
        
        my $user = $Users->list({ UID       => '_SHOW',
                                  PHONE     => $caller_number,
                                  COLS_NAME => 1 });
        my $uid;
        if ( $user && ref $user eq 'ARRAY' && scalar @{$user} > 0 ) {
          $uid = $user->[0]->{uid};
        }
        
        $Callcenter->callcenter_add_cals({
          USER_PHONE     => $caller_number,
          OPERATOR_PHONE => $called_number,
          ID             => $call_id,
          UID            => $uid || 0,
          STATUS         => 1,
        });
        
        if(!$Callcenter->{errno}){
          $Log->log_print('LOG_INFO', $log_user, "New call added. ID: $call_id");
        }
        else{
         $Log->log_print('LOG_INFO', $log_user, "Can't add new call"); 
        }
      }
    }

    $Log->log_print( 'LOG_INFO', $log_user, "Got Newchannel event. $caller_number calling to $called_number " );

    my $aid = get_admin_by_sip_number( $called_number );

    if (!$aid){
      $Log->log_print('LOG_NOTICE', $log_user, "Not admin number");
    }
    elsif (!exists $aid_client_ids{$aid}){
      $Log->log_print('LOG_NOTICE', $log_user, "Can't notify $aid, no connection");
      return 1;
    };

    my $search_list = $Voip->user_list( { NUMBER => $caller_number, UID => '_SHOW', COLS_NAME => 1 } );
    if ( !($search_list && ref $search_list eq 'ARRAY' && scalar @{$search_list} > 0) ) {
      # That's not an ABillS registered number
      $Log->log_print('LOG_INFO', $log_user, "That's not an ABillS registered number");
      return 1;
    }

    my $user_id = $search_list->[0]->{uid};
    my $user_info = $Users->info( $user_id );
    my $user_pi = $Users->pi( { UID => $user_id, LOCATION_ID => '_SHOW' } );

    my $notification = create_notification( { %{$user_info}, %{$user_pi} } );

    notify_admin( $aid, $notification );
  }

  return 1;
}

#**********************************************************
=head2 process_asterisk_newstate() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_asterisk_newstate {
  my ($asterisk, $event) = @_;
  
  if($event->{ChannelStateDesc} eq 'Up' && $event->{ConnectedLineNum} ne ''){
      
    my ($call_id, undef) = split('\.', $event->{Uniqueid});

    use Callcenter;
    my $Callcenter = Callcenter->new($db, $Admins, \%conf);

    $Callcenter->callcenter_change_calls({ STATUS  => 2,
                                           ID      => $call_id });
    if(!$Callcenter->{errno}){
      $calls_statuses{$call_id} = 2;
      $Log->log_print('LOG_INFO', $log_user, "Call in process. ID: $call_id");
    }
    else{
      $Log->log_print('LOG_INFO', $log_user, "Can't change status call"); 
    }
  }

  return 1;
}


#**********************************************************
=head2 process_asterisk_softhangup () -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_asterisk_softhangup {
  my ($asterisk, $event) = @_;

  if($event->{ConnectedLineNum} =~ /\d+/){
    use Callcenter;
    my $Callcenter = Callcenter->new($db, $Admins, \%conf);
  
    my ($call_id, undef) = split('\.', $event->{Uniqueid});
      
    if(defined $calls_statuses{$call_id} && $calls_statuses{$call_id} == 2){
      $Callcenter->callcenter_change_calls({ STATUS => 3,
                                             ID     => $call_id });
  
      delete $calls_statuses{$call_id};
      $Log->log_print('LOG_INFO', $log_user, "Call processed. ID: $call_id");
    }
    else{
      $Callcenter->callcenter_change_calls({ STATUS => 4,
                                             ID     => $call_id });
      $Log->log_print('LOG_INFO', $log_user, "Call not proceessed. ID: $call_id");
    }
  }
  return 1
}


#**********************************************************
=head2 create_notification($user_info)

  Create JSON message from %user_info

=cut
#**********************************************************
sub create_notification {
  my ($user_info) = @_;

  my $title = $user_info->{FIO} . ' ( '
    . (($user_info->{COMPANY_NAME}) ? $user_info->{COMPANY_NAME} . ' : ' . $user_info->{LOGIN}
                                    : $user_info->{LOGIN})
    . ' )';

  #TODO: localization
  my $text = 'Deposit : ' . $user_info->{DEPOSIT} . '<br/>' . $user_info->{ADDRESS_FULL};

  #  my %message = (
  #    TYPE   => 'MESSAGE',
  #    TITLE  => $title,
  #    TEXT   => $text,
  #    CLIENT => { UID => $user_info->{UID}, LOGIN => $user_info->{LOGIN} }
  #  );
  #  return JSON->new->utf8->encode( \%message );

  my $result = << "MESSAGE";
{
  "TYPE"   : "MESSAGE",
  "TITLE"  : "$title",
  "TEXT"   : "$text",
  "CLIENT" : { "UID" : "$user_info->{UID}", "LOGIN" : "$user_info->{LOGIN}"}
}
MESSAGE

  return $result;
}

#**********************************************************
=head2 notify_admin($aid, $notification, $attr) - sends notification to all admin handles

  Notify all sockets for this admin

=cut
#**********************************************************
sub notify_admin {
  my ($aid, $notification, $attr) = @_;

  # TODO: return error
  my @admin_opened_sockets = get_aid_handles( $aid );

  unless ( scalar @admin_opened_sockets ) {
    $Log->log_print( 'LOG_ERR', $log_user, 'No opened sockets for ' . $aid );
    return undef;
  }
  $Log->log_print( 'LOG_INFO', $log_user, "Notifying admin $aid . Opened sockets:" . scalar @admin_opened_sockets );

  if ( $attr && $attr->{TYPE} && $attr->{TYPE} eq 'PING' ) {
    $Log->log_print( 'LOG_INFO', $log_user, "Ping admin $aid " );
    # Take first socket and return responce
    return send_notification( $admin_opened_sockets[0], { MESSAGE => $notification } );
  }

  my @responces = ();
  my %notified_handlles = ();
  foreach my $handle ( @admin_opened_sockets ) {
    # Skip sending to same handle
    next if (exists $notified_handlles{$handle});
    $notified_handlles{$handle} = 1;
    
    my $responce = send_notification( $handle, { MESSAGE => $notification } );
    push ( @responces, $responce );
  }

  if ( scalar @responces > 0 ) {
    my %admin_answer = (
      TYPE   => 'RESULT',
      AID    => $aid,
      RESULT => \@responces
    );

    return $json->encode( \%admin_answer );
  }

  return 1;
}

#**********************************************************
=head2 send_notification() - sends single notification to handle

=cut
#**********************************************************
sub send_notification {
  my ($handle, $attr) = @_;

  unless ( defined $handle ) {
    $Log->log_print( 'LOG_ERR', $log_user, "Trying to write to undefined handle" );
    return -1;
  }
  my $result = '';

  my $operation_end_waiter = AnyEvent->condvar;

  # Set timeout to 5 seconds
  my $timeout_waiter = AnyEvent->timer(
    after => 0.2,
    cb    => sub {
      $Log->log_print( 'LOG_NOTICE', $log_user, "Timeout" );
      $result = undef;
      my %client_ids = reverse(%client_handles);
      drop_client($client_ids{$handle}, 'Timeout');
      $operation_end_waiter->send;
    }
  );

  my $message = $attr->{MESSAGE};

  # Setup recieve callback
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;

      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;

      my $frame = Protocol::WebSocket::Frame->new;
      $frame->append( $readed );

      my $responce = '';
      while (my $client_answer = $frame->next) {
        $responce .= $client_answer;
      }
      $operation_end_waiter->send( $responce );
    }
  );

  $handle->push_write( $main_frame->new( $message )->to_bytes );

  $result = $operation_end_waiter->recv;

  return $result;
}

END {
  # Tell all clients we want to poweroff
  foreach my $client_id ( keys %client_handles ) {
    $Log->log_print( 'LOG_EMERG', $log_user, "Sending 'Goodbye' to $client_id " );
    drop_client( $client_id, 'Websocket server crashed or restarts' );
  }
}