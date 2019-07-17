package Ureports::Report1;
use strict;
use warnings FATAL => 'all';

my %SYS_CONF    = (
  'REPORT_ID'       => 51,
  'REPORT_NAME'     => 'Report1 name',
  'REPORT_FUNCTION' => 'report1',
  'COMMENTS'        => 'Happy birthday',
  'TEMPLATE'        => 'ureports_report_0'
);

#**********************************************************
=head2 report1()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my($db, $admin, $CONF) = @_;

  my $self = {
    db   => $db,
    admin=> $admin,
    conf => $CONF
  };

  bless($self, $class);

  $self->{SYS_CONF} = \%SYS_CONF;

  return $self;
}


#**********************************************************
=head2 report1()

=cut
#**********************************************************
sub report1 {
  my $self = shift;
  my ($user) = @_;
  # $user->{VALUE}
  my %PARAMS = ();

  $PARAMS{MESSAGE} = 'Happy birthday';
  $PARAMS{SUBJECT} = 'Happy birthday ' . ($user->{fio}  || '');

  $self->{PARAMS} = \%PARAMS;

  return 1;
}

1;
