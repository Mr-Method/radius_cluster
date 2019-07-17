package User_info;

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
  return "Аккаунт";
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
  $Users->pi({UID => $uid});

  my $message = "Здравствуйте, $Users->{FIO}\n\n";
  $message .= "Ваш логин: $Users->{LOGIN}\n";
  $message .= sprintf("Ваш депозит: %.2f\n", $Users->{DEPOSIT});

  $self->{bot}->send_message({
    text => $message,
  }); 

  return 1;
}

1;
