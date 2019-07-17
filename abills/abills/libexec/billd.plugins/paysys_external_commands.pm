use Paysys;
use Conf;
use Time::Local;

use Data::Dumper;
my $version = 0.01;
my $Paysys = Paysys->new($db, $Admin, \%conf);
my $Config = Conf->new($db, $Admin, \%conf);

run_end_command();

#**********************************************************
=head2 test() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub run_end_command {
  my ($attr) = @_;

  my $start_command = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_START_COMMAND'}))->{VALUE};
  my $end_command   = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_END_COMMAND'}))->{VALUE};
  my $time          = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_TIME'}))->{VALUE};
  my $attempts      = ($Config->config_info({PARAM => 'PAYSYS_EXTERNAL_ATTEMPTS'}))->{VALUE};

  my $users_list = $Paysys->paysys_user_list({COLS_NAME => 1, CLOSED => 0});

  foreach my $user (@$users_list){
    my ($user_date, $user_time)     = split(' ', $user->{external_last_date});
    my ($user_year, $user_month, $user_day)        = split('-', $user_date);
    my ($user_hours, $user_minutes, $user_seconds) = split(':', $user_time);

    my $command_start_time = timelocal(int($user_seconds), int($user_minutes), int($user_hours), int($user_day), int($user_month - 1), int($user_year));
    my $command_end_time   = $command_start_time + ($time * 60);

    my ($year, $month, $day)        = split('-', $DATE);
    my ($hours, $minutes, $seconds) = split(':', $TIME);
    my $now_time = timelocal(int($seconds), int($minutes), int($hours), int($day), int($month - 1), int($year));

    if($command_end_time <= $now_time){
      # FIXME выборка ип с оплаты
      my $payments_list = $Paysys->list({ DESC => 'desc', 
                                          PAGE_ROWS => 1, SORT => 'datetime', 
                                          UID => $user->{uid}, 
                                          IP => '_SHOW', 
                                          COLS_NAME => 1});

      # _bp("list", $user, {TO_CONSOLE => 1});
      # _bp("list", $payments_list[0], {TO_CONSOLE => 1});

      cmd($end_command, {
        PARAMS => { IP => $user->{external_user_ip}, UID => $user->{uid} }
      });

      $Paysys->paysys_user_change({UID => $user->{uid}, PAYSYS_ID => $user->{paysys_id}, CLOSED => 1});
    }
  }

  return 1;
}
