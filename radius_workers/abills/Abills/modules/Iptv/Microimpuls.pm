package Iptv::Microimpuls;

=head1 NAME

=cut

#**********************************************************

use strict;
use warnings FATAL => 'all';

our $VERSION = 0.9;

use parent qw(dbcore);
use Abills::Base qw(load_pmodule mk_unique_value in_array urlencode convert _bp);
use Abills::Fetcher;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64;

my $MODULE = 'Microimpuls';

my ($admin, $CONF, $db);
my $json;
my Abills::HTML $html;
my $lang;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $admin->{MODULE} = $MODULE;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{public_key} = $attr->{LOGIN} || q{};
  $self->{private_key} = $attr->{PASSWORD} || q{};
  $self->{URL} = $attr->{URL} || "";
  $self->{debug} = $attr->{DEBUG};
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $result = $self->_send_request({
    ACTION => '/customer/info/',
  });

  if (!$self->{errno} && ref $result eq 'HASH') {
    $result = 'Ok';
  }
  else {
    $self->{errno} = 1005;
    $result = 'Unknown Error';
  }

  return $result;
}

#**********************************************************
=head2 _send_request($attr)

=cut
#**********************************************************
sub _send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{URL} || '';
  my $public_key = $self->{public_key} || 'f77da74c6b626400382c7bf96ca7902b5a244610';
  my $private_key = $self->{private_key} || '0f87ffe97757ee3cbd1e22b81d7bfa6f71e1c587';

  my $debug = (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug};
  if ($self->{DEBUG_FILE} && $debug < 2) {
    $debug = 2;
  }

  if ($attr->{ACTION}) {
    $request_url .= $attr->{ACTION};
  }

  my $message = ();
  if ($attr->{PARAMS}) {
    foreach my $key (keys %{$attr->{PARAMS}}) {

      if ($message) {
        $message .= '&' . ($key || q{}) . '=' . $attr->{PARAMS}->{$key};
      }
      else {
        $message = $key . '=' . ($attr->{PARAMS}->{$key} || q{});
      }
    }
  }

  my $api_time = time();
  my $hmac_text = $api_time . $public_key . ($message || '');
  my $api_hash = hmac_sha256_hex($hmac_text, $private_key);

  my @params = ();
  $params[0] = 'API_ID: ' . $public_key;
  $params[1] = 'API_TIME: ' . $api_time;
  $params[2] = 'API_HASH: ' . $api_hash;

  my $result = web_request($request_url,
    {
      DEBUG      => 4,
      HEADERS    => \@params,
      POST       => ($message || '""'),
      DEBUG      => $debug,
      DEBUG2FILE => $self->{DEBUG_FILE},
      CURL       => 1,
    }
  );

  my $perl_scalar;
  if ($result =~ /\{/) {
    $perl_scalar = $json->decode($result);
  }
  else {
    $perl_scalar->{errno} = 10;
    $perl_scalar->{err_str} = $result;
    $self->{errno} = 100;
    $self->{error} = 100;
    $self->{errstr} = $result;
  }

  return $perl_scalar;
}

#**********************************************************
=head2 user_info($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
  });

  my $result = $self->_send_request({
    ACTION => '/customer/info',
    PARAMS => {
      signature => $attr->{SIGNATURE} || $signature || '',
      ext_id    => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 account_info($attr)

   Arguments:
     $attr
       ID

   Results:
     $self->
       {RESULT}->{results}

=cut
#**********************************************************
sub account_info {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
    abonement => $attr->{ext_id} || 0,
  });

  my $result = $self->_send_request({
    ACTION => '/account/info',
    PARAMS => {
      signature => $attr->{SIGNATURE} || $signature || '',
      ext_id    => $attr->{ext_id} || 0,
      abonement => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  $self->{RESULT}->{results} = [ $result ];

  return $self;
}

#**********************************************************
=head2 user_add($attr)

   Arguments:
     $attr
       ID
       TP_ID,
       FILTER_ID
       TP_FILTER_ID

   Results:

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{TP_ID}) {
    $self->{errno} = '10100';
    $self->{errstr} = 'ERR_SELECT_TP';
    return $self;
  }

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $result = user_info($self, {
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} && $result->{RESULT}{results}[0]{error} eq '1') {
    $signature = _shaping_signature({
      client_id => $CONF->{MICROIMPULS_CLIENT_ID},
      comment   => $attr->{UID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    $result = $self->_send_request({
      ACTION => '/customer/create',
      PARAMS => {
        signature => $signature,
        ext_id    => $attr->{UID} || 0,
        comment   => $attr->{UID} || 0,
        client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      },
    });

    if ($result->{error} eq '0') {
      $signature = _shaping_signature({
        client_id                 => $CONF->{MICROIMPULS_CLIENT_ID},
        password                  => $attr->{PASSWORD} || '',
        parent_code               => $attr->{PIN} || 0,
        ext_id                    => $attr->{UID} || 0,
        abonement                 => $attr->{UID} || 0,
        active                    => 1,
        status_reason             => "ACTIVE",
        allow_login_by_device_uid => 1,
      });

      $result = _account_add($self, {
        password      => $attr->{PASSWORD} || '',
        parent_code   => $attr->{PIN} || 0,
        ext_id        => $attr->{UID} || 0,
        active        => 1,
        status_reason => 'ACTIVE',
        abonement     => $attr->{UID} || 0,
        signature     => $signature,
      });

      $result = account_info($self, {
        ext_id    => $attr->{UID} || 0,
        client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
        signature => $signature,
      });

      if (! $result->{RESULT}{results}[0]{abonement}) {
        $result = _account_add($self, {
          password      => $attr->{PASSWORD} || '',
          parent_code   => $attr->{PIN} || 0,
          ext_id        => $attr->{UID} || 0,
          active        => 1,
          status_reason => 'ACTIVE',
          abonement     => $attr->{UID} || 0,
          signature     => $signature,
        });
      }

      if (!$result->{RESULT}{results}[0]{error} && !$result->{RESULT}{results}[0]{error} eq '1') {
        $result = _customer_tariff_assign($self, {
          tariff_id => $attr->{TP_FILTER_ID} || 0,
          ext_id    => $attr->{UID} || 0,
        });
      }
    }
  }
  else {
    my @Tarrifs = $result->{RESULT}{results}[0]{tariffs};

    if (!in_array($attr->{TP_FILTER_ID}, @Tarrifs)) {
      my $reslut = _customer_tariff_assign($self, {
        tariff_id => $attr->{TP_FILTER_ID} || 0,
        ext_id    => $attr->{UID} || 0,
      });
    }
  }

  return $self;
}


#**********************************************************
=head2 user_del($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $result = user_info($self, {
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} eq '0') {
    my $Tarrifs = $result->{RESULT}{results}[0]{tariffs};
    my $elements = @$Tarrifs;

    if ($elements > 1) {
      _customer_tariff_remove($self, {
        tariff_id => $attr->{TP_FILTER_ID},
        ext_id    => $attr->{UID} || 0,
      });
    }
    else {
      $result = $self->_send_request({
        ACTION => '/customer/delete',
        PARAMS => {
          signature => $signature,
          ext_id    => $attr->{UID} || 0,
          client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
        },
      });
    }
  }
  else {
    $self->{errno} = '1';
    $self->{errstr} = 'Data Dissynchronization Microimpuls <=> Abills';
    return $self;
  }

  return $self;
}

#**********************************************************
=head2 user_change($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{UID} || 0,
  });

  my $result = user_info($self, {
    ext_id    => $attr->{UID} || 0,
    client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    signature => $signature,
  });

  if ($result->{RESULT}{results}[0]{error} eq '0') {
    my $Tarrifs = $result->{RESULT}{results}[0]{tariffs} || ();

    foreach my $tarrif (@$Tarrifs) {
      _customer_tariff_remove($self, {
        tariff_id => $tarrif,
        ext_id    => $attr->{UID} || 0,
        signature => $signature,
      });
    }

    _customer_tariff_assign($self, {
      tariff_id => $attr->{TP_FILTER_ID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    if ($attr->{STATUS} eq '0') {
      $signature = _shaping_signature({
        client_id     => $CONF->{MICROIMPULS_CLIENT_ID},
        active        => 1,
        abonement     => $attr->{UID} || 0,
        status_reason => "ACTIVE",
      });

      _account_modify_status($self, {
        active        => 1,
        abonement     => $attr->{UID} || 0,
        status_reason => "ACTIVE",
        signature     => $signature,
      });
    }
    elsif ($attr->{STATUS} eq '1') {
      $signature = _shaping_signature({
        client_id     => $CONF->{MICROIMPULS_CLIENT_ID},
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "INACTIVE",
      });

      _account_modify_status($self, {
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "INACTIVE",
        signature     => $signature,
      });
    }
    elsif ($attr->{STATUS} eq '3') {
      $signature = _shaping_signature({
        client_id     => $CONF->{MICROIMPULS_CLIENT_ID},
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "BLOCK",
      });

      _account_modify_status($self, {
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "BLOCK",
        signature     => $signature,
      });
    }
    elsif ($attr->{STATUS} eq '5') {
      $signature = _shaping_signature({
        client_id     => $CONF->{MICROIMPULS_CLIENT_ID},
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "DEBT",
      });

      _account_modify_status($self, {
        active        => 0,
        abonement     => $attr->{UID} || 0,
        status_reason => "DEBT",
        signature     => $signature,
      });
    }

    if ($attr->{PIN} ne '') {
      $signature = _shaping_signature({
        client_id   => $CONF->{MICROIMPULS_CLIENT_ID},
        parent_code => $attr->{PIN},
        abonement   => $attr->{UID} || 0,
      });

      _account_modify_pin($self, {
        parent_code => $attr->{PIN},
        abonement   => $attr->{UID} || 0,
        signature   => $signature,
      });
    }

  }
  else {
    $self->{errno} = '1';
    $self->{errstr} = 'Data Dissynchronization Microimpuls <=> Abills';

    my $status_reason = $attr->{STATUS} eq "0" ? "ACTIVE" : $attr->{STATUS} eq "1" ? "INACTIVE" : $attr->{STATUS} eq "3" ?
      "BLOCK" : $attr->{STATUS} eq "5" ? "DEBT" : "ACTIVE";
    my $active = $attr->{STATUS} eq "0" ? "1" : $attr->{STATUS} eq "1" ? "0" : $attr->{STATUS} eq "3" ? "0" : $attr->{STATUS} eq "5" ? "0" : "1";

    $signature = _shaping_signature({
      client_id => $CONF->{MICROIMPULS_CLIENT_ID},
      comment   => $attr->{UID} || 0,
      ext_id    => $attr->{UID} || 0,
    });

    $result = $self->_send_request({
      ACTION => '/customer/create',
      PARAMS => {
        signature => $signature,
        ext_id    => $attr->{UID} || 0,
        comment   => $attr->{UID} || 0,
        client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      },
    });

    if ($result->{error} eq '0') {
      $signature = _shaping_signature({
        client_id                 => $CONF->{MICROIMPULS_CLIENT_ID},
        password                  => $attr->{PASSWORD} || '',
        parent_code               => $attr->{PIN} || 0,
        ext_id                    => $attr->{UID} || 0,
        abonement                 => $attr->{UID} || 0,
        active                    => $active,
        status_reason             => $status_reason,
        allow_login_by_device_uid => 1,
      });

      $result = _account_add($self, {
        password      => $attr->{PASSWORD} || '',
        parent_code   => $attr->{PIN} || 0,
        ext_id        => $attr->{UID} || 0,
        abonement     => $attr->{UID} || 0,
        status_reason => $status_reason,
        active        => $active,
        signature     => $signature,
      });

      if ($result->{RESULT}{results}[0]{error} && $result->{RESULT}{results}[0]{error} eq '1') {
        _customer_tariff_assign($self, {
          tariff_id => $attr->{TP_FILTER_ID} || 0,
          ext_id    => $attr->{UID} || 0,
          signature => $signature,
        });
      }
    }

    return $self;
  }

  return $self;
}

#**********************************************************
=head2 _shaping_signature($attr)

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub _shaping_signature {
  my ($attr) = @_;

  my $Signature = '';

  foreach my $key (sort keys %{$attr}) {
    $Signature .= $key . ':' . $attr->{$key} . ";";
  }

  $Signature .= $CONF->{MICROIMPULS_API_KEY};

  my $md5 = Digest::MD5->new();

  $Signature = encode_base64($Signature);
  $Signature =~ s/[\s]//g;
  $md5->reset;
  $md5->add($Signature);
  $Signature = $md5->hexdigest;

  return $Signature;
}

#**********************************************************
=head2 _account_add($attr)

  Arguments:
    $attr
      signature
      password
      parent_code
      ext_id
      abonement

  Results:

=cut
#**********************************************************
sub _account_add {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/account/create',
    PARAMS => {
      ext_id                    => $attr->{ext_id} || 0,
      password                  => $attr->{password} || '',
      parent_code               => $attr->{parent_code} || 0,
      abonement                 => $attr->{ext_id} || 0,
      active                    => $attr->{active} eq '0' ? 0 : 1,
      status_reason             => $attr->{status_reason} || "ACTIVE",
      allow_login_by_device_uid => 1,
      client_id                 => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature                 => $attr->{signature} || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _account_modify($attr)

  Arguments:
    $attr
      signature
      abonement
      active
      status_reason

  Results:

=cut
#**********************************************************
sub _account_modify_status {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/account/modify',
    PARAMS => {
      abonement     => $attr->{abonement} || 0,
      active        => $attr->{active} || 0,
      status_reason => $attr->{status_reason},
      client_id     => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature     => $attr->{signature} || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _account_modify_pin($attr)

  Arguments:
    $attr
      signature
      parent_code
      abonement

  Results:

=cut
#**********************************************************
sub _account_modify_pin {
  my $self = shift;
  my ($attr) = @_;

  $self->_send_request({
    ACTION => '/account/modify',
    PARAMS => {
      abonement   => $attr->{abonement} || 0,
      parent_code => $attr->{parent_code} || 0,
      client_id   => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
      signature   => $attr->{signature} || '',
    },
  });

  return $self;
}

#**********************************************************
=head2 _customer_tariff_assign($attr)

  Arguments:
    $attr
      signature
      tarif_id
      ext_id

  Results:

=cut
#**********************************************************
sub _customer_tariff_assign {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
    tariff_id => $attr->{tariff_id} || 0,
  });

  my $result = $self->_send_request({
    ACTION => '/customer/tariff/assign',
    PARAMS => {
      signature => $signature,
      tariff_id => $attr->{tariff_id} || 0,
      ext_id    => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  return $self;
}

#**********************************************************
=head2 _customer_tariff_remove($attr)

  Arguments:
    $attr
      signature
      tarif_id
      ext_id

  Results:

=cut
#**********************************************************
sub _customer_tariff_remove {
  my $self = shift;
  my ($attr) = @_;

  my $signature = _shaping_signature({
    client_id => $CONF->{MICROIMPULS_CLIENT_ID},
    ext_id    => $attr->{ext_id} || 0,
    tariff_id => $attr->{tariff_id} || 0,
  });

  $self->_send_request({
    ACTION => '/customer/tariff/remove',
    PARAMS => {
      signature => $signature,
      tariff_id => $attr->{tariff_id} || 0,
      ext_id    => $attr->{ext_id} || 0,
      client_id => $CONF->{MICROIMPULS_CLIENT_ID} || 0,
    },
  });

  return $self;
}

1;