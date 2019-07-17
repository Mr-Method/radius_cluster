package Abills::Backend::Plugin::Asterisk;
use strict;
use warnings FATAL => 'all';

use Abills::Backend::Plugin::BasePlugin;
use parent 'Abills::Backend::Plugin::BasePlugin';

use Abills::Base qw/in_array/;
use Encode;

#use Voip;
use Users;
use Callcenter;
use Admins;

#my $Voip;
my $Users;
my $Callcenter;
my $Admins;


# Used in local thread and can't be global
my ($admin, $db, %conf);

our (@MODULES);

use Abills::Backend::Log;
our Abills::Backend::Log $Log;
my $log_user = ' Asterisk ';

# DEBUGGING EVENTS ( Will be removed )
my $Event_log = Abills::Backend::Log->new('FILE', 7, 'Asterisk debug', {
    FILE => ('/usr/abills/var/log/event_asterisk.log'),
  });
# DEBUGGING EVENTS

use Abills::Backend::Defs;

use Abills::Backend::Plugin::Websocket::API;
my Abills::Backend::Plugin::Websocket::API $websocket_api = get_global('WEBSOCKET_API');

# Cache
my %calls_statuses = ();

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
sub new {
  my $class = shift;
  
  my ($CONF) = @_;
  
  %conf = %{$CONF};
  
  $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
      CHARSET => $conf{dbcharset},
      SCOPE   => 2
    });
  
  $admin = Admins->new($db, \%conf);
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };
  
  bless($self, $class);
  
#  $Voip = Voip->new($db, $admin, $CONF);
  $Users = Users->new($db, $admin, $CONF);
  $Callcenter = Callcenter->new($db, $admin, $CONF);
  $Admins = Admins->new($db, $CONF);
  
  return $self;
}

#**********************************************************
=head2 init() - inits Asterisk events listener
    
=cut
#**********************************************************
sub init {
  my $self = shift;
  
  $self->init_connection();
  
  return 1;
}

#**********************************************************
=head2 init_connection() - new thread for asterisk

  Setting up Asterisk connection. Will die on error.
  All events will be passed to process_asterisk_event()

=cut
#**********************************************************
sub init_connection {
  my $self = shift;
  
  eval {require Asterisk::AMI};
  if ( $@ ) {
    $Log->critical($log_user, "Can't load Asterisk::AMI perl module");
    die "Can't load Asterisk::AMI perl module";
  }
  
  Asterisk::AMI->import();
  
  $Log->info("Connecting to asterisk ");
  
  $self->connect_to_asterisk();
}

#**********************************************************
=head2 connect_to_asterisk() -

=cut
#**********************************************************
sub connect_to_asterisk {
  my $self = shift;
  
  $self->{connection_num} //= 0;
  
  delete $self->{astman_guard} if ( exists $self->{astman_guard} );
  
  $self->{astman_guard} = Asterisk::AMI->new(
    PeerAddr   => $conf{ASTERISK_AMI_IP},
    PeerPort   => $conf{ASTERISK_AMI_PORT},
    Username   => $conf{ASTERISK_AMI_USERNAME},
    Secret     => $conf{ASTERISK_AMI_SECRET},
    Events     => 'on', # Give us something to proxy
    Timeout    => 1,
    Blocking   => 0,
    Handlers   => { # Install handler for new calls
      Newchannel => \&process_asterisk_newchannel,
      Hangup     => \&process_asterisk_softhangup,
      Newstate   => \&process_asterisk_newstate,
      default    => \&process_default
    },
    Keepalive  => 3, # Send a keepalive every 3 seconds
    on_connect => sub {
      # Counter for connections
      $self->{connection_num}++;
      $Log->info("Connected to Asterisk::AMI (Connection #$self->{connection_num})");
      
      # Clear counter of unsuccessful tries
      $self->{connection_tries} = 0;
    },
    on_error   => sub {
      $Log->critical("Error occured on Asterisk::AMI socket : $_[1]");
      $self->reconnect_to_asterisk_in(3) or $self->exit_with_error("Unable to connect to Asterisk");
    },
    on_timeout => sub {
      $Log->critical("Connection $self->{connection_num} to Asterisk timed out");
      $self->reconnect_to_asterisk_in(1) or $self->exit_with_error("Unable to connect to Asterisk");
    }
  );
  
  return $self->{astman_guard};
}

#**********************************************************
=head2 reconnect_to_asterisk_in($seconds) - Controls number of tries to reconnect

  Arguments:
    $seconds - delay beetween next try
    
  Returns:
    1 if below connection tries treshold
    
=cut
#**********************************************************
sub reconnect_to_asterisk_in {
  my ($self, $seconds) = @_;
  
  $self->{connection_tries} //= 0;
  
  return 0 if ( $self->{connection_tries} >= 20 );
  
  $Log->notice("Set timer in $seconds seconds to reestablish connection to Asterisk ");
  
  # Create delayed action
  $self->{guard_timer} = AnyEvent->timer(
    after => $seconds,
    cb    => sub {
      $self->{connection_tries} = $self->{connection_tries} + 1;
      $Log->notice("Trying to connect again (Try #$self->{connection_tries})");
      $self->{astman_guard} = $self->connect_to_asterisk();
    }
  );
  
}

#**********************************************************
=head2 process_asterisk_newchannel($asterisk, $event)

  Default handler for asterisk AMI events

=cut
#**********************************************************
sub process_asterisk_newchannel {
  my ($asterisk, $event) = @_;

  if ( $event->{Event} && $event->{Event} eq 'Newchannel' ) {
    
    my $called_number = $event->{Exten};
    my $caller_number = $event->{CallerIDNum};

    return unless $caller_number && $called_number;
    
    # CALLCENTER CODE
    if ( in_array('Callcenter', \@MODULES) ) {
      if ( $event->{CallerIDNum} ne '' && $event->{Exten} ne '' ) {
        my ($call_id, undef) = split('\.', $event->{Uniqueid});
        
        my $newchannel_handler = sub {
          
          my $user = $Users->list(
            {
              UID       => '_SHOW',
              PHONE     => $caller_number,
              COLS_NAME => 1
            }
          );
          my $uid;
          if ( $user && ref $user eq 'ARRAY' && scalar @{$user} > 0 ) {
            $uid = $user->[0]->{uid};
          }
          
          $Callcenter->callcenter_add_cals(
            {
              USER_PHONE     => $caller_number,
              OPERATOR_PHONE => $called_number,
              ID             => $call_id,
              UID            => $uid || 0,
              STATUS         => 1,
            }
          );
          
          if ( !$Callcenter->{errno} ) {
            $Log->info("New call added. ID: $call_id");
            
          }
          else {
            $Log->info("Can't add new call");
          }
        };
        
        # check if its in IVR
        my $ivr_is_exist = 0;
        $asterisk->{guard_timer} = AnyEvent->timer(
          after => 1,
          cb    => sub {
            $Callcenter->log_list({ COLS_NAME => 1, UID => '_SHOW', UNIQUE_ID => $call_id });
            print "Total - $Callcenter->{TOTAL}\n";
            if ( !$Callcenter->{TOTAL} ) {
              $newchannel_handler->();
            }
            
          }
        );
        
        # $Callcenter->{debug}=1;
        
        # my $ivr_call_info = $Callcenter->log_list({COLS_NAME => 1, UID=> '_SHOW', UNIQUE_ID => $call_id});
        
        # use Abills::Base;
        # _bp("ivr", $ivr_call_info, {TO_CONSOLE=>1});
      }
    }
    
    $Log->info("Got Newchannel event. $caller_number calling to $called_number ");
    
    notify_admin_about_new_call($called_number, $caller_number);
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
  
  if ( $event->{ChannelStateDesc} eq 'Up' && $event->{ConnectedLineNum} ne '' ) {
    
    my ($call_id, undef) = split('\.', $event->{Uniqueid});
    $Callcenter->{debug} = 1;
    $Callcenter->callcenter_change_calls({
      STATUS => 2,
      ID     => $call_id
    });
    
    if ( !$Callcenter->{errno} ) {
      $calls_statuses{$call_id} = 2;
      $Log->info("Call in process. ID: $call_id");
    }
    else {
      $Log->info("Can't change status call");
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
  
  if ( $event->{ConnectedLineNum} =~ /\d+/ ) {
    
    my ($call_id, undef) = split('\.', $event->{Uniqueid});
    
    if ( defined $calls_statuses{$call_id} && $calls_statuses{$call_id} == 2 ) {
      $Callcenter->callcenter_change_calls({ STATUS => 3,
        ID                                          => $call_id });
      
      delete $calls_statuses{$call_id};
      $Log->info("Call processed. ID: $call_id");
    }
    else {
      $Callcenter->callcenter_change_calls({ STATUS => 4,
        ID                                          => $call_id });
      $Log->warning("Call not proceessed. ID: $call_id");
    }
  }
  return 1
}


#**********************************************************
=head2 get_admin_by_sip_number()

=cut
#**********************************************************
sub get_admin_by_sip_number {
  my ($sip_number) = @_;
  
  my $admins_for_number_list = $Admins->list({ SIP_NUMBER => $sip_number, AID => '_SHOW', COLS_NAME => 1 });
  if ( $admins_for_number_list && ref $admins_for_number_list eq 'ARRAY' && scalar @{$admins_for_number_list} > 0 ) {
    
    # Get first matched administrator aid
    my $aid = $admins_for_number_list->[0]->{aid};
    
    return $aid;
  }
  else {
    # Return undef
    return;
  }
}

#**********************************************************
=head2 notify_admin_about_new_call($call_info) - notifies admin in new thread

  Arguments:
    $called_number - call receiver
    $caller_numer  - call initiatior
    
  Returns:
    1
    
=cut
#**********************************************************
sub notify_admin_about_new_call {
  my ($called_number, $caller_number) = @_;
  
  my $aid = get_admin_by_sip_number($called_number);
  
  if ( !$aid ) {
    $Log->debug("Not admin number $called_number");
  }
  elsif ( !$websocket_api->has_connected('admin', $aid) ) {
    $Log->notice("Can't notify $aid, no connection");
    return 1;
  };

  if($conf{CALLCENTER_ASTERISK_PHONE_PREFIX}){
    $caller_number =~ s/$conf{CALLCENTER_ASTERISK_PHONE_PREFIX}//;
  }

  my $search_list = $Users->list({ PHONE => "*$caller_number",
    UID          => '_SHOW',
    FIO          => '_SHOW',
    DEPOSIT      => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    COMPANY_NAME => '_SHOW',
    COLS_UPPER   => 1,
    COLS_NAME    => 1 });

  if ( !($search_list && ref $search_list eq 'ARRAY' && scalar @{$search_list} > 0) ) {
    # That's not an ABillS registered number
    $Log->warning("That's not an ABillS registered number $caller_number");
    return 1;
  }

  foreach my $user_info (@$search_list){

    my $notification = _create_user_info_notification({ %{$user_info}, });

    $websocket_api->notify_admin($aid, $notification);
  }
  
  return 1;
}


#**********************************************************
=head2 exit_with_error($error) - notifies admins, writes to log and finishes thread

  Arguments:
    $error - text for message
    
  Returns:
    
    
=cut
#**********************************************************
sub exit_with_error {
  my ($self, $error) = @_;
  
  $websocket_api->notify_admin('*', {
      TITLE  => 'ASTERISK',
      TEXT   => $error || 'Unable connect to asterisk',
      MODULE => 'Callcenter'
    });
  
  $Log->critical("Unable to connect to Asterisk ");
  
  return 1;
}

#**********************************************************
=head2 _create_user_info_notification($user_info)

  Create JSON message from %user_info

=cut
#**********************************************************
sub _create_user_info_notification {
  my ($user_info) = @_;

  my $Internet = ();
  my $Sessions = ();
  my $tp_name  = '';
  if (in_array( 'Internet', \@MODULES )) {
    require Internet;
    require Internet::Sessions;
    $Internet = Internet->new($db, $admin, \%conf);
    $Sessions = Internet::Sessions->new($db, $admin, \%conf);

    my $user_session = $Sessions->list({
      UID        => $user_info->{UID},
      TP_NAME    => '_SHOW',
      SORT       => 2,
      DESC       => 'DESC',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      PAGE_ROWS  => 1});

    $tp_name = $user_session->[0]->{tp_name} || '';
  }

  my $title = ($user_info->{FIO} || '')
    . ' ( '
    . (($user_info->{COMPANY_NAME}) ? $user_info->{COMPANY_NAME} . ' : ' . $user_info->{LOGIN}
                                    : $user_info->{LOGIN})
    . ' )';
  
  #TODO: localization
  my $text = 'Deposit : ' . $user_info->{DEPOSIT} . '<br/>' . Encode::decode('utf8', ($user_info->{ADDRESS_FULL} || '')) . "<br/>" . $tp_name;
  
  my $result = {
    TITLE  => Encode::decode('utf8', $title),
    TEXT   => $text,
    EXTRA  => '?index=15&UID=' . $user_info->{UID},
    CLIENT => {
      UID   => $user_info->{UID},
      LOGIN => $user_info->{LOGIN}
    }
  };
  
  return $result;
}

#**********************************************************
=head2 process_default() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub process_default {
  my ($asterisk, $event) = @_;
  
  # Start debuging events, Will be removed
  my $debug_event = "\n================EVENT START=================\n";
  foreach my $key ( sort keys %{$event} ) {
    $debug_event .= ($key || '') . "-" . ($event->{$key} || '') . "\n";
  }
  $debug_event .= "================EVENT END=================\n";
  $Event_log->info("$debug_event");
  # End debuging events
  
  return 1;
}


1;