package Abills::Auth::Facebook;

=head1 NAME

  facebook.com auth module

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(_bp urlencode mk_unique_value load_pmodule show_hash);
use Abills::Fetcher;
use Encode;

my $access_token_url = 'https://graph.facebook.com/oauth/access_token';
#my $get_me_url       = 'https://graph.facebook.com/me';
my $get_me_url       = 'https://graph.facebook.com/';
# https://developers.facebook.com/docs/facebook-login/permissions#reference-user_likes
# read_stream
# user_hometown
my $facebook_scope   = 'public_profile,email,user_birthday,user_likes,user_friends,user_location,user_posts';

#**********************************************************
=head2  get_token() - Get token

=cut
#**********************************************************
sub get_token {
  my $self = shift;
  my $token = '';

  my $client_id    = $self->{conf}->{AUTH_FACEBOOK_ID} || q{};
  my $client_secret= $self->{conf}->{AUTH_FACEBOOK_SECRET} || q{};
  my $request      = qq($access_token_url?client_id=$client_id&client_secret=$client_secret&grant_type=client_credentials);

  my $result = web_request($request, {
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0,
    JSON_RETURN => 1,
  });

  if($self->{debug}) {
    print $result;
  }

  if($result->{access_token}) {
    $token = $result->{access_token};
  }
  else {
    load_pmodule('JSON');
    my $json = JSON->new->allow_nonref;

    my $result_pair;
    eval { $result_pair = $json->decode( $result );  };

    if($self->{debug}) {
      print "failed";
      show_hash($result_pair);
    }
  }

  return $token;
}

#**********************************************************
=head2 check_auth($attr)

  https://www.facebook.com/v2.3/dialog/oauth?client_id=546673382033765&response_type=code&redirect_uri=https%3A%2F%2Fmy.lanet.ua%2Flogin.php&state=facebook&scope=public_profile%2Cemail%2Cuser_birthday%2Cuser_likes%2Cuser_friends

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr)=@_;

  my $client_id    = $self->{conf}->{AUTH_FACEBOOK_ID} || q{};
  my $redirect_uri = $self->{conf}->{AUTH_FACEBOOK_URL} || q{};
  my $client_secret= $self->{conf}->{AUTH_FACEBOOK_SECRET} || q{};
  $self->{debug}   = $self->{conf}->{AUTH_FACEBOOK_DEBUG} || 0;
  $redirect_uri    =~ s/\%SELF_URL\%/$self->{self_url}/g;

  if($self->{domain_id}) {
    $redirect_uri .= "%26DOMAIN_ID=$self->{domain_id}";
  }
  if($attr->{user_registration}) {
    $redirect_uri .= "%26user_registration=$attr->{user_registration}";
  }

  if($self->{debug}) {
    print "Content-Type: text/html\n\n";
  }

  if ($attr->{code}) {
    my $request = qq($access_token_url?client_id=$client_id&client_secret=$client_secret&code=$attr->{code}&redirect_uri=$redirect_uri);
    my $result = web_request($request, {
      JSON_RETURN => 1,
      DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
    });

    if($self->{debug}) {
      print show_hash($result);
    }
    if($result->{access_token}) {
      my $token = $result->{access_token};
      if($self->{debug}) {
        print "Ok<br>";
      }

      $request = qq($get_me_url/me/?fields=id,name,email,hometown&access_token=$token);
      $result = web_request($request, {
        JSON_RETURN => 1,
        DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
      });

      if($self->{debug}) {
        print $request;
      }
      if ($result->{error}) {
        $self->{errno}=$result->{error}->{code};
        $self->{errstr}=$result->{error}->{message};
      }
      elsif ($result->{name}) {
        $self->{USER_ID}     = 'facebook, '.$result->{id};
        $self->{USER_NAME}   = $result->{name};
        $self->{EMAIL}       = $result->{email};
        $self->{CHECK_FIELD} = '_FACEBOOK';
      }
    }
    else {
      load_pmodule('JSON');
      my $json = JSON->new->allow_nonref;

      my $result_pair;
      eval { $result_pair = $json->decode( $result );  };
      if($result_pair->{error}) {
        $self->{errstr} = $result_pair->{error}->{message};
        $self->{errno}  = $result_pair->{error}->{code};
      }

      if($self->{debug}) {
        print "failed";
        show_hash($result_pair);
      }
    }

    #Return
    # {"access_token":"0cbc06819f523fdbbd7e593afbb63509e2b6df75504da82f6a0a6d98e5e69fcff9dc551f481d598df9edd","expires_in":86376,"user_id":22089814}
  }
  elsif($attr->{error_code}) {
    print "Content-Type: text/html\n\n";

#    [error] => access_denied
#    [error_code] => 200
#    [error_description] => Permissions error
#    [error_reason] => user_denied
#    [state] => 7262836fbd03301ee4d3291b15044ca6

    print ' '. ($attr->{error_code} || q{})
     . '<br>' . ($attr->{error_message} || q{})
     . '<br>' . ($attr->{state} || q{});
  }
  else {
    my $session_state = mk_unique_value(10);
    $self->{auth_url} = 'https://www.facebook.com/dialog/oauth'
      . '?client_id=' . $client_id
      . '&state=' . $session_state
      . '&scope=' . $facebook_scope
      . '&redirect_uri=' . $redirect_uri;
  }

  return $self;
}

#**********************************************************
=head2 get_info($attr)

  Arguments:
   CLIENT_ID

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub get_info {
  my $self = shift;
  my ($attr)=@_;
  my %info_fiealds = (
    ID       => 'id',
    NAME     => 'name',
    ABOUT    => 'about',
    BIRTHDAY => 'birthday',
    FIRT_NAME=> 'first_name',
    LAST_NAME=> 'last_name',
    GENDER   => 'gender',
    COVER    => 'cover',
    LOCATION => 'location',
    LOCALE   => 'locale',
    EMAIL    => 'email',
    HOMETOWN => 'hometown',
    EDUCATION=> 'education',
    FRIENDS  => 'friends',
    LIKES    => 'likes',
    FEED     => 'feed',
    EGA_RANGE=> 'age_range',
    PICTURE  => 'picture',
    #EMPLOYEE_NUMBER => 'employee_number',
    WORK     => 'work'
  );

  my $client_id = $attr->{CLIENT_ID};
  my $token=$self->get_token();
  my $request = $get_me_url .'/v2.8/'
    . $client_id
    . '?fields='. join(',', values %info_fiealds)
    . "&access_token=$token";

  my $result = web_request($request, {
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
  });

  if($result->{error}) {
    show_hash($result->{error});
    $self->{errno}=$result->{error}{code};
    $self->{errstr}=$result->{error}{type} .' '.$result->{error}{message};
  }

  $self->{result} = $result;

  return $self;
}
#**********************************************************
=head2 get_fb_photo($attr)

  Arguments:
    USER_ID - facebook user id,
    SIZE    - image height    
    
  Returns:
    json
=cut
#**********************************************************
sub get_fb_photo {
  my $self = shift;
  my ($request) = @_;
  
  my $token = $self->get_token();
  my $request_url = $get_me_url
    . 'v2.8/'
    . ($request->{USER_ID} || q{}) . '/picture?'
    . ($request->{SIZE} ? "height=$request->{SIZE}" : q{})
    . "&redirect=0&access_token=$token";
   
  my $result = web_request($request_url, {
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
    DEBUG       => ($self->{debug} && $self->{debug} > 2) ? $self->{debug} : 0
  });
  return $result;
}

#**********************************************************
=head2 get_fbrequest($attr)

  Arguments:
    NODE_ID - facebook object id,  
      XXXXXX - for single page,
      XXXXXX_YYYYYYY - for status (where XXXXXXX - user id, YYYYYYY - post id)
    
    FIELDS - additional fields
  Returns:
    json
=cut
#**********************************************************
sub get_fbrequest {
  my $self = shift;
  my ($request) = @_;
  
  my $token = $self->get_token();
  my $request_url = $get_me_url
    . 'v2.8/'
    . ($request->{NODE_ID} || q{}) . '?'
    . ($request->{FIELDS} ? "fields=$request->{FIELDS}" : q{})
    . "&access_token=$token";
    
  my $result = web_request($request_url, {
    JSON_RETURN => 1,
    JSON_UTF8   => 1,
  });
  
  return $result;
}

#**********************************************************
=head2 who_liked_it($attr)

  Arguments:
    facebook object id,  
      XXXXXX - for single page,
      XXXXXX_YYYYYYY - for status (where XXXXXXX - user id, YYYYYYY - post id)
  Returns:
    Array of users from users db, who like this page.
=cut
#**********************************************************
sub who_liked_it {
  my $self = shift;
  my ($nodeid) = @_;
  
  my $response = $self->get_fbrequest({
    NODE_ID => $nodeid,
    FIELDS  => 'reactions',
  });

  unless ($response && ref $response eq 'HASH') {
    $self->{errno}=440;
    $self->{errstr}='Facebook is not answer';
    return 0;
  }
  if ($response->{error}) {
    $self->{errno}=$response->{error}->{code};
    $self->{errstr}=$response->{error}->{message};
    return 0;
  }
  
  my %likes_hash = ();
  if ( $response->{reactions}->{data} ) {
    foreach (@{$response->{reactions}->{data}}) {
      $likes_hash{$_->{id}} = (encode('UTF-8',$_->{name}));
    };
  }
  return \%likes_hash;
}
1;
