package Abills::Sender::Telegram;
use strict;
use warnings;

use parent 'Abills::Sender::Plugin';
use Abills::Base qw(_bp);

our $VERSION = 0.02;

use Abills::Backend::Plugin::Telegram::BotAPI;
use Abills::Fetcher;

my %conf = ();

my $api_url = 'api.telegram.org';

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Telegram object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Telegram = Abills::Sender::Telegram->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_ or return 0;
  
  %conf = %{$conf};
  
  my $self = {
    token   => $conf{TELEGRAM_TOKEN},
    name    => $conf{TELEGRAM_BOT_NAME},
    api_url => $api_url
  };
  
  $self->{api} = Abills::Backend::Plugin::Telegram::BotAPI->new(\%conf, {
      token   => $conf{TELEGRAM_TOKEN},
      debug   => $conf{TELEGRAM_API_DEBUG},
      api_url => $api_url
    });
  
  die 'No Telegram token ($conf{TELEGRAM_TOKEN})' if ( !$self->{token} );
  
  bless $self, $class;
  
  return $self;
}


#**********************************************************
=head2 send_message() - Send message to user with his chat_id or to channel with username(@<CHANNELNAME>)

  Arguments:
    $attr:
      TO_ADDRESS - Telegram ID
      MESSAGE    - text of the message
      PARSE_MODE - parse mode of the message. u can use 'markdown' or 'html' 
      DEBUG      - debug mode
  
  Returns:

  Examples:
    $Telegram->send_message({
      AID        => "235570079",
      MESSAGE    => "testing",
      PARSE_MODE => 'markdown',
      DEBUG      => 1
    });

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr, $callback) = @_;
  
  my $text = $attr->{MESSAGE} || return 0;
  
  if ( $attr->{PARSE_MODE} ) {
    $attr->{TELEGRAM_ATTR} = {} if ( !$attr->{TELEGRAM_ATTR} );
    $attr->{TELEGRAM_ATTR}->{parse_mode} = $attr->{PARSE_MODE}
  }
  
  if ( $attr->{SUBJECT} ) {
    $text = $attr->{SUBJECT} . "\n\n" . $text;
  }
  
  if ($attr->{DEBUG}){
    $self->{api}{debug} = $attr->{DEBUG};
  }
  
  my $result = $self->{api}->sendMessage({
      chat_id => $attr->{TO_ADDRESS},
      text    => $text,
      %{ $attr->{TELEGRAM_ATTR} // {} }
    }, $callback);
  
  if ( $attr->{DEBUG} && $attr->{DEBUG} > 1 ) {
    _bp("Result", $result, { TO_CONSOLE => 1 });
  }
  
  if ( $attr->{RETURN_RESULT} ) {
    return $result;
  }
  
  return $result && $result->{ok} eq '1';
}

#**********************************************************
=head2 get_updates() -

  Arguments:
    $attr:
      OFFSET - Identifier of the first update to be returned.
               Must be greater by one than the highest among
               the identifiers of previously received updates.
      DEBUG  - debug mode
      
  Returns:
    array_ref of updates or 0
    
  Examples:
    $result = $Telegram->get_updates( { OFFSET => $updateid + 1, DEBUG => 1 } )->{result};

=cut
#**********************************************************
sub get_updates {
  my $self = shift;
  my ($attr) = @_;
  
  my Abills::Backend::Plugin::Telegram::BotAPI $api = $self->{api};
  
  return $api->getUpdates({ offset => $attr->{OFFSET} || 0 });
}

#**********************************************************
=head2 get_bot_name() - returns this bot name

  Returns:
    string - bot name
    
=cut
#**********************************************************
sub get_bot_name {
  my ( $self, $conf, $db ) = @_;
  
  $self->{name} //= $conf->{TELEGRAM_BOT_NAME} // $conf->{TELEGRAM_BOT_NAME_AUTO};
  
  if ( !$self->{name} || ($conf->{TELEGRAM_BOT_NAME_AUTO} && $conf->{TELEGRAM_BOT_NAME_AUTO} ne $self->{name}) ) {
    my $bot_url = 'https://' . $self->{api_url} . "/bot$self->{token}/getMe";
    
    my $result = web_request($bot_url, {
        CURL        => 1,
        JSON_RETURN => 1
      });
    
    if ( $result && ref $result eq 'HASH' && $result->{ok} && $result->{result}->{username} ) {
      $self->{name} = $result->{result}->{username};
    }
    
    # Save to conf
    require Conf;
    Conf->import();
    
    require Admins;
    Admins->import();
    
    my $admin_ = Admins->new($db, $conf);
    $admin_->info($conf->{SYSTEM_ADMIN_ID} || 2);
    
    my $Conf = Conf->new($db, $admin_, $conf);
    $Conf->config_add({
      PARAM   => 'TELEGRAM_BOT_NAME_AUTO',
      VALUE   => $self->{name},
      REPLACE => 1,
    });
    
  }
  
  return $self->{name};
}

1;