#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use Encode qw/encode_utf8/;
# use utf8;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../../',
    $Bin . '/../../lib/',
    $Bin . '/../../Abills/mysql',
    $Bin . '/../../Abills/modules/Telegram',
  );

}

use Abills::Base qw/_bp/;
use Abills::SQL;
use Admins;
use Users;
use Contacts;
use API::Botapi;
use Buttons;

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin   = Admins->new($db, \%conf);
my $Contacts = Contacts->new($db, $admin, \%conf);
my $Users    = Users->new($db, $admin, \%conf);

my $message = ();
my $debug = 0;

print "Content-type:text/html\n\n";
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
if (!$ENV{'REQUEST_METHOD'}) {
  $message->{text} = join(' ', @ARGV);
  $message->{chat}{id} = 403536999;
  $debug = 1;
}
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  `echo '$buffer' >> /tmp/telegram.log`;
  my $hash = from_json($buffer);
  exit 0 unless ($hash && ref($hash) eq 'HASH' && $hash->{message});
  $message = $hash->{message};
}
else {
  print "За вами уже выехали.";
  exit 0;
}

# _bp('message', $message, {TO_CONSOLE => 1}) if ($debug);

my $Bot = Botapi->new($conf{TELEGRAM_TOKEN}, $message->{chat}{id});
my %buttons_list = %{buttons_list({bot => $Bot})};
my %commands_list = reverse %buttons_list;
# _bp('buttons', \%commands_list, {TO_CONSOLE => 1}) if ($debug);

message_process();
exit 1;


#**********************************************************
=head2 message_process()
  
=cut
#**********************************************************
sub message_process {
  #Subscribe
  if ($message->{text} =~ m/^\/start/) {
    subscribe();
  }
  #Auth
  my $uid = get_uid();
  unless ($uid) {
    $Bot->send_message({
      text         => "Для подключения телеграм-бота нажмите на кнопку 'Подписаться' в кабинете пользователя.",
    });
    exit 0;
  }
  $Bot->{uid} = $uid;

  my $text = encode_utf8($message->{text});

  if ($message->{fn_data}) {
    #TODO
  }
  elsif ($commands_list{$text}) {
    telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      bot    => $Bot,
    });
  }
  else {
    main_menu(),
  }

  return 1;
}

#**********************************************************
=head2 subscribe()
  
=cut
#**********************************************************
sub subscribe {
  my ($type, $sid) = $message->{text} =~ m/^\/start ([ua])_([a-zA-Z0-9]+)/;

  if ($type && $sid && $type eq 'u') {
    my $uid = $Users->web_session_find($sid);
    if ($uid) {
      my $list = $Contacts->contacts_list({
        TYPE  => 6,
        VALUE => $message->{chat}{id},
      });
      
      if ( !$Contacts->{TOTAL} || scalar (@{$list}) == 0 ) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => 6,
          VALUE    => $message->{chat}{id},
          PRIORITY => 0,
        });
      }
    }
  }
  elsif ($type && $sid && $type eq 'a') {
    $admin->online_info({SID => $sid});
    my $aid = $admin->{AID};
    if ( $aid ) {
      my $list = $admin->admins_contacts_list({
        TYPE  => 6,
        VALUE => $message->{chat}{id},
      });
      
      if ( !$admin->{TOTAL} || scalar (@{$list}) == 0 ) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => 6,
          VALUE    => $message->{chat}{id},
          PRIORITY => 0,
        });
      }
    }
    exit 0;
  }
  else {
    $Bot->send_message({
      text         => "Для подключения телеграм-бота нажмите на кнопку 'Подписаться' в кабинете пользователя.",
    });
    exit 0;
  }

  return 1;
}

#**********************************************************
=head2 main_menu()
  
=cut
#**********************************************************
sub main_menu {
  my @line = ();
  my $i = 0;
    
  foreach my $button (sort keys %commands_list) {
    push (@{$line[$i%4]}, {text => $button});
    $i++;
  }

  my $keyboard = [$line[0] || [], $line[1] || [], $line[2] || [], $line[3] || []];

  $Bot->send_message({
    text         => "Жмите кнопки.",
    reply_markup => { 
      keyboard => $keyboard
    },
  });

  return 1;
}

#**********************************************************
=head2 get_uid($chat_id)
  
=cut
#**********************************************************
sub get_uid {
  my $chat_id = $message->{chat}{id};
  my $list = $Contacts->contacts_list({
    TYPE  => 6,
    VALUE => $message->{chat}{id},
    UID   => '_SHOW',
  });

  # _bp('contacts list by chat_id', $list, {TO_CONSOLE => 1}) if ($debug);

  return 0 if ($Contacts->{TOTAL} < 1);

  return $list->[0]->{uid};
}

1;
