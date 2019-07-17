# Billd plugin for autoclose old messages


use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $users,
  $var_dir,
  $argv,
);

use Abills::Base qw/_bp sendmail/;
use Msgs;
use Abills::Templates qw/templates/;
our $html = Abills::HTML->new( { CONF => \%conf } );

my $date = $argv->{DATE} || $DATE;

my $Msgs = Msgs->new($db, $Admin, \%conf);
my $Log  = Log->new($db, $Admin);
$Log->{LOG_FILE} = $var_dir.'/log/msgs_autoclose.log';

$Msgs->chapters_list({ LIST2HASH => 'id,autoclose' });

my $autoclose_list = $Msgs->{list_hash};

my $messages_list = $Msgs->messages_list({
  LAST_REPLIE_DATE => '_SHOW',
  STATE            => 6,
  EMAIL            => '_SHOW',

  COLS_NAME        => 1,
});

foreach my $message (@$messages_list) {
  next if (!$message->{last_replie_date} || $message->{last_replie_date} eq '0000-00-00 00:00:00');
  next if (!$autoclose_list->{$message->{chapter_id}} );
  my ($last_action, undef) = split(/ /, $message->{last_replie_date}, 2);
  
  if (_period_days($last_action, $date) == $autoclose_list->{$message->{chapter_id}} - 2) {
    $Log->log_print('LOG_INFO', '', "Alert for message $message->{id}");
    my $message_body = $html->tpl_show(templates('form_msgs_autoclose'), { MSGS_ID => $message->{id} } , {
        OUTPUT2RETURN      => 1, 
        SKIP_DEBUG_MARKERS => 1
    });
    my $email = $message->{email};
    sendmail("$conf{ADMIN_MAIL}", "$email", "You did not respond for a long time", "$message_body", "$conf{MAIL_CHARSET}", "");
    $Log->log_print('LOG_INFO', '', "Sendmail to UID:'$message->{uid}' about message $message->{id}");
  }
  elsif (_period_days($last_action, $date) >= $autoclose_list->{$message->{chapter_id}}) {
    $Log->log_print('LOG_INFO', '', "Autoclose message $message->{id}");
    my $message_body = $html->tpl_show(templates('form_msgs_autoclose2'), { MSGS_ID => $message->{id} } , {
        OUTPUT2RETURN      => 1, 
        SKIP_DEBUG_MARKERS => 1
    });
    $Msgs->message_reply_add({
      ID         => $message->{id},
      REPLY_TEXT => $message_body,
      STATE      => 2,
      UID        => $message->{uid},
      AID        => 2,
    });
    $Msgs->message_change({
      ID    => $message->{id},
      STATE => 2,
    });
  }
}


sub _period_days {
  my ($s_date, $e_date) = @_;
  return 0 if ($s_date gt $e_date);
  my ($s_year, $s_month, $s_day) = split '-', $s_date;
  my ($e_year, $e_month, $e_day) = split '-', $e_date;
  my @lastday = (31,28,31,30,31,30,31,31,30,31,30,31);
  
  $lastday[1] = ($e_year % 4) ? 28 : 29;
  
  while ($e_year > $s_year || $e_month > $s_month ) {
    $e_month--;
    if ($e_month == 0) {
      $e_year--;
      $e_month = 12;
      $lastday[1] = ($e_year % 4) ? 28 : 29;
    }
    $e_day += $lastday[$e_month-1]
  }

  return $e_day - $s_day;
}
1