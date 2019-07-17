package Balance;

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
  return "Баланс";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;
  my $uid = $self->{bot}->{uid};

  use Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  
  use Payments;
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my $last_payments = $Payments->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  Abills::Base::_bp('1',$last_payments,{TO_CONSOLE => 1});

  use Fees;
  my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
  my $last_fees = $Fees->list({
    DATETIME  => '_SHOW',
    SUM       => '_SHOW',
    DESCRIBE  => '_SHOW',
    DESC      => 'desc',
    SORT      => 1,
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  my $message = sprintf("Ваш депозит: %.2f\n", $Users->{DEPOSIT});
  $message .= "Кредит: $Users->{CREDIT}\n" if ($Users->{CREDIT} && $Users->{CREDIT} > 0);
  $message .= "Кредит доступен до: $Users->{CREDIT_DATE}\n" if ($Users->{CREDIT_DATE} && $Users->{CREDIT_DATE} ne '0000-00-00');
  $message .= "\n";

  $message .= "Последняя оплата:\n";
  $message .= sprintf("Сумма: %.2f\n", $last_payments->[0]->{sum}) if ($last_payments->[0]->{sum});
  $message .= "Дата: $last_payments->[0]->{datetime}\n" if ($last_payments->[0]->{datetime});
  $message .= "Описание: $last_payments->[0]->{describe}\n" if ($last_payments->[0]->{describe});
  $message .= "\n";

  $message .= "Последнее списание:\n";
  $message .= sprintf("Сумма: %.2f\n", $last_fees->[0]->{sum}) if ($last_fees->[0]->{sum});
  $message .= "Дата: $last_fees->[0]->{datetime}\n" if ($last_fees->[0]->{datetime});
  $message .= "Описание: $last_fees->[0]->{describe}\n" if ($last_fees->[0]->{describe});

  $self->{bot}->send_message({
    text         => $message,
  }); 

  return 1;
}

1;