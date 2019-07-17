package Abills::Sender::Telegram;
use strict;
use warnings;

use Abills::Fetcher;
use Abills::Base qw(_bp);
use JSON;
our $VERSION = 0.01;

#**********************************************************
=head2 new($attr) - Create new Telegram object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Telegram = Abills::Sender::Telegram->new( token => $conf{TELEGRAM_TOKEN} );

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = { conf => $attr->{CONF} };

  $self->{api_url} = "https://api.telegram.org/bot$self->{conf}->{TELEGRAM_TOKEN}/";

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
  my $self   = shift;
  my ($attr) = @_;

  #my $user       = $attr->{AID} ? $attr->{AID} : $attr->{UID};
  my $text       = $attr->{MESSAGE};
  my $parse_mode = $attr->{PARSE_MODE} || '';
  # $user = '@' . $user;

  my $result_json = web_request($self->{api_url} . "sendMessage",
    {
     REQUEST_PARAMS => { chat_id    => $attr->{TO_ADDRESS},
                         text       => $text,
                         parse_mode => $parse_mode
                       }
  });

  my $result = from_json($result_json);

  if($attr->{DEBUG} && $attr->{DEBUG} == 1){
    _bp("Result: ", $result, {TO_CONSOLE => 1});
  }
    
  return $result->{ok};
}

#**********************************************************
=head2 get_updates() -

  Arguments:
    $attr:
      OFFSET - Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates.
      DEUBG  - debug mode
  Returns:

  Examples:
    $result = $Telegram->get_updates( { OFFSET => $updateid + 1, DEBUG => 1 } )->{result};

=cut
#**********************************************************
sub get_updates {
  my $self   = shift;
  my ($attr) = @_;

  my $result_json = web_request("$self->{api_url}" . "getUpdates",
                                {REQUEST_PARAMS => {offset => $attr->{OFFSET}}
                              });

  my $result = from_json($result_json);

  if($attr->{DEBUG} && $attr->{DEBUG} == 1){
    _bp("Result: ", $result);
  }
    
  return $result;
}
  