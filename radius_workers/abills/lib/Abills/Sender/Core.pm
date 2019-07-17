package Abills::Sender::Core;

=head1 NAME

  Authe core

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(show_hash);
use Log qw( log_print );

my $Contacts;

#**********************************************************
=head2

  Arguments:
    SELF_URL
    AUTH_TYPE
    USERNAME
    CONF

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $conf      = $attr->{CONF};
  my $self      = {
    conf     => $conf,
    self_url => $attr->{SELF_URL} || q{},
    domain_id=> $attr->{DOMAIN_ID},
    db       => $attr->{DB},
    admin    => $attr->{ADMIN}
  };

  bless($self, $class);

  if($attr->{SENDER_TYPE}) {
    $self->sender_load($attr->{SENDER_TYPE}, $attr);
  }

  if($self->{db}) {
    require Contacts;
    Contacts->import();
    $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});
  }

  return $self;
}

#**********************************************************
=head2 load_sender($attr)

  Arguments:

  Returns:
    $self

=cut
#**********************************************************
sub sender_load {
  my $self = shift;
  my ($sender_type, $attr)=@_;

  return $self if(! $sender_type);

  my $name = "Abills::Sender::$sender_type";
  eval " require $name ";

  if (!$@) {
    $name->import();
    our @ISA = ($name);
    $self->{SENDER_TYPE}=$sender_type;
    if($name->can('new')) {
      $self = $name->new($attr);
    }
  }
  else {
    print "Content-Type: text/html\n\n";
    print $@;
  }

  return $self;
}


#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    TO_ADDRESS
    PRIORITY_ID
    ADMIN_ID
    CLIENT_ID
    SENDER_TYPE

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr)=@_;

  if($attr->{UID}) {
    #Get contact address
    my $contacts_list = $Contacts->contacts_list({
      UID       => $attr->{UID},
      TYPE_NAME => $attr->{SENDER_TYPE},
      COLS_NAME => 1
    });

    if($Contacts->{TOTAL}) {
      $attr->{TO_ADDRESS} = $contacts_list->[0]->{VALUE};
      if(! $attr->{SENDER_TYPE}) {
        $attr->{SENDER_TYPE} = $contacts_list->[0]->{TYPE_NAME};
      }
    }
    else {
      print "Not defined address UID: $attr->{UID}";
      return 0;
    }
  }

  if($attr->{AID}) {
    #Get admins contact address
  }

  if($attr->{SENDER_TYPE}
    && ($self->{SENDER_TYPE} && $self->{SENDER_TYPE} ne $attr->{SENDER_TYPE})) {
    if($self->{conf}) {
      $attr->{CONF}=$self->{conf};
    }
    $self = $self->sender_load($attr->{SENDER_TYPE}, $attr);
  }


  return $self->SUPER::send_message($attr);
}

#**********************************************************
=head2 notification_type($attr)

  Arguments:
    MESSAGE

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub notification_type {
  my $self = shift;
  #my ($attr) = @_;

  my $list = {
    Browser => 'Browser',
    Mail    => 'Mail',
    Push    => 'Push',
    Telegram=> 'Telegram',
    Sms     => 'Sms'
  };

  return $list;
}

1;
