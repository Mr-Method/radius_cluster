package Abills::Sender::Mail;
use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail);

=head1 NAME

  Send E-mail message

=cut

##**********************************************************
#=head2 send_message($attr)
#
#  Arguments:
#    $attr - hash_ref
#      UID     - user ID
#      MESSAGE - string. CANNOT CONTAIN DOUBLE QUOTES \"
#
#  Returns:
#    1 if success, 0 otherwise
#
#=cut
##**********************************************************
#sub send_message {
#  my $self = shift;
#  #my ($attr) = @_;
#
#
#  return $self;
#}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Email addess

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $sender = $attr->{SENDER} || $self->{conf}->{ADMIN_MAIL} || 'abills_admin';

  sendmail(
    $sender,
    $attr->{TO_ADDRESS},
    $attr->{SUBJECT},
    $attr->{MESSAGE},
    '',
    undef
  );

  print "Sending E-mail\n Subject: $attr->{SUBJECT}\n $attr->{MESSAGE}\n" if($self->{debug});

  return $self;
}

1;
