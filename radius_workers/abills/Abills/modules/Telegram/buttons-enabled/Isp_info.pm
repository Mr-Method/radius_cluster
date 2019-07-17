package Isp_info;

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
  return "1";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  use Conf;
  my $Conf = Conf->new($self->{db}, $self->{admin}, $self->{conf});

  my $message = "";
  $message .= "Название компании: $Conf->{conf}->{ORGANIZATION_NAME}\n" if ($Conf->{conf}->{ORGANIZATION_NAME});
  $message .= "Адресс: $Conf->{conf}->{ORGANIZATION_ADDRESS}\n" if ($Conf->{conf}->{ORGANIZATION_ADDRESS});
  $message .= "Телефон: $Conf->{conf}->{ORGANIZATION_PHONE}\n" if ($Conf->{conf}->{ORGANIZATION_PHONE});
  $message .= "Электронная почта: $Conf->{conf}->{ORGANIZATION_MAIL}\n" if ($Conf->{conf}->{ORGANIZATION_MAIL});

  $self->{bot}->send_message({
    text         => $message,
  }); 

  return 1;
}

1;