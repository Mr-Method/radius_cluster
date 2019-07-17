package Abills::Sender::Push;
use strict;
use warnings;

use parent 'Abills::Sender::Plugin';

BEGIN {
  unshift @INC, "../../";
};

use Abills::Fetcher;
use Abills::Base qw/_bp mk_unique_value/;

# Needed only until no encryption
use Abills::SQL;
use Admins;
use Contacts;

use MIME::Base64;
use JSON;

#use Crypt::Random;
#
#use Crypt::PK::ECC;
#use Crypt::GCM;
#use Crypt::Rijndael;

#use Digest::HMAC;
#use Digest::SHA;

my JSON $json = JSON->new->utf8( 0 );

_bp('', '', {SET_ARGS => {TO_CONSOLE => 1}});

#our $base_dir;
#$base_dir ||= '/usr/abills';

#**********************************************************
=head2 new($conf) - constructor for GCM_PUSH

  Attributes:
    $conf

  Returns:
    object - new GCM_PUSH instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf) = @_;
  
  return 0 unless ($conf->{PUSH_ENABLED});
  
  my $self = {
    auth_key => $conf->{GOOGLE_API_KEY}
  };
  
  die 'Undefined $conf{GOOGLE_API_KEY}' if (!$self->{auth_key});
  
  $self->{db} = Abills::SQL->connect($conf->{dbtype}, $conf->{dbhost}, $conf->{dbname}, $conf->{dbuser}, $conf->{dbpasswd},
    { CHARSET => ($conf->{dbcharset}) ? $conf->{dbcharset} : undef });
  $self->{admin} = Admins->new($self->{db}, $conf);
  $self->{admin}->info($conf->{SYSTEM_ADMIN_ID} || '2', { IP => '127.0.0.1' });
  $self->{Contacts} = Contacts->new($self->{db}, $self->{admin}, $conf);
  
  bless( $self, $class );
  return $self;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr - hash_ref
      UID        - user ID
      MESSAGE    - string. CANNOT CONTAIN DOUBLE QUOTES \"
      TO_ADDRESS - Push endpoint

  Returns:
    1 if success, 0 otherwise

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;
  
  # Return if client is not registered
  return 0 unless (defined $attr->{TO_ADDRESS} && defined $attr->{MESSAGE});
  
  my $contact = $attr->{CONTACT};
#  my ($sendpoint, $key, $auth) = split(/\|\|/, $attr->{TO_ADDRESS}, 3);
  
#  $attr->{TO_ADDRESS}    = $sendpoint;
#  $attr->{CLIENT_PUBLIC} = $key;
#  $attr->{CLIENT_AUTH}   = $auth;

  # Multiple
  my $sent = 0;
  if (ref $contact eq 'ARRAY') {
    my @endpoints = split(',\s?', $attr->{TO_ADDRESS});
    for my $i ( 0 ... $#endpoints ) {
      $sent = 1 if ($self->send_single($endpoints[$i], $contact->[$i]{id}, $attr));
    }
  }
  else {
    $sent = $self->send_single($attr->{TO_ADDRESS}, $contact->{id}, $attr);
  }
  
}

#**********************************************************
=head2 send_single($endpoint, $contact_id, $attr) -

  Arguments:
    $endpoint   - string, special url linked to client device (browser)
    $contact_id - int, ID of contact for this device
    $attr       - hash_ref
    
  Push works in two steps
  Server sends client 'Push', so he knows there's something on server for him
  Client goes to server and fetches messages
  
  So here is algoritm
  Send 'Push' to client. If Push Service tells us, everything is ok, and 'Push' will be delivered to client,
  save message to DB, so client can fetch it later
  
=cut
#**********************************************************
sub send_single {
  my ($self, $endpoint, $contact_id, $attr) = @_;
  
  my $result = ($endpoint =~ 'google')
    ? $self->send_to_gcm($attr)
    : $self->send_to_firefox($attr);
  
  if ( $result ) {
    my Contacts $Contacts = $self->{Contacts};
    
    $Contacts->push_messages_add({
      CONTACT_ID => $contact_id,
      MESSAGE    => $attr->{MESSAGE},
      TITLE      => $attr->{TITLE} || '',
      TAG        => $attr->{TAG} || 'message',
      %{ $attr }
    });
  }
  
  return $result;
};

#**********************************************************
=head2 send_to_firefox($attr) - Sends message to Firefox anypush server

  Arguments:
    $attr -
    
  Returns:
    1
    
=cut
#**********************************************************
sub send_to_firefox {
  my ($self, $attr, $data) = @_;
  
  my $push_data = $json->encode( {
    data             => {
      message => 'Push'
    },
    'time_to_live'   => 600
  } );
  $push_data =~ s/"/\\\"/g;
  
  my $result = web_request( $attr->{TO_ADDRESS}, {
      CURL_OPTIONS => '-XPOST',
      HEADERS => [
        "TTL:86400"
      ],
      DEBUG   => $attr->{DEBUG}
    } );
  
  # Normal result is empty responce
  
  return $result eq '';
}

#**********************************************************
=head2 send_to_gcm($attr) - Sends Push message to Google Cloud Messaging

  Arguments:
    $attr -
    
  Returns:
  
  
=cut
#**********************************************************
sub send_to_gcm {
  my ($self, $attr, $data) = @_;
  
  my @endpoint_sections = split('/', $attr->{TO_ADDRESS});
  my $client_id = pop @endpoint_sections;
  my $server_url = join('/', @endpoint_sections);
  
  my $gcm_data = $json->encode( {
    registration_ids => [ $client_id ],
    data             => {
     message => undef
    },
    'time_to_live'   => 86400
  } );
  $gcm_data =~ s/"/\\\"/g;
  
  my $result = web_request( $server_url, {
      POST    => $gcm_data,
      HEADERS => [
        "Authorization:key=$self->{auth_key}",
        "TTL:86400",
        "Content-Type:application/json"
      ],
      DEBUG   => $attr->{DEBUG}
    } );
  
  # Check answer
  if ( $result =~ /^{"/ ) {
    my $responce = $json->decode( $result );
    
    # Now should check result responce for errors
    if (!$responce->{success} && $responce->{failure}){
      
      my $results = $responce->{results};
      if ($results && ref $results eq 'ARRAY' && scalar @{$results}){
        
        my $error = $results->[0];
        if ( $error && ref $error eq 'HASH' && $error->{error} ){
          if ($error->{error} eq 'InvalidRegistration'){
            # TODO: remove contact
            print "Invalid registration \n";
          }
        }
      }
    }
    
    return $responce->{success};
  }
  elsif ( $result =~ /Unauthorized/ ) {
    print "\n\n AUTHORIZATION ERROR: Invalid \$conf{GOOGLE_API_KEY} key \n";
  }
  elsif ( $result =~ /InvalidTokenFormat/ ){
    print "\n\n PUSH ERROR: Invalid Token key \n";
  }
  
  return 0;
}

# Contacts save

#**********************************************************
=head2 register_client($attr)

  Arguments:
    $attr
      UID


  Returns:
    1
=cut
#**********************************************************
sub register_client {
  my ($self, $attr, $FORM) = @_;
  
  my $client_id = $attr->{UID} || $attr->{AID} || do {
    print qq{ {"result": "error", "message" : "No user given. Auth failed?"} };
    return 0;
  };
  my $type = ($attr->{UID}) ? '0' : '1';

  my Contacts $Contacts = $self->{Contacts};
  
  if ( $FORM->{unsubscribe} ) {
    my $result = 0;
  
    $Contacts->push_contacts_del({
      TYPE      => $type,
      CLIENT_ID => $client_id,
      ID        => $FORM->{CONTACT_ID}
    });
    
    my $result_str = !$self->{Contacts}->{errno} ? 'ok' : 'error';
    print qq{ {"result": "$result_str", "id" : "$client_id", "registration_id" : "unsubscribe"} };
    return $result;
  }
  
  my $reg_id = $FORM->{ENDPOINT};
  
  if ( !defined $reg_id ) {
    print qq{ {"result": "error", "message" : "No required args : ENDPOINT "} };
    return 0;
  };
  
  
  # First check we don't have same endpoint in table
  my $new_contact_id = undef;
  my $contacts_with_this_reg_id = $Contacts->push_contacts_list({
    CLIENT_ID => $client_id,
    ENDPOINT  => $reg_id,
    #    AUTH      => $FORM{AUTH},
  });
  
  if ($contacts_with_this_reg_id && ref $contacts_with_this_reg_id eq 'ARRAY' && scalar @$contacts_with_this_reg_id > 0){
    $new_contact_id = $contacts_with_this_reg_id->[0]{id};
  }
  else {
    $new_contact_id = $Contacts->push_contacts_add({
      TYPE      => $type,
      CLIENT_ID => $client_id,
      ENDPOINT  => $reg_id,
      #    AUTH      => $FORM{AUTH},
      #    KEY       => $FORM{KEY}
    });
  }
  
  my $result_str = !$self->{Contacts}->{errno} ? 'ok' : 'error';
  print qq{ {"result": "$result_str", "id" : "$client_id", "contact_id" : "$new_contact_id"} };
  
  return 1;
}

#**********************************************************
=head2 message_request($contact_id)

# Message_request

=cut
#**********************************************************
sub message_request {
  my ($self, $contact_id) = @_;
  
  return 0 unless ($contact_id);
  
  my $messages = $self->{Contacts}->push_messages_list({
    CONTACT_ID => $contact_id,
    ID         => '_SHOW',
    MESSAGE    => '_SHOW',
    TITLE      => '_SHOW',
    SORT       => 'created'
  });
  
  if ( $self->{errno} ) {
    print qq{ { "error" : "error retrieving messages", "reason" : "$self->{errstr}", "errno" : "$self->{errno}" } };
    return 0;
  }
  elsif ( !$messages || ref $messages ne 'ARRAY' ) {
    print qq{ { "error" : "error retrieving messages", "reason" : "no messages" } };
    return 0;
  }
  
  my $icon = $self->{conf}->{PUSH_ICON} || '/img/abills-120x120.jpg';
  my @response_messages = map {
    
    {
      title   => $_->{title} // '',
      message => $_->{message} // '',
      icon    => $icon
    }
    
  } @{$messages};
  
  print $json->encode(\@response_messages);
  $self->{Contacts}->push_messages_del({ CONTACT_ID => $contact_id });
  
  return 1;
  
}

#  CONSERVED
#
##**********************************************************
#=head2 encrypt_message() -
#
#  Arguments:
#     -
#
#  Returns:
#
#
#=cut
##**********************************************************
#sub encrypt_json {
#  my ($self, $public_key_base64, $user_auth_base64, $data) = @_;
#
#  my $raw_client_public = decode_base64($public_key_base64);
#  my ($secret, $server_public, $server_private) = _get_shared_secret($raw_client_public);
#
#  my $header = "Content-Encoding: auth";
#  my $prk = _get_hdkf( $user_auth_base64, $secret, $header, 32 );
#
#  my $salt = '3kpNASasQUKL-Ipn';# mk_unique_value(16, { EXTRA_RULES => '2:2' });
#  _bp('salt', $salt, {TO_CONSOLE => 1});
#  my $content_encryption_info = _create_info('aesgcm', $public_key_base64, $server_public);
#  my $content_encryption_key = _get_hdkf( $salt, $prk, $content_encryption_info, 16);
#
#  my $nonceInfo = _create_info('nonce', $public_key_base64, $server_public);
#  my $nonce = _get_hdkf($salt, $prk, $nonceInfo, 12);
#
#  my $Gcm = Crypt::GCM->new( -key => $server_private, -cipher => 'Crypt::Rijndael' );
#  $Gcm->set_iv(pack 'H*', '000000000000000000000000');
#  $Gcm->aad('Hello, world!');
#
#  my $result = $Gcm->aad();
#
#  _bp('', {
#      SENDER_PUB64   => encode_base64($server_public),
#      SENDER_PRV   => encode_base64($server_private),
#      RECEIVER => $public_key_base64,
#      SALT     => encode_base64($salt),
#      AUTH     => $user_auth_base64,
#      RESULT   => $result
#    },
#    {
#      TO_CONSOLE => 1, EXIT => 1
#    });
#
#  my $return = {
#    PAYLOAD => $result,
#    HEADERS => [
#      'Encryption: salt=' . encode_base64($salt),
#      'Crypto-Key: dh=' . encode_base64($server_public),
#      'Content-Encoding: aesgcm',
#    ]
#  };
#
#  _bp('', $return, { TO_CONSOLE => 1 });
#
#  return $return;
#}
#
##**********************************************************
#=head2 _get_shared_secret($public_key) - ECDH shared secret calculated from client public key
#
#  Arguments:
#    $public_key - client public key
#
#  Returns:
#    hash_ref
#      SERVER_PUBLIC  - publick key for client to decrypt message
#      SECRET         - encoding secret
#
#=cut
##**********************************************************
#sub _get_shared_secret {
#  my ($client_public_key) = @_;
#
#  my $certs_dir = $base_dir . '/Certs';
#  my $private_cert = $certs_dir . '/ec-priv.pem';
#
#  my $pk = Crypt::PK::ECC->new();
#  if (-f $private_cert){
#    $pk->import_key($private_cert);
#  }
#  else {
#    $pk->generate_key('prime256v1');
#    open (my $pr_cert_fh, '>', $private_cert) or die "Can't save private cert : $!";
#    print ($pr_cert_fh $pk->export_key_pem('private'));
#    close $pr_cert_fh;
#  }
#
#  my $pkb = Crypt::PK::ECC->new();
#  $pkb->import_key_raw($client_public_key, 'prime256v1');
##  open (my $cl_pub_fh, '<',  unpack('H*', $client_public_key));
##  $pkb->import_key_raw($cl_pub_fh, 'prime256v1');
#
#  # Calculate shared secret
#  my $secret = $pk->shared_secret($pkb);
#
#  # Public key is exported in ANS X9.63
#  # To use it for Web Push, should transform it to raw bytes
#  #  my $public_ans = $pk->export_key_raw('public_uncompressed');
#  my $key_hash = $pk->key2hash();
#
#  my $public_ans = join('', map { pack('C', hex($_)) } (('04' . $key_hash->{pub_x} . $key_hash->{pub_y}) =~ /(..)/g));
#
#  return ( $secret, lc $public_ans, $pk->export_key_raw('private') );
#}
#
##**********************************************************
#=head2 _get_hdkf($salt, $initial_key_material, $info, $length) - returns HMAC-based Key Derivation Function
#
#  Simplified HKDF, returning keys up to 32 bytes long
#
#  Arguments:
#    $salt
#    $initial_key_material
#    $info
#    $length
#
#  Returns:
#    string - digest
#
#=cut
##**********************************************************
#sub _get_hdkf {
#  my ($salt, $initial_key_material, $info, $length) =  @_;
#
#  my $hmac = Digest::HMAC->new($salt, 'Digest::SHA', 256);
#  $hmac->add($initial_key_material);
#  my $key = $hmac->digest();
#
#  my $info_hmac = Digest::HMAC->new($key, 'Digest::SHA', 256);
#  $info_hmac->add($info);
#  $info_hmac->add(0x01);
#
#  return substr($info_hmac->digest, 0, $length);
#}
#
##**********************************************************
#=head2 _create_info($type, $client_public_key, $shared_secret, $server_public_info) -
#
#  Arguments:
#    $type               -
#    $client_public_key  -
#    $shared_secret      -
#    $server_public_info -
#
#  Returns:
#
#
#=cut
##**********************************************************
#sub _create_info {
#  my ($type, $client_public_key, $server_public_key) = @_;
#
#  my $len = length $type;
#  # The start index for each element within the buffer is:
#  # value               | length | start    |
#  # -----------------------------------------
#  # 'Content-Encoding: '| 18     | 0        |
#  # type                | len    | 18       |
#  # nul byte            | 1      | 18 + len |
#  # 'P-256'             | 5      | 19 + len |
#  # nul byte            | 1      | 24 + len |
#  # client key length   | 2      | 25 + len |
#  # client key          | 65     | 27 + len |
#  # server key length   | 2      | 92 + len |
#  # server key          | 65     | 94 + len |
#  # For the purposes of push encryption the length of the keys will
#  # always be 65 bytes.
#
#  my $info = pack(
#    "A18A$len" . 'xA5x' . 'S1' . 'A65' . 'S1' . 'A65',
#    'Content-Encoding:',
#    $type,
#    'P-256',
#    length $client_public_key,
#    $client_public_key,
#    length $server_public_key,
#    $server_public_key
#  );
#
#  return $info;
#}
1;