package Paysys::systems::Ipay;

=head1 Ipay
  New module for Ipay payment system

  Date: 07.06.2018
=cut

use strict;
use warnings FATAL => 'all';

use parent 'main';

use Abills::Base qw(load_pmodule _bp);
use Abills::Fetcher;
require Abills::Templates;
require Paysys::Paysys_Base;
our $PAYSYSTEM_VERSION = '1.01';

my $CONF;

my $PAYSYSTEM_NAME       = 'Ipay';
my $PAYSYSTEM_SHORT_NAME = 'IPAY';

my $PAYSYSTEM_ID         = 72;

my $DEBUG = 1;
my %PAYSYSTEM_CONF = (
  PAYSYS_IPAY_LANGUAGE => '',
  PAYSYS_IPAY_FAST_PAY => '',
  PAYSYS_IPAY_REQUEST_URL => '',
  PAYSYS_IPAY_SIGN_KEY => '',
  PAYSYS_IPAY_MERCHANT_KEY => '',
);

my %MERCHANT_CONF = (
  PAYSYS_IPAY_MERCHANT_KEY => '',
  PAYSYS_IPAY_SIGN_KEY     => '',
);

my ($json, $html, $user, $SELF_URL, $DATETIME, $OUTPUT2RETURN);
our $users;

#**********************************************************
=head2 new() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub new2 {
  my $class = shift;

  $CONF = shift;
  my $FORM  = shift;
  my $lang  = shift;
  my $index = shift;
  $user = shift;
#  $user  = $users;
#  $users->pi({UID => $user->{UID}});
  $user->pi({UID => $user->{UID}});
  my $attr = shift;
  $DEBUG = $CONF->{PAYSYS_DEBUG} || 1;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{SELF_URL}) {
    $SELF_URL = $attr->{SELF_URL};
  }

  if ($attr->{DATETIME}) {
    $DATETIME = $attr->{DATETIME};
  }

  my $self = {
    conf  => $CONF,
    lang  => $lang,
    FORM  => $FORM,
    index => $index
  };

  bless($self, $class);

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  return $self;
}

#**********************************************************
=head2 new()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONFIG, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONFIG,
    DEBUG => $CONFIG->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if($attr->{LANG}) {
    $self->{lang} = $attr->{LANG};
  }

  if($attr->{INDEX}){
    $self->{index} = $attr->{INDEX};
  }

  if($attr->{SELF_URL}){
    $SELF_URL = $attr->{SELF_URL};
  }

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************

=head2 paysys_ipay() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut

#**********************************************************
sub paysys_ipay {
  my $self = shift;
  load_pmodule('JSON');

  # Check the PHONE format
  if ($user->{PHONE}) {
    ($user->{PHONE}) = $user->{PHONE} =~ /(\d+)/;
    $user->{PHONE} =~ s/^0/380/;

    if ($user->{PHONE} !~ /^380/ || length($user->{PHONE}) != 12) {
      return $html->message("err", "$self->{lang}->{ERR_WRONG_PHONE}", "$self->{lang}->{PHONE}: 380XXXXXXXXX", { OUTPUT2RETURN => 1 });
    }
  }
  else {
    return $html->message("err", "$self->{lang}->{ERR_WRONG_PHONE}", "$self->{lang}->{PHONE}: 380XXXXXXXXX", { OUTPUT2RETURN => 1 });
  }

  # Card delete
  if ($self->{FORM}->{DeleteCard}) {
    my $json_request_string = $self->create_request_params_in_json('DeleteCard', { CARD_ALIAS => $self->{FORM}->{DeleteCard} });
    use utf8;
    utf8::decode($json_request_string || '');
    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string });

    my $RESULT_HASH = $json->decode($result)->{response};

    if ($RESULT_HASH->{status} && $RESULT_HASH->{status} eq 'OK') {
      $html->message('info', "$self->{lang}->{SUCCESS}", "$self->{lang}->{DELETED}");
    }
    else {
      $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{NOT} $self->{lang}->{DELETED}");
    }
  }

  # make payment if registered
  if ($self->{FORM}->{ipay_pay}) {
    my $json_create_payment_string = $self->create_request_params_in_json(
      'PaymentCreate',
      {
        CARD_ALIAS => $self->{FORM}->{CARD_ALIAS},
        INVOICE    => $self->{FORM}->{SUM},
        ACC        => $self->{FORM}->{OPERATION_ID},
      }
    );
    use utf8;
    utf8::decode($json_create_payment_string || '');
    my $pay_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_create_payment_string });

    my $PAY_RESULT = $json->decode($pay_result)->{response};

    if ($PAY_RESULT->{pmt_status} && $PAY_RESULT->{pmt_status} == 5) {
     # my ($status_code) = main::paysys_pay(
     #   {
     #     PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
     #     PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
     #     CHECK_FIELD       => 'UID',
     #     USER_ID           => $user->{UID},
     #     SUM               => ($PAY_RESULT->{invoice} / 100),
     #     EXT_ID            => $PAY_RESULT->{pmt_id},
     #     DATA              => $self->{FORM},
     #     DATE              => "$DATETIME",
          # CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
     #     MK_LOG           => 1,
     #     DEBUG            => 1,
     #     ERROR            => 1,
     #     PAYMENT_DESCRIBE => 'IPAY',
     #     USER_INFO_OBJECT        => $user,
     #   }
     # );
     # if ($status_code == 0) {
        $html->message("success", "$self->{lang}->{SUCCESS}", "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}");
      #}
      #else{
      #  $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
      #}
    }
    elsif($PAY_RESULT->{pmt_status} && $PAY_RESULT->{pmt_status} == 4){
      $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
    }
  }

  if ($self->{FORM}->{ipay_purchase}) {
    if($self->{FORM}->{ipay_purchase} == 1){
        $html->message("success", "$self->{lang}->{SUCCESS}", "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}");
    }
    elsif($self->{FORM}->{ipay_purchase} == 2){
      $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
    }
  }

  if ($self->{FORM}->{ipay_register_purchase}) {

    # call register by url action
    my $register_purchse_by_url_string = $self->create_request_params_in_json(
      'RegisterPurchaseByURL',
      {
        INVOICE => $self->{FORM}->{SUM},
        ACC     => $self->{FORM}->{OPERATION_ID},
      }
    );
    use utf8;
    utf8::decode($register_purchse_by_url_string || '');
    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $register_purchse_by_url_string, });
    my $RESULT_HASH = $json->decode($result);

    $html->tpl_show(
      main::_include('paysys_ipay_register_purchase', 'Paysys'),
      {
        URL => $RESULT_HASH->{response}->{url},
      }
    );
  }

  # TEST INVITE
  #    my $json_request_string_testinvite = $self->create_request_params_in_json('TestInvite');
  #    my $testinvite_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string_testinvite });
  #    my $HASH_TEST_IVNITE_RESULT = $json->decode($testinvite_result);
  #    my $testinvite_url = $HASH_TEST_IVNITE_RESULT->{response}->{url};
  #    $testinvite_url=~ s/\\\//\//g;
  #    _bp('test invite', $testinvite_url, {HEADER=>1});

  my $json_request_string_check = $self->create_request_params_in_json('Check');

  # send REQUEST_HASH to IPAY for check
  my $check_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string_check });

  if ($check_result eq '') {
    return $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_WRONG_DATA}", { OUTPUT2RETURN => 1 });
  }
  my $RESULT_HASH = $json->decode($check_result);

  if($RESULT_HASH->{response} && $RESULT_HASH->{response}->{error}){
    return $html->message("err", "$self->{lang}->{ERROR}", "$RESULT_HASH->{response}->{error}", { OUTPUT2RETURN => 1 });
  }
  # EXIST PROCESSING
  if (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'exists') {

    # call list action
    my $cards_list       = '';
    my $json_list_string = $self->create_request_params_in_json('List');

    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_list_string, });
    my $RESULT_HASH = $json->decode($result)->{response};

    #    my $RESULT_HASH = {
    #        card1 => {
    #            card_alias => 'card number one',
    #            mask => '1312********1231',
    #        },
    #        card2 => {
    #            card_alias => 'card number one',
    #            mask => '1312********1231',
    #        }
    #    };
    my $card_checked = 0;
    foreach my $card (keys %{$RESULT_HASH}) {

      my $button_delete_card = $html->button("$self->{lang}->{DEL}", "index=$self->{index}&DeleteCard=$RESULT_HASH->{$card}->{card_alias}", { ICON => 'fa fa-trash fa-2x' });

      $cards_list .= $html->tpl_show(
        main::_include('paysys_ipay_one_card', 'Paysys'),
        {
          NAME          => $RESULT_HASH->{$card}->{card_alias},
          MASK          => $RESULT_HASH->{$card}->{mask},
          DELETE_BUTTON => $button_delete_card,
          CHECKED       => $card_checked == 0 ? 'checked' : '',
          CARD_SELECTED => $card_checked == 0 ? 'card-selected' : '',
        },
        { OUTPUT2RETURN => 1 }
      );
      $card_checked = 1;
    }

    my $json_add_card_by_url__string = $self->create_request_params_in_json('AddcardByURL');

    my $result2 = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_add_card_by_url__string, });
    $RESULT_HASH = $json->decode($result2);

    my $add_card_by_url = $RESULT_HASH->{response}->{url};
    $add_card_by_url =~ s/\\\//\//g;

    # button register by url
    my $button_add_card_by_url = $html->button("$self->{lang}->{ADD_CARD}", '', { GLOBAL_URL => $add_card_by_url, class => 'btn btn-success btn-xs', ADD_ICON=> 'glyphicon glyphicon-plus'});
    my $submit_name = 'ipay_pay';

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_cards_list', 'Paysys'),
      {
        CARDS => $cards_list,

        ADD_BTN     => $button_add_card_by_url,
        SUBMIT_NAME => $submit_name
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  # INVITE PROCESSING
  elsif (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'invite') {

    # call invite by url action
    my $json_invite_by_url_string = $self->create_request_params_in_json('InviteByURL');
    my $invite_by_url_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_invite_by_url_string, });

    my $RESULT_HASH = $json->decode($invite_by_url_result);

    my $confirm_invite_url = $RESULT_HASH->{response}->{url};
    $confirm_invite_url =~ s/\\\//\//g;

    my $button_invite_url = $html->button("$self->{lang}->{PLUG_IN}", '', { GLOBAL_URL => $confirm_invite_url, class => 'btn btn-success' });

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_invite_by_url', 'Paysys'),
      {
        INVITE_BY_URL_BTN => $button_invite_url
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  # NOT EXIST PROCESSING
  elsif (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'notexists') {
    my $submit_name = 'ipay_register_purchase';

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_register_purchase', 'Paysys'),
      {
        SUBMIT_NAME => $submit_name
      },
      { OUTPUT2RETURN => 1 }
    );
  }
  $OUTPUT2RETURN = "<label class='col-md-12 bg-success text-center'>Оплата в один клик</label>" . ($OUTPUT2RETURN || '');
  return $OUTPUT2RETURN;
}

#**********************************************************
=head2 create_request_params() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub create_request_params_in_json {
  my $self = shift;
  my ($action, $attr) = @_;

  if($attr->{USER}){
    $user = $attr->{USER};
  }

  load_pmodule('Digest::MD5');
  my $md5 = Digest::MD5->new();
  ($user->{PHONE}) = $user->{PHONE} =~ /(\d+)/;
  $user->{PHONE} =~ s/^0/380/;

  # REQUEST_HASH Hash
  my %REQUEST_HASH;
  $REQUEST_HASH{request}{action}      = $action;                                      #action

  main::conf_gid_split({
    GID => $user->{GID},
    PARAMS => [
      'PAYSYS_IPAY_MERCHANT_KEY',
      'PAYSYS_IPAY_SIGN_KEY'
    ]
  });

  my $merchant_key = $self->{conf}->{PAYSYS_IPAY_MERCHANT_KEY};
  my $sign_key     = $self->{conf}->{PAYSYS_IPAY_SIGN_KEY};

  $REQUEST_HASH{request}{auth}{login} = $merchant_key;    # login from Ipay

  # TODO: заменить добавление количество часов на правильное время таймзоны Киева
#    my $time = time();
#    $time = $time + 2 * 60 * 60;
#    my $date = POSIX::strftime("%F %X", gmtime($time));
#  $REQUEST_HASH{request}{auth}{time}  = $date;                                    # now time
  use Time::Piece;
  my $t = localtime;
  my $time = $t->epoch + (($t->isdst) ? 3 : 2) * 60 * 60;
  my $date = POSIX::strftime("%F %X", gmtime($time));
  $REQUEST_HASH{request}{auth}{time}  = $date;

  # create a sign string which became a signature
  my $sign_string = $REQUEST_HASH{request}{auth}{time} . $sign_key;

  # create signature from sign string
  $md5->add($sign_string);
  my $md5_sign = $md5->hexdigest();

  $REQUEST_HASH{request}{auth}{sign} = $md5_sign;                                     # sign to request

  if ($action eq 'Check') {
    $REQUEST_HASH{request}{body}{msisdn}  = $user->{PHONE};                           # user phone
    $REQUEST_HASH{request}{body}{user_id} = $user->{UID};                             # user id in abills
  }
  elsif ($action eq 'RegisterByURL') {
    $REQUEST_HASH{request}{body}{msisdn}      = $user->{PHONE};                                   # user phone
    $REQUEST_HASH{request}{body}{user_id}     = $user->{UID};                                     # user id in abills
    $REQUEST_HASH{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';    # lang: ua/ru/en
    $REQUEST_HASH{request}{body}{success_url} = "$SELF_URL?index=$self->{index}";                 # url after success registration
    $REQUEST_HASH{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}";                 # url after fail registration
  }
  elsif ($action eq 'List') {
    $REQUEST_HASH{request}{body}{msisdn}  = $user->{PHONE};                                       # user phone
    $REQUEST_HASH{request}{body}{user_id} = $user->{UID};                                         # user id in abills
  }
  elsif ($action eq 'DeleteCard') {
    $REQUEST_HASH{request}{body}{msisdn}     = $user->{PHONE};                                    # user phone
    $REQUEST_HASH{request}{body}{user_id}    = $user->{UID};                                      # user id in abills
    $REQUEST_HASH{request}{body}{card_alias} = $attr->{CARD_ALIAS};
  }
  elsif ($action eq 'PaymentCreate') {
    $REQUEST_HASH{request}{body}{msisdn}     = $user->{PHONE};                                    # user phone
    $REQUEST_HASH{request}{body}{user_id}    = $user->{UID};                                      # user id in abills
    $REQUEST_HASH{request}{body}{card_alias} = $attr->{CARD_ALIAS};
    $REQUEST_HASH{request}{body}{invoice}    = $attr->{INVOICE} * 100;

    # $REQUEST_HASH{request}{body}{guid}=$attr->{GUID};
    if($self->{conf}{PAYSYS_IPAY_DESC}){
      $self->{conf}{PAYSYS_IPAY_DESC} =~ s/\%([^\%]+)\%/($user->{$1} || '')/g;
      $REQUEST_HASH{request}{body}{pmt_desc}          = $self->{conf}{PAYSYS_IPAY_DESC};
    }
    else{
      $REQUEST_HASH{request}{body}{pmt_desc}          = "Оплата услуг согласно счету " . ($user->{_PIN_ABS} || $user->{BILL_ID} || '');
    }
    $REQUEST_HASH{request}{body}{pmt_info}{invoice} = $attr->{INVOICE} * 100;
    $REQUEST_HASH{request}{body}{pmt_info}{acc}     = $user->{UID};
  }
  elsif ($action eq 'AddcardByURL') {
    $REQUEST_HASH{request}{body}{msisdn}      = $user->{PHONE};                                   # user phone
    $REQUEST_HASH{request}{body}{user_id}     = $user->{UID};                                     # user id in abills
    $REQUEST_HASH{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';    # lang: ua/ru/en
    $REQUEST_HASH{request}{body}{success_url} = "$SELF_URL?index=$self->{index}";                 # url after success registration
    $REQUEST_HASH{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}";                 # url after fail registration
  }
  elsif ($action eq 'RegisterPurchaseByURL') {
    $REQUEST_HASH{request}{body}{msisdn}      = $user->{PHONE};                                                                                                                              # user phone
    $REQUEST_HASH{request}{body}{user_id}     = $user->{UID};                                                                                                                                # user id in abills
    $REQUEST_HASH{request}{body}{lang}        = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';                                                                                               # lang: ua/ru/en
    $REQUEST_HASH{request}{body}{success_url} = "$SELF_URL?qindex=$self->{index}&ipay_purchase=1&header=1&invoice=" . ($attr->{INVOICE} * 100) . "&pmt_id=$attr->{ACC}&UID=$user->{UID}";    # url after success registration
    $REQUEST_HASH{request}{body}{error_url}   = "$SELF_URL?qindex=$self->{index}&ipay_purchase=2&header=1&invoice=" . ($attr->{INVOICE} * 100) . "&pmt_id=$attr->{ACC}&UID=$user->{UID}";;                                                                           # url after fail registration

    $REQUEST_HASH{request}{body}{invoice}           = $attr->{INVOICE} * 100;
    if($self->{conf}{PAYSYS_IPAY_DESC}){
      $self->{conf}{PAYSYS_IPAY_DESC} =~ s/\%([^\%]+)\%/($user->{$1} || '')/eg;
      $REQUEST_HASH{request}{body}{pmt_desc}          = $self->{conf}{PAYSYS_IPAY_DESC};
    }
    else{
      $REQUEST_HASH{request}{body}{pmt_desc}          = "Оплата услуг согласно счету " . ($user->{_PIN_ABS} || $user->{BILL_ID} || '');
    }
    $REQUEST_HASH{request}{body}{pmt_info}{invoice} = $attr->{INVOICE} * 100;
    $REQUEST_HASH{request}{body}{pmt_info}{acc}     = $user->{UID};
  }
  elsif ($action eq 'InviteByURL') {
    $REQUEST_HASH{request}{body}{msisdn}      = $user->{PHONE};                                                                                                                              # user phone
    $REQUEST_HASH{request}{body}{user_id}     = $user->{UID};                                                                                                                                # user id in abills
    $REQUEST_HASH{request}{body}{lang}        = 'ua';                                                                                                                                        # lang: ua/ru/en
    $REQUEST_HASH{request}{body}{success_url} = "$SELF_URL?index=$self->{index}";                                                                                                            # url after success registration
    $REQUEST_HASH{request}{body}{error_url}   = "$SELF_URL?index=$self->{index}";                                                                                                            # url after fail registration
  }
  elsif ($action eq 'TestInvite') {
    $REQUEST_HASH{request}{body}{msisdn}  = $user->{PHONE};                                                                                                                                  # user phone
    $REQUEST_HASH{request}{body}{user_id} = $user->{UID};                                                                                                                                    # user id in abills
    $REQUEST_HASH{request}{body}{lang}    = $self->{conf}->{PAYSYS_IPAY_LANGUAGE} || 'ru';
  }

  # REQUEST_HASH hash to json
  my $json_request_string = $json->encode(\%REQUEST_HASH);
  $json_request_string =~ s/\"/\\\"/g;

  return $json_request_string;
}

#**********************************************************
=head2 ipay_check_payments()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub ipay_check_payments {
  my $self = shift;
  print "Content-Type: text/html\n\n";
  my $buffer = $self->{FORM}->{__BUFFER};
  my ($xml) = $buffer =~ /xml\=(<.+>)/gms;
  main::mk_log($xml, {PAYSYS_ID => 'Ipay', REQUEST => 'Request'});
#  _bp("test", $xml, {TO_CONSOLE => 1});
#  my $xml = q{<?xml version="1.0" encoding="utf-8"?>
#<payment id="14706320">
#<ident>83ced0ac0c6525522ef64c4412816afdgf98113e7cc861</ident>
#<status>5</status>
#<amount>1000</amount>
#<currency>UAH</currency>
#<timestamp>1478301940</timestamp>
#<transactions>
#<transaction id="26852267">
#<mch_id>205452</mch_id>
#<srv_id>0</srv_id>
#<amount>1000</amount>
#<currency>UAH</currency>
#<type>20</type>
#<status>11</status>
#<code>00</code>
#<desc>INTERNET</desc>
#<info>{"account_number":"151348","amount":"10.00","mcc":"4814"}</info>
#</transaction>
#<transaction id="26852267">
#<mch_id>205452</mch_id>
#<srv_id>0</srv_id>
#<amount>1000</amount>
#<currency>UAH</currency>
#<type>21</type>
#<status>11</status>
#<code>00</code>
#<desc>INTENT</desc>
#<info>{"account_number":"1","amount":"10.00","mcc":"4814"}</info>
#</transaction>
#</transactions>
#<salt>78f9bf28be7f632427492403ef69b273cc8bf6fd</salt>
#<sign>522e04769878e412678d4bf8a2554442f7454505c9fc0fa07714a4cc6f8469704d63a6d664d47a4f64efb
#77a185df28d302c1f80a011a32gfdgdfgb5ef2938102305d8hcef44</sign>
#</payment>
#  };

  load_pmodule('XML::Simple');
  my $xs = XML::Simple->new(ForceArray => 1, KeepRoot => 1);
  my $ref = $xs->XMLin($xml);

  my $payment = $ref->{payment};
  my ($payment_id) = keys %$payment;

  my $payment_status = $payment->{$payment_id}->{status}->[0];

  my $transaction = $payment->{$payment_id}->{transactions}->[0]->{transaction};
  my ($transaction_id) = keys %$transaction;

  my $json_transaction_info = $transaction->{$transaction_id}->{info}->[0];

  my $desc = $transaction->{$transaction_id}->{desc}->[0];
  my $hash_transaction_info = $json->decode($json_transaction_info);


  my $payment_amount = $hash_transaction_info->{invoice} / 100;

  my $account = $hash_transaction_info->{acc};

  my %DATA;
  $DATA{UID} = $account;
  $DATA{amount} = $payment_amount;
  $DATA{payment_status} = $payment_status;
  $DATA{transaction_id} = $transaction_id;

  if($payment_status == 5){
    my ($status_code) = main::paysys_pay( {
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => 'UID',
      USER_ID           => $account,
      SUM               => $payment_amount,
      EXT_ID            => $payment_id,
      DATA              => \%DATA,
#      DATE              => "$DATETIME",
      DATE              => "$main::DATE $main::TIME",
      #    CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
      MK_LOG            => 1,
      #    PAYMENT_ID        => 1,
      DEBUG             => $DEBUG,
      PAYMENT_DESCRIBE  => $desc|| 'Ipay payment',
    } );

    print $status_code;
  }

  return 1;
}

#**********************************************************
=head2 get_settings()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub get_settings {
  my %SETTINGS = ();

  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{ID}      = $PAYSYSTEM_ID;
  $SETTINGS{NAME}    = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

#**********************************************************
=head2 user_portal()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub user_portal_special {
  my $self = shift;
  my ($user, $attr) = @_;

  load_pmodule('JSON');

  # Check the PHONE format
  if ($user->{PHONE}) {
    ($user->{PHONE}) = $user->{PHONE} =~ /(\d+)/;
    $user->{PHONE} =~ s/^0/380/;

    if ($user->{PHONE} !~ /^380/ || length($user->{PHONE}) != 12) {
      return $html->message("err", "$self->{lang}->{ERR_WRONG_PHONE}", "$self->{lang}->{PHONE}: 380XXXXXXXXX", { OUTPUT2RETURN => 1 });
    }
  }
  else {
    return $html->message("err", "$self->{lang}->{ERR_WRONG_PHONE}", "$self->{lang}->{PHONE}: 380XXXXXXXXX", { OUTPUT2RETURN => 1 });
  }

  # Card delete
  if ($attr->{DeleteCard}) {
    my $json_request_string = $self->create_request_params_in_json('DeleteCard', { CARD_ALIAS => $attr->{DeleteCard}, USER => $user });
    use utf8;
    utf8::decode($json_request_string || '');
    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string });

    my $RESULT_HASH = $json->decode($result)->{response};

    if ($RESULT_HASH->{status} && $RESULT_HASH->{status} eq 'OK') {
      $html->message('info', "$self->{lang}->{SUCCESS}", "$self->{lang}->{DELETED}");
    }
    else {
      $html->message('err', "$self->{lang}->{ERROR}", "$self->{lang}->{NOT} $self->{lang}->{DELETED}");
    }
  }

  # make payment if registered
  if ($attr->{ipay_pay}) {
    my $json_create_payment_string = $self->create_request_params_in_json(
      'PaymentCreate',
      {
        CARD_ALIAS => $attr->{CARD_ALIAS},
        INVOICE    => $attr->{SUM},
        ACC        => $attr->{OPERATION_ID},
        USER       => $user,
      }
    );
    use utf8;
    utf8::decode($json_create_payment_string || '');
    my $pay_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_create_payment_string });

    my $PAY_RESULT = $json->decode($pay_result)->{response};

    if ($PAY_RESULT->{pmt_status} && $PAY_RESULT->{pmt_status} == 5) {
      # my ($status_code) = main::paysys_pay(
      #   {
      #     PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      #     PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      #     CHECK_FIELD       => 'UID',
      #     USER_ID           => $user->{UID},
      #     SUM               => ($PAY_RESULT->{invoice} / 100),
      #     EXT_ID            => $PAY_RESULT->{pmt_id},
      #     DATA              => $self->{FORM},
      #     DATE              => "$DATETIME",
      # CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
      #     MK_LOG           => 1,
      #     DEBUG            => 1,
      #     ERROR            => 1,
      #     PAYMENT_DESCRIBE => 'IPAY',
      #     USER_INFO_OBJECT        => $user,
      #   }
      # );
      # if ($status_code == 0) {
      $html->message("success", "$self->{lang}->{SUCCESS}", "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}");
      #}
      #else{
      #  $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
      #}
    }
    elsif($PAY_RESULT->{pmt_status} && $PAY_RESULT->{pmt_status} == 4){
      $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
    }
  }

  if ($attr->{ipay_purchase}) {
    if($attr->{ipay_purchase} == 1){
      $html->message("success", "$self->{lang}->{SUCCESS}", "$self->{lang}->{SUCCESS} $self->{lang}->{TRANSACTION}");
    }
    elsif($attr->{ipay_purchase} == 2){
      $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERROR} $self->{lang}->{TRANSACTION}");
    }
  }

  if ($attr->{ipay_register_purchase}) {

    # call register by url action
    my $register_purchse_by_url_string = $self->create_request_params_in_json(
      'RegisterPurchaseByURL',
      {
        INVOICE => $attr->{SUM},
        ACC     => $attr->{OPERATION_ID},
        USER    => $user,
      }
    );
    use utf8;
    utf8::decode($register_purchse_by_url_string || '');
    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $register_purchse_by_url_string, });
    my $RESULT_HASH = $json->decode($result);

    $html->tpl_show(
      main::_include('paysys_ipay_register_purchase', 'Paysys'),
      {
        URL => $RESULT_HASH->{response}->{url},
      }
    );
  }

  # TEST INVITE
  #    my $json_request_string_testinvite = $self->create_request_params_in_json('TestInvite');
  #    my $testinvite_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string_testinvite });
  #    my $HASH_TEST_IVNITE_RESULT = $json->decode($testinvite_result);
  #    my $testinvite_url = $HASH_TEST_IVNITE_RESULT->{response}->{url};
  #    $testinvite_url=~ s/\\\//\//g;
  #    _bp('test invite', $testinvite_url, {HEADER=>1});

  my $json_request_string_check = $self->create_request_params_in_json('Check', {USER => $user});

  # send REQUEST_HASH to IPAY for check
  my $check_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_request_string_check });

  if ($check_result eq '') {
    return $html->message("err", "$self->{lang}->{ERROR}", "$self->{lang}->{ERR_WRONG_DATA}", { OUTPUT2RETURN => 1 });
  }
  my $RESULT_HASH = $json->decode($check_result);

  if($RESULT_HASH->{response} && $RESULT_HASH->{response}->{error}){
    return $html->message("err", "$self->{lang}->{ERROR}", "$RESULT_HASH->{response}->{error}", { OUTPUT2RETURN => 1 });
  }
  # EXIST PROCESSING
  if (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'exists') {

    # call list action
    my $cards_list       = '';
    my $json_list_string = $self->create_request_params_in_json('List');

    my $result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_list_string, });
    my $RESULT_HASH = $json->decode($result)->{response};

    #    my $RESULT_HASH = {
    #        card1 => {
    #            card_alias => 'card number one',
    #            mask => '1312********1231',
    #        },
    #        card2 => {
    #            card_alias => 'card number one',
    #            mask => '1312********1231',
    #        }
    #    };
    my $card_checked = 0;
    foreach my $card (keys %{$RESULT_HASH}) {

      my $button_delete_card = $html->button("$self->{lang}->{DEL}", "index=$self->{index}&DeleteCard=$RESULT_HASH->{$card}->{card_alias}", { ICON => 'fa fa-trash fa-2x' });

      $cards_list .= $html->tpl_show(
        main::_include('paysys_ipay_one_card', 'Paysys'),
        {
          NAME          => $RESULT_HASH->{$card}->{card_alias},
          MASK          => $RESULT_HASH->{$card}->{mask},
          DELETE_BUTTON => $button_delete_card,
          CHECKED       => $card_checked == 0 ? 'checked' : '',
          CARD_SELECTED => $card_checked == 0 ? 'card-selected' : '',
        },
        { OUTPUT2RETURN => 1 }
      );
      $card_checked = 1;
    }

    my $json_add_card_by_url__string = $self->create_request_params_in_json('AddcardByURL');

    my $result2 = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_add_card_by_url__string, });
    $RESULT_HASH = $json->decode($result2);

    my $add_card_by_url = $RESULT_HASH->{response}->{url};
    $add_card_by_url =~ s/\\\//\//g;

    # button register by url
    my $button_add_card_by_url = $html->button("$self->{lang}->{ADD_CARD}", '', { GLOBAL_URL => $add_card_by_url, class => 'btn btn-success btn-xs', ADD_ICON=> 'glyphicon glyphicon-plus'});
    my $submit_name = 'ipay_pay';

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_cards_list', 'Paysys'),
      {
        CARDS => $cards_list,

        ADD_BTN     => $button_add_card_by_url,
        SUBMIT_NAME => $submit_name
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  # INVITE PROCESSING
  elsif (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'invite') {

    # call invite by url action
    my $json_invite_by_url_string = $self->create_request_params_in_json('InviteByURL');
    my $invite_by_url_result = web_request("$self->{conf}->{PAYSYS_IPAY_REQUEST_URL}", { POST => $json_invite_by_url_string, });

    my $RESULT_HASH = $json->decode($invite_by_url_result);

    my $confirm_invite_url = $RESULT_HASH->{response}->{url};
    $confirm_invite_url =~ s/\\\//\//g;

    my $button_invite_url = $html->button("$self->{lang}->{PLUG_IN}", '', { GLOBAL_URL => $confirm_invite_url, class => 'btn btn-success' });

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_invite_by_url', 'Paysys'),
      {
        INVITE_BY_URL_BTN => $button_invite_url
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  # NOT EXIST PROCESSING
  elsif (defined $RESULT_HASH->{response}->{user_status} && $RESULT_HASH->{response}->{user_status} eq 'notexists') {
    my $submit_name = 'ipay_register_purchase';

    $OUTPUT2RETURN = $html->tpl_show(
      main::_include('paysys_ipay_start_register_purchase', 'Paysys'),
      {
        SUBMIT_NAME => $submit_name
      },
      { OUTPUT2RETURN => 1 }
    );
  }
  $OUTPUT2RETURN = "<label class='col-md-12 bg-success text-center'>Оплата в один клик</label>" . ($OUTPUT2RETURN || '');
  return $OUTPUT2RETURN;

}

#**********************************************************
=head2 process()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  print "Content-Type: text/html\n\n";
  my $buffer = $FORM->{__BUFFER};
  my ($xml) = $buffer =~ /xml\=(<.+>)/gms;
  main::mk_log($xml, {PAYSYS_ID => 'Ipay', REQUEST => 'Request'});
  #  _bp("test", $xml, {TO_CONSOLE => 1});
  #  my $xml = q{<?xml version="1.0" encoding="utf-8"?>
  #<payment id="14706320">
  #<ident>83ced0ac0c6525522ef64c4412816afdgf98113e7cc861</ident>
  #<status>5</status>
  #<amount>1000</amount>
  #<currency>UAH</currency>
  #<timestamp>1478301940</timestamp>
  #<transactions>
  #<transaction id="26852267">
  #<mch_id>205452</mch_id>
  #<srv_id>0</srv_id>
  #<amount>1000</amount>
  #<currency>UAH</currency>
  #<type>20</type>
  #<status>11</status>
  #<code>00</code>
  #<desc>INTERNET</desc>
  #<info>{"account_number":"151348","amount":"10.00","mcc":"4814"}</info>
  #</transaction>
  #<transaction id="26852267">
  #<mch_id>205452</mch_id>
  #<srv_id>0</srv_id>
  #<amount>1000</amount>
  #<currency>UAH</currency>
  #<type>21</type>
  #<status>11</status>
  #<code>00</code>
  #<desc>INTENT</desc>
  #<info>{"account_number":"1","amount":"10.00","mcc":"4814"}</info>
  #</transaction>
  #</transactions>
  #<salt>78f9bf28be7f632427492403ef69b273cc8bf6fd</salt>
  #<sign>522e04769878e412678d4bf8a2554442f7454505c9fc0fa07714a4cc6f8469704d63a6d664d47a4f64efb
  #77a185df28d302c1f80a011a32gfdgdfgb5ef2938102305d8hcef44</sign>
  #</payment>
  #  };

  load_pmodule('XML::Simple');
  my $xs = XML::Simple->new(ForceArray => 1, KeepRoot => 1);
  my $ref = $xs->XMLin($xml);

  my $payment = $ref->{payment};
  my ($payment_id) = keys %$payment;

  my $payment_status = $payment->{$payment_id}->{status}->[0];

  my $transaction = $payment->{$payment_id}->{transactions}->[0]->{transaction};
  my ($transaction_id) = keys %$transaction;

  my $json_transaction_info = $transaction->{$transaction_id}->{info}->[0];

  my $desc = $transaction->{$transaction_id}->{desc}->[0];
  my $hash_transaction_info = $json->decode($json_transaction_info);


  my $payment_amount = $hash_transaction_info->{invoice} / 100;

  my $account = $hash_transaction_info->{acc};

  my %DATA;
  $DATA{UID} = $account;
  $DATA{amount} = $payment_amount;
  $DATA{payment_status} = $payment_status;
  $DATA{transaction_id} = $transaction_id;

  if($payment_status == 5){
    my ($status_code) = main::paysys_pay( {
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      CHECK_FIELD       => 'UID',
      USER_ID           => $account,
      SUM               => $payment_amount,
      EXT_ID            => $payment_id,
      DATA              => \%DATA,
      DATE              => "$main::DATE $main::TIME",
      #    CURRENCY_ISO      => $conf{PAYSYS_OSMP_CURRENCY},
      MK_LOG            => 1,
      #    PAYMENT_ID        => 1,
      DEBUG             => $DEBUG,
      PAYMENT_DESCRIBE  => $desc|| 'Ipay payment',
    } );

    print $status_code;
  }

  return 1;

}

1
