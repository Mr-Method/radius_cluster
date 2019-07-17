package Internet_info;

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  return "Интернет";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $self->{bot}->{uid};

  use Internet;
  my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  my $list = $Internet->list({
    ID        => '_SHOW',
    TP_NAME   => '_SHOW',
    SPEED     => '_SHOW',
    MONTH_FEE => '_SHOW',
    DAY_FEE   => '_SHOW',
    GROUP_BY  => 'internet.id',
    UID       => $uid,
    COLS_NAME => 1,
  });

  my $message = "Подключенные сервисы:\n\n";

  foreach (@$list) {
    $message .= "Тарифный план: <b>$_->{tp_name}</b>\n";
    $message .= "Скорость: <b>$_->{speed}</b>\n" if ($_->{speed});
    $message .= "Стоимость за месяц: <b>$_->{month_fee}</b>\n" if ($_->{month_fee} && $_->{month_fee} > 0);
    $message .= "Стоимость за день: <b>$_->{day_fee}</b>\n" if ($_->{day_fee} && $_->{day_fee} > 0);
    $message .= "\n";
  }

  $self->{bot}->send_message({
    text       => $message,
    parse_mode => 'HTML'
  }); 

  return 1;
}

1;