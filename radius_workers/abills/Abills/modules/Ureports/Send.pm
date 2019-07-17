=head1 NAME

  Ureports::Send

=head2 SYNOPSIS

  This is code for sending reports

=cut


use strict;
use warnings FATAL => 'all';

use Abills::Base qw/cmd in_array/;
use Abills::Misc;
use Abills::Templates;
use Abills::Sender::Core;
use Ureports;

our ($html, %conf, $db, $admin);

my $debug = 0;

my $Sender   = Abills::Sender::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 ureports_send_reports($type, $destination, $message, $attr)

  Arguments:
    $type           - sender type
    $destination    - Destination address
    $message
    $attr
       MESSAGE_TEPLATE || REPORT_ID
       UID
       TP_ID
       REPORT_ID
       SUBJECT
       DEBUG

   Returns:
     boolean

=cut
#**********************************************************
sub ureports_send_reports {
  my ($type, $destination, $message, $attr) = @_;

  return 0 unless ( defined $type );
  $debug = $attr->{DEBUG} || 0;

  # Fix old EMAIL type 0 -> 9
  $type = 9 if ( $type eq '0' );

  if ( $attr->{MESSAGE_TEPLATE} ) {
    $message = $html->tpl_show(_include($attr->{MESSAGE_TEPLATE}, 'Ureports'), $attr,
      { OUTPUT2RETURN => 1 });
  }
  elsif ( $attr->{REPORT_ID} ) {
    $message = $html->tpl_show(_include('ureports_report_' . $attr->{REPORT_ID}, 'Ureports'), $attr,
      { OUTPUT2RETURN => 1 });
  }

  if ( $debug > 6 ) {
    print "TYPE: $type DESTINATION: $destination MESSAGE: $message\n";
    return 1;
  }

  my $status = 0;
  if ( $type == 1 ) {
    if ( in_array('Sms', \@MODULES) ) {
      $attr->{MESSAGE} = $message;
      $message = $html->tpl_show(_include('ureports_sms_message', 'Ureports'), $attr, { OUTPUT2RETURN => 1 });

      load_module('Sms');
      $status = sms_send(
        {
          NUMBER    => $destination,
          MESSAGE   => $message,
          DEBUG     => $debug,
          UID       => $attr->{UID},
          PERIODIC  => 1
        }
      );
    }
    elsif ( $conf{UREPORTS_SMS_CMD} ) {
      cmd("$conf{UREPORTS_SMS_CMD} $destination $message");
    }
  }
  else {
    $Sender->send_message({
      UID         => $attr->{UID},
      TO_ADDRESS  => $destination,
      SENDER_TYPE => $type,
      MESSAGE     => $message,
      SUBJECT     => $attr->{SUBJECT} || '',
      DEBUG       => ($debug > 2) ? $debug - 2 : undef
    });

    $status = $Sender->{STATUS};
  }

  if ( $debug < 5 ){
    my $Ureports = Ureports->new( $db, $admin, \%conf );
    $Ureports->log_add(
      {
        DESTINATION => $destination,
        BODY        => $message,
        UID         => $attr->{UID},
        TP_ID       => $attr->{TP_ID} || 0,
        REPORT_ID   => $attr->{REPORT_ID} || 0,
        STATUS      => $status || 0
      }
    );
  }

  return 1;
}


1;