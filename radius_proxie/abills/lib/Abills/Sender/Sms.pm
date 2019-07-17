package Abills::Sender::Sms;
=head1 NAME

  Send E-mail message

=cut


use strict;
use warnings FATAL => 'all';

use Abills::Sender::Plugin;
use parent 'Abills::Sender::Plugin';


#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Email addess
    MAIL_TPL
    UID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  unless ($attr->{TO_ADDRESS}){
    print "No recipient address given \n" if($self->{debug});
    return 0;
  };

  our $html = Abills::HTML->new();
  our %conf = %{ $self->{conf} };
  our $db   = $self->{db};

  do 'Abills/Misc.pm';
  load_module('Sms', $html);

  my $status = sms_send(
     {
       NUMBER    => $attr->{TO_ADDRESS},
       MESSAGE   => $attr->{MESSAGE},
       DEBUG     => $attr->{debug},
       UID       => $attr->{UID},
       PERIODIC  => 1
     }
  );
  $self->{status}=$status;
  $self->{message_id}=$status;

  print "Start send smss $attr->{UID} //";

  return 1;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;

1;