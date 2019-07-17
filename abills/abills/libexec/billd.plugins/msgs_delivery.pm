=head1 NAME

  Msgs delivery


 Arguments:
  CUSTOM_DELIVERY=message_file
  ADDRESS_LIST=address_list
  SLEEP= Sleep after message send
  LOGIN=
  UID=

=head1  EXAMPLES

    billd msgs_delivery CUSTOM_DELIVERY=message_file ADDRESS_LIST=address_list

=cut

use strict;
use warnings;
use Abills::Base qw(sendmail in_array);
use Abills::Sender::Core;
use Msgs;
use Users;

our (
  $debug,
  %conf,
  $Admin,
  $var_dir,
  $db,
  $argv,
  %LIST_PARAMS
);


my $Sender = Abills::Sender::Core->new({
  CONF => \%conf,
  SENDER_TYPE => 'Mail'
});
my $Log     = Log->new($db, $Admin);
my %list_params = %LIST_PARAMS;
our $html = Abills::HTML->new( { CONF => \%conf } );
%LIST_PARAMS = %list_params;

if($debug > 2) {
  $Log->{PRINT}=1;
}
else {
  $Log->{LOG_FILE} = $var_dir.'/log/msgs_delivery.log';
}

if($argv->{CUSTOM_DELIVERY}) {
  custom_delivery();
}
else {
  msgs_delivery();
}

#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub custom_delivery {

  my $text = get_content($argv->{CUSTOM_DELIVERY});

  my $addresses = '';
  if($argv->{ADDRESS_LIST}) {
    $addresses = get_content($argv->{ADDRESS_LIST});
  }
  else {
    print "No address list ADDRESS_LIST=address_list\n";
    exit;
  }

  my $subject   = '';

  if($text =~ s/Subject: (.+)//) {
    $subject = $1;
  }

  my @address_list = split(/\n\r?/, $addresses);

  foreach my $to_address (@address_list) {
    print "$to_address // $subject \n\n $text \n" if($debug > 3);

    $Sender->send_message({
      TO_ADDRESS => $to_address,
      MESSAGE    => $text,
      SUBJECT    => $subject,
      SENDER_TYPE=> 'Mail',
      #UID       => 1
    });
  }

  return 1;
}

#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub get_content {
  my($filename) = shift;

  my $content = '';

  if(open(my $fh, '<', $filename)) {
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);
  }
  else {
    print "Error: '$filename' $!\n";
  }

  return $content;
}


#**********************************************************
=head2 msgs_delivery($attr) - Msgs delivery function

=cut
#**********************************************************
sub msgs_delivery {
  #my ($attr) = @_;

  my $debug_output = '';
  $debug_output .= "Mdelivery\n" if ($debug > 1);

  my @send_methods = (
    'Push',
    'Mail',
    'Sms',
    'Web_redirect'
  );

  my $Msgs_delivery = Msgs->new($db, $Admin, \%conf);
  my $SEND_DATE           = $argv->{DATE} || $DATE;
  $LIST_PARAMS{STATUS}    = 0;
  $LIST_PARAMS{SEND_DATE} = "<=$SEND_DATE";

  if($debug>6) {
    $Msgs_delivery->{debug}=1;
  }

  my $delivery_list = $Msgs_delivery->msgs_delivery_list({
    %LIST_PARAMS,
    COLS_NAME => 1
  });

  my $users = Users->new($db, $Admin, \%conf);
  my $Internet;

  if (in_array('Internet', \@MODULES)) {
    require Internet;
    $Internet = Internet->new($db, $Admin, \%conf);
  }

  foreach my $mdelivery (@$delivery_list) {
    $Msgs_delivery->msgs_delivery_info($mdelivery->{id});
    $Log->log_print('LOG_INFO', '', "Delivery: $mdelivery->{id} Send method: $send_methods[$Msgs_delivery->{SEND_METHOD}] ($Msgs_delivery->{SEND_METHOD}) ");
    $LIST_PARAMS{PAGE_ROWS}    = 1000000;
    $LIST_PARAMS{MDELIVERY_ID} = $mdelivery->{id};

    $Msgs_delivery->attachment_info({ MSG_ID => $mdelivery->{id}, COLS_NAME => 1 });

    my @ATTACHMENTS = ();

    if ($Msgs_delivery->{TOTAL} > 0) {
      foreach my $line (@{ $Msgs_delivery->{list} }) {
        push @ATTACHMENTS,
        {
          ATTACHMENT_ID => $line->{attachment_id},
          FILENAME      => $line->{filename},
          CONTENT_TYPE  => $line->{content_type},
          FILESIZE      => $line->{filesize},
          CONTENT       => $line->{content}
        };
      }
    }

    my $user_list = $Msgs_delivery->delivery_user_list({
      %LIST_PARAMS,
      STATUS    => 0,
      COLS_NAME => 1
    });

    my @users_ids = ();

    foreach my $u (@$user_list) {
      my $email = ($u->{email}) ? $u->{email} : ($conf{USERS_MAIL_DOMAIN}) ? $u->{login} . '@' . $conf{USERS_MAIL_DOMAIN} : '';
      if (!$email) {
        print "Login: $u->{login} Don't have mail address. Skip...\n";
        next;
      }

      $Msgs_delivery->{SENDER} = ($Msgs_delivery->{SENDER}) ? $Msgs_delivery->{SENDER} : $conf{ADMIN_MAIL};

      $Log->log_print('LOG_DEBUG', $u->{login}, "E-mail: $email $Msgs_delivery->{SUBJECT}");

      push @users_ids, $u->{uid};

      my $user_pi = $users->pi({ UID => $u->{uid} });
      my $internet_info = {};
      if (in_array('Dv', \@MODULES)) {
        $internet_info = $Internet->info($u->{uid});
      }

      my $message = $html->tpl_show($Msgs_delivery->{TEXT}, {%$user_pi, %$internet_info}, {
        OUTPUT2RETURN      => 1, 
        SKIP_DEBUG_MARKERS => 1
      });

      if($debug < 6) {
        $Sender->send_message({
          SENDER      => $Msgs_delivery->{SENDER},
          TO_ADDRESS  => $email,
          MESSAGE     => $message,
          SUBJECT     => $Msgs_delivery->{SUBJECT},
          SENDER_TYPE => $send_methods[$Msgs_delivery->{SEND_METHOD} || 1],
          ATTACHMENTS => ($#ATTACHMENTS > -1) ? \@ATTACHMENTS : undef,
          #UID       => 1
        });

        if($argv->{SLEEP}) {
          sleep int($argv->{SLEEP});
        }
      }
    }

    if (!$LIST_PARAMS{LOGIN}) {
      $Msgs_delivery->delivery_user_list_change({
        MDELIVERY_ID => $mdelivery->{id}  || '-',
        UID          => join(';', @users_ids)
      });

      $Msgs_delivery->msgs_delivery_change({
        ID          => $mdelivery->{id} || '-',
        SENDED_DATE => "$DATE $TIME",
        STATUS      => 2
      });
    }
  }

  $DEBUG .= $debug_output;

  return $debug_output;
}

1

