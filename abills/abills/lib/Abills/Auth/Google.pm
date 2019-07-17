package Abills::Auth::Google;

=head1 NAME

  Google OAuth module

=cut

use strict;
use warnings FATAL => 'all';

# "win2utf8" is not exported by the Abills::Base module
use Abills::Base qw(urlencode mk_unique_value _bp show_hash load_pmodule);
#use Abills::Base;

use Abills::Fetcher;

my $auth_endpoint_url = 'https://accounts.google.com/o/oauth2/v2/auth';
my $access_token_url = 'https://www.googleapis.com/oauth2/v4/token';
my $get_me_url = 'https://www.googleapis.com/userinfo/v2/me';
my $get_public_info_url = 'https://www.googleapis.com/plus/v1/people/';

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;
  
  my $client_id = $self->{conf}->{AUTH_GOOGLE_ID} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_GOOGLE_URL} || q{};
  $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;
  $self->{debug} = $self->{conf}->{AUTH_GOOGLE_DEBUG} || 0;
  
  my $redirect_encoded = urlencode($redirect_uri);
  
  if ( $self->{debug} ) {
    print "Content-Type: text/html\n\n";
  }
  
  if ( !exists $attr->{code} ) {
    # Form redirect_url;
    my $session_state = mk_unique_value(10);
    $self->{auth_url} = join('', "$auth_endpoint_url?",
      "&response_type=code",
      "&client_id=$client_id",
      "&redirect_uri=$redirect_encoded",
      "&scope=profile",
      "&access_type=offline",
      "&state=$session_state",
    );
    
    return $self;
  }
  else {
    my $token = $self->get_token( $attr->{code} );
    if ( defined $token ) {
      my $user_info = $self->get_info( { TOKEN => $token } );
      
      if ( $user_info->{name} ) {
        $self->{USER_ID} = 'google, ' . $user_info->{id};
        $self->{USER_NAME} = $user_info->{name};
        $self->{CHECK_FIELD} = '_GOOGLE';
      }
    }
    else {
      _bp('Error getting token');
    }
  }
  
  return $self;
}


#**********************************************************
=head2  get_token() - Get token

=cut
#**********************************************************
sub get_token {
  my $self = shift;
  my ($code) = @_;
  
  my $token = '';
  
  my $client_id = $self->{conf}->{AUTH_GOOGLE_ID} || q{};
  my $client_secret = $self->{conf}->{AUTH_GOOGLE_SECRET} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_GOOGLE_URL} || q{};
  $redirect_uri =~ s/\%SELF_URL\%/$self->{self_url}/g;
  my $redirect_encoded = urlencode($redirect_uri);
  
  my $post_params = join('',
    "code=$code",
    "&client_id=$client_id",
    "&client_secret=$client_secret",
    "&redirect_uri=$redirect_encoded",
    '&grant_type=authorization_code'
  );
  
  my $result = web_request($access_token_url, {
      POST        => $post_params,
      HEADERS     => [ 'Content-Type: application/x-www-form-urlencoded' ],
      JSON_RETURN => 1,
      DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
    }
  );
  
  _bp('Result', $result) if ($self->{debug});
  
  if ( $result->{access_token} ) {
    print "Ok <br/>" if ( $self->{debug} );
    return $result;
  }
  elsif ( $result->{error} ) {
    print "Error getting token: $result->{error} <br/>" if ( $self->{debug} );
    $token = undef;
  }
  
  return $token;
}

#**********************************************************
=head2 get_info($attr)

  Unless OAuth token specified will show public available info from Google+;

  Arguments:
   CLIENT_ID|TOKEN - Google services ID or OAuth 2.0 Token

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr) = @_;
  
  my $token = $attr->{TOKEN};
  my $client_id = $attr->{CLIENT_ID};
  
  my $api_key = $self->{conf}->{GOOGLE_API_KEY};
  $self->{debug} = $self->{conf}->{AUTH_GOOGLE_DEBUG} || 0;
  
  my $result = '';
  
  if ( !defined $token ) {
    
    return { "Error", 'Undefined $conf{GOOGLE_API_KEY}' } unless (defined $api_key);
    $result = web_request($get_public_info_url . $client_id . "?key=$api_key", {
        GET         => 1,
        JSON_RETURN => 1,
        JSON_UTF8   => 1,
        DEBUG       => ($self->{debug} && $self->{debug} > 2) ? 2 : 0,
        DEBUG2FILE  => ($self->{debug} && $self->{debug} > 4) ? '/tmp/abills_google_auth.log' : 0,
      });
    
  }
  else {
    my $token_type = $token->{token_type} || '';
    my $access_token = $token->{access_token} || '';
    
    $result = web_request($get_me_url, {
        HEADERS     => [ "Authorization: $token_type $access_token" ],
        JSON_RETURN => 1,
        JSON_UTF8   => 1,
        DEBUG       => ($self->{debug} && $self->{debug} > 2) ? 2 : 0,
        DEBUG2FILE  => ($self->{debug} && $self->{debug} > 4) ? '/tmp/abills_google_auth.log' : 0,
      });
  };
  
  return 0 unless $result;
  
  if ( $result->{error} ) {
    show_hash($result->{error});
    $self->{errno} = $result->{error}->{code};
    $self->{errstr} = $result->{error}->{message};
  }

  $self->{result} = $result;
  
  return $result;
}

1;
