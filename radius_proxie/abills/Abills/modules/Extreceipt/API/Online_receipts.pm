=head1 NAME

  Модуль взаимодействия с сервисом "Чеки-Онлайн"

=cut


package Online_receipts;
use strict;
use warnings FATAL => 'all';

use Digest::MD5 qw(md5_hex);
use JSON;
use utf8 qw/encode/;
use Abills::Base qw(_bp);

my $api_url = '';
my $debug = 0;


#**********************************************************
=head2 new($app_id, $secret)

=cut
#**********************************************************
sub new {
  my ($class, $conf) = @_;

  $debug   = 1;
  $api_url = $conf->{EXTRECEIPT_API_URL};
  
  my $self = {
    APP_ID  => $conf->{EXTRECEIPT_APP_ID},
    SECRET  => $conf->{EXTRECEIPT_SECRET},
    author  => $conf->{EXTRECEIPT_AUTHOR},
    goods   => $conf->{EXTRECEIPT_GOODS_NAME},
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init {
  my $self = shift;

  my %data = (
    nonce => $self->get_nonce(),
    app_id => $self->{APP_ID}
  );
  my $sign  = $self->get_sign(\%data);
  my $query = $self->make_query(\%data);

  my $params = qq/-H "sign: $sign"/;
  my $url = $api_url . "Token?" . $query;
  my $result = `curl -s "$url" $params`;

  my $perl_hash = decode_json($result);
  if ($self->{debug}) {
    print "CMD: curl -s '$url' $params\n";
    print "RESULT: $result\n";
  }

  $self->{TOKEN} = $perl_hash->{token};

  return 0 unless ($self->{TOKEN});
  
  return 1;
}

#**********************************************************
=head2 payment_register($attr)
  Регистрирует платеж в онлайн-кассе
=cut
#**********************************************************
sub payment_register {
  my $self = shift;
  my ($attr) = @_;

  if ($debug) {
    print "\nTry \\printCheck for payment $attr->{payments_id}\n";
  }
  
  my %data = (
    nonce          => $self->get_nonce(),
    app_id         => $self->{APP_ID},
    token          => $self->{TOKEN},
    type           => "printCheck",
    command => {
      smsEmail54FZ   => ($attr->{phone} || $attr->{mail} || ''),
      payed_cash     => '0',
      payed_cashless => $attr->{sum},
      author         => $self->{author},
      c_num          => $attr->{payments_id},
      goods  => [{
        count => 1,
        price => $attr->{sum},
        sum   => $attr->{sum},
        name  => $self->{goods},
        # nds_value       => 0, 
        nds_not_apply   => 'true',
      }]
    }
  );

  my $sign  = $self->get_sign(\%data);
  my $p_data = $self->perl2json(\%data);

  my $params = qq(-d '$p_data' -H "sign: $sign" -H "Content-Type: application/json");
  my $url = $api_url . "Command";
  my $result = `curl $params -s -X POST "$url"`;
  my $perl_hash = decode_json($result);
  if ($debug) {
    print "CMD: curl $params -s -X POST '$url'\n";
    print "RESULT: $result\n";
  }

  return $perl_hash->{command_id} || 0;
}

#**********************************************************
=head2 get_info($id)
  Получает информацию по ранее зарегистрированному платежу
=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($command_id) = @_;

  my %data = (
    nonce  => $self->get_nonce(),
    app_id => $self->{APP_ID},
    token  => $self->{APP_ID},
  );
  my $sign  = $self->get_sign(\%data);
  my $query = $self->make_query(\%data);

  my $params = qq/-H "sign: $sign"/;
  my $url = $api_url . "Command/$command_id?" . $query;
  my $result = `curl -s '$url' $params`;
  if ($debug) {
    print "CMD: curl -s '$url' $params\n";
    print "RESULT: $result\n";
  }
  my $perl_hash = decode_json($result);

  if ($perl_hash->{fiscal_document_number} && $perl_hash->{fiscal_document_attribute} && $perl_hash->{receipt_datetime}) {
    return ($perl_hash->{fiscal_document_number}, $perl_hash->{fiscal_document_attribute}, $perl_hash->{receipt_datetime});
  }

  return (0, 0, 0);
}

#**********************************************************
=head2 get_sign($attr)

=cut
#**********************************************************
sub get_sign {
  my $self = shift;
  my ($data) = @_;

  my $json_str = $self->perl2json($data);
  my $data_str = $json_str . $self->{SECRET};
  my $sign = md5_hex($data_str);

  return $sign;
}

#**********************************************************
=head2 get_nonce()

=cut
#**********************************************************
sub get_nonce {
  return "salt_" . int(rand(100000000));
}

#**********************************************************
=head2 make_query()

=cut
#**********************************************************
sub make_query {
  my $self = shift;
  my ($data) = @_;
  my $query_str = "";

  foreach my $key (sort keys %$data) {
    $query_str .= "&" if ($query_str);
    $query_str .= "$key=$data->{$key}";
  }

  return $query_str;
}

#**********************************************************
=head2 perl2json()

=cut
#**********************************************************
sub perl2json {
  my $self = shift;
  my ($data) = @_;
  my @json_arr = ();

  if (ref $data eq 'ARRAY') {
    foreach my $key (@{$data}) {
      push @json_arr, $self->perl2json($key);
    }
    return '[' . join(',', @json_arr) . "]";
  }
  elsif (ref $data eq 'HASH') {
    foreach my $key (sort keys %$data) {
      my $val = $self->perl2json($data->{$key});
      push @json_arr, qq{\"$key\":$val};
    }
    return '{' . join(',', @json_arr) . "}";
  }
  else {
    $data //='';
    # print "$data\n";
    # if ($data =~ '^[0-9]+$') {
    #   return qq{$data};
    # }
    # else {
      return qq{\"$data\"};
    # }
  }
}

#**********************************************************
=head2 payment_cancel($attr)
  Регистрирует отмену чека в онлайн-кассе
=cut
#**********************************************************
sub payment_cancel {
  my $self = shift;
  my ($attr) = @_;

  if ($debug) {
    print "\nTry \\printPurchaseReturn for payment $attr->{payments_id}\n";
  }
  
  my %data = (
    nonce          => $self->get_nonce(),
    app_id         => $self->{APP_ID},
    token          => $self->{TOKEN},
    type           => "printPurchaseReturn",
    command => {
      smsEmail54FZ   => ($attr->{phone} || $attr->{mail} || ''),
      payed_cash     => '0',
      payed_cashless => $attr->{sum},
      author         => $self->{author},
      c_num          => "n" . $attr->{payments_id},
      goods  => [{
        count => 1,
        price => $attr->{sum},
        sum   => $attr->{sum},
        name  => $self->{goods},
        nds_not_apply   => 'true',
      }]
    }
  );

  my $sign  = $self->get_sign(\%data);
  my $p_data = $self->perl2json(\%data);

  my $params = qq(-d '$p_data' -H "sign: $sign" -H "Content-Type: application/json");
  my $url = $api_url . "Command";
  my $result = `curl $params -s -X POST "$url"`;
  my $perl_hash = decode_json($result);
  if ($debug) {
    print "CMD: curl $params -s -X POST '$url'\n";
    print "RESULT: $result\n";
  }

  return $perl_hash->{command_id} || 0;
}


#**********************************************************
=head2 test()
  Тест подключения
=cut
#**********************************************************
sub test {
  my $self = shift;
  my ($attr) = @_;
  return 1;
}





1