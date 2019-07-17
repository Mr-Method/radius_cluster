package Abills::Fetcher;

=head1 NAME

  Web fetcher function
    using CURL

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(cmd urlencode load_pmodule);
use POSIX qw/strftime/;
use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  web_request
  );

our @EXPORT_OK = qw(
  web_request
  );

our %conf;

#**********************************************************
=head2 web_request($request_url, $attr); - make web request

  Arguments:
    $request_url     - request URL
    $attr            - Attributes
      REQUEST_PARAMS - Request params hash
        [Param name] => [ value ]
      REQUEST_PARAMS_JSON - Request params hash converted to json request string
        [Param name] => [ value ]
      POST           - POST string (When not specified REQUEST_PARAMS)
      GET            - GET request mode
      JSON_ARRAY_VARS- JSON_ARRAY_VARS
      JSON_RETURN    - agregate result as JSON, return JSON hash result
      JSON_UTF8      - treat result as UTF8 (may be needed for JSON::XS)
      AGENT          - Agent info
      CURL_OPTIONS   - curl options
      HEADERS        - curl -H option (ARRAY_ref)
      BIN_DATA       - Send data througth file
      COOKIE         - Use cookies
      CLEAR_COOKIE   - Clear saved cookies
      TIMEOUT        - Request timeout (Default: 30 sec)
      DEBUG          - Debug mode
      DEBUG2FILE     - Write debug to file (Result is not writed unless DEBUG > 1)
      PAGE_HEADER    - Page header for debug message
      FILE_CURL      - Curl full path

  Returns:
      result string
      or
      hash on JSON_RETURN mode

  Examples:

=cut
#**********************************************************
sub web_request {
  my ($request_url, $attr) = @_;
  
  my $result = '';
  
  if ( $request_url =~ /^https/ || $attr->{CURL} || $attr->{POST} ) {
    $result = _curl_request($request_url, $attr);
  }
  else {
    $result = _socket_request($request_url, $attr);
  }
  
  if ( $attr->{JSON_RETURN} && $result ) {
    return json_return($result, $attr);
  }
  
  return $result;
}

#**********************************************************
=head2 json_return($result, $attr) - make json return

=cut
#**********************************************************
sub json_return {
  my ($result, $attr) = @_;

  my $json = $attr->{JSON_RETURN};
  if ( $json == 1 ) {
    load_pmodule('JSON');
    $json = JSON->new->allow_nonref;
    
    if ( $attr->{JSON_UTF8} ) {
      $json->utf8(1);
    }
  }
  
  my $perl_scalar;
  eval {$perl_scalar = $json->decode($result);};
  
  #Syntax error
  if ( $@ ) {
    $perl_scalar->{errno} = 2;
    $perl_scalar->{errstr} = $@;
  }
  #Else other error
  elsif ( ref $perl_scalar eq 'HASH' && $perl_scalar->{status} && $perl_scalar->{status} eq 'error' ) {
    $perl_scalar->{errno} = 1;
    $perl_scalar->{errstr} = "$perl_scalar->{message}";
  }
  
  return $perl_scalar;
}

#**********************************************************
=head2 _curl_request($request_url, $attr)

  Arguments:
     CURL_OPTIONS

  Results:

=cut
#**********************************************************
sub _curl_request {
  my ($request_url, $attr) = @_;
  my @request_params_arr = _parse_request_data_hash($attr);
  
  my $debug = $attr->{DEBUG} || 0;
  
  my $CURL = $attr->{FILE_CURL} || $conf{FILE_CURL} || _find_curl();
  if ( !-f $CURL ) {
    print "'curl' not found. use \$conf{FILE_CURL}\n";
    return 0;
  }
  
  my $result = '';
  my $request_params = '';
  my $curl_options = $attr->{CURL_OPTIONS} || '';
  
  # Tell curl it should follow redirects
  $curl_options .= q{ -L };
  
  if ( $attr->{AGENT} ) {
    $curl_options .= qq{ -A "$attr->{AGENT}" };
  }
  
  # Allow self-signed certificates
  if ($attr->{INSECURE}){
    $curl_options .= q{ -k };
  }
  
  if ( $attr->{HEADERS} ) {
    foreach my $key ( @{ $attr->{HEADERS} } ) {
      $curl_options .= qq{ -H "$key" };
    }
  }
  
  if ( $attr->{COOKIE} ) {
    my $cookie_file = '/tmp/cookie.';
    $curl_options .= qq{ --cookie $cookie_file --cookie-jar $cookie_file };
  }
  
  if ( $attr->{BIN_DATA} ) {
    if ( $attr->{TPL_DIR} ) {
      $conf{TPL_DIR} = $attr->{TPL_DIR};
    }
    elsif ( !$conf{TPL_DIR} ) {
      $conf{TPL_DIR} = '/tmp/';
    }
    
    #my $ret = file_op({
    #  FILENAME => "$conf{TPL_DIR}/tmp_.bin",
    #  PATH     => "$conf{TPL_DIR}",
    #  WRITE    => 1,
    #  CONTENT  => $attr->{BIN_DATA}
    #});
    
    if ( open(my $fh, '>', "$conf{TPL_DIR}/tmp_.bin") ) {
      print $fh $attr->{BIN_DATA};
      close($fh);
    }
    else {
      print "Can't open file $conf{TPL_DIR}/tmp_.bin $!\n";
    }
    
    $curl_options .= " --data \"\@$conf{TPL_DIR}/tmp_.bin\"";
  }
  
  if ( $attr->{REQUEST_PARAMS_JSON} ) {
    $request_params = '-d "{' . join(',', @request_params_arr) . '}"';
  }
  elsif ( $#request_params_arr > - 1 ) {
    $request_params = join('&', @request_params_arr);
    if ( $attr->{GET} ) {
      $request_url .= "?" . $request_params;
      $request_params = '';
    }
    #POST request string
    else {
      $request_params = "-d \"$request_params\" ";
    }
  }

  $request_url =~ s/\n/%20/g;
  $request_url =~ s/ /%20/g;
  $request_url =~ s/"/\\"/g;
  $request_url =~ s/\`/\\\`/g;
  
  my $request_cmd = qq{$CURL $curl_options -s "$request_url" $request_params };
  $result = cmd($request_cmd, { timeout => defined($attr->{'TIMEOUT'}) ? $attr->{'TIMEOUT'} : 30 }) if ( $debug < 7 );
  
  if ( $? != 0 ) {
    $result = 'Timeout ' . $?;
  }
  
  if ( $debug ) {
    my $request_ = (($attr->{REQUEST_COUNT}) ? $attr->{REQUEST_COUNT} : 0);
    if ( $attr->{DEBUG2FILE} ) {
      my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
      my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));
      
      if ( open(my $fh, '>>', $attr->{DEBUG2FILE}) ) {
        print $fh "===============================\n";
        print $fh " $DATE : $TIME ($request_) " . $request_cmd . "\n";
        print $fh "$result\n" if ( $debug > 1 );
        close($fh);
      }
      else {
        print "$attr->{DEBUG2FILE} $!\n";
      }
    }
    else {
      if ( $attr->{PAGE_HEADER} ) {
        print "Content-Type: text/html\n\n";
      }
      print "<br>DEBUG: $debug COUNT:" . $request_ . "=====REQUEST=====<br>\n";
      print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
      print "=====RESPONCE=====<br>\n";
      print "<textarea cols=90 rows=15>$result</textarea>\n";
    }
  }
  
  if ( $attr->{CLEAR_COOKIE} ) {
    unlink "/tmp/cookie.";
  }
  
  if ( $result eq 'Timeout' ) {
    return $result;
  }
  
  return $result;
}

#**********************************************************
=head2 _socket_request()

=cut
#**********************************************************
sub _socket_request {
  my ($request_url, $attr) = @_;
  
  # Direct request
  require Socket;
  Socket->import();
  require IO::Socket;
  IO::Socket->import();
  require IO::Select;
  IO::Select->import();
  
  my @request_params_arr = _parse_request_data_hash($attr);
  
  my $res;
  my $host = '';
  my $port = 80;
  my $debug = $attr->{DEBUG} || 0;
  
  # Parse
  $request_url =~ /http:\/\/([a-zA-Z.0-9:-]+)(\/?(.+))?/;
  $host = $1;
  $request_url = '/' . ($3 || '');
  
  return '' if !$host;
  
  if ( $host =~ /:/ ) {
    ($host, $port) = split(/:/, $host, 2);
  }
  
  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    Timeout  => defined($attr->{'TIMEOUT'}) ? $attr->{'TIMEOUT'} : 5
  ); # or log_print('LOG_DEBUG', "ERR: Can't connect to '$host:$port' $!");
  
  if ( !$socket ) {
    return '';
  }
  
  if ( $#request_params_arr > - 1 ) {
    $request_url .= '?' . join('&', @request_params_arr);
  }
  
  $request_url =~ s/ /%20/g;
  my $raw_request = "GET $request_url HTTP/1.0\r\n";
  $raw_request .= ($attr->{'User-Agent'}) ? $attr->{'User-Agent'} : "User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows 98;Win 9x 4.90)\r\n";
  $raw_request .= "Accept: text/html, image/png, image/x-xbitmap, image/gif, image/jpeg, */*\r\n";
  $raw_request .= "Accept-Language: ru\r\n";
  $raw_request .= "Host: $host\r\n";
  $raw_request .= "Content-type: application/x-www-form-urlencoded\r\n";
  $raw_request .= "Referer: $attr->{'Referer'}\r\n" if ( $attr->{'Referer'} );
  # $raw_request .= "Connection: Keep-Alive\r\n";
  $raw_request .= "Cache-Control: no-cache\r\n";
  $raw_request .= "Accept-Encoding: *;q=0\r\n";
  $raw_request .= "\r\n";
  
  print $raw_request if ( $attr->{debug} );
  
  $socket->send($raw_request);
  while ( <$socket> ) {
    $res .= $_;
  }
  close($socket);
  
  $res //= q{};
  # my ($header, $content)
  my ($header) = split(/\n\n/, $res);
  
  # Allow to be redirected
  if ( $header =~ /HTTP\/1.\d 302/ ) {
    $header =~ /Location: (.+)[\r\n]{1,2}/;
    
    my $new_location = $1;
    if ( $new_location !~ /^http:\/\// ) {
      $new_location = "http://$host" . $new_location;
    }
    
    return web_request($new_location, {
        Referer    => "$request_url",
        REDIRECTED => 302,
        %{ ($attr) ? $attr : {} } }
    );
  }
  
  if ( $res =~ /\<meta\s+http-equiv='Refresh'\s+content='\d;\sURL=(.+)'\>/ig ) {
    my $new_location = $1;
    if ( $new_location !~ /^http:\/\// ) {
      $new_location = "http://$host" . $new_location;
    }
    
    $res = web_request($new_location, { Referer => "$new_location", %{ ($attr) ? $attr : {} } });
  }
  
  if ( $debug > 2 ) {
    print "<br>Plain request:<textarea cols=80 rows=8>$raw_request\n\nRESULT:\n$res</textarea><br>\n";
  }
  
  if ( $attr->{BODY_ONLY} ) {
    (undef, $res) = split(/\r?\n\r?\n/, $res, 2);
  }
  
  return $res;
}

#**********************************************************
=head2 _parse_request_data_hash($attr)

=cut
#**********************************************************
sub _parse_request_data_hash {
  my ($attr) = @_;
  
  my @params = ();
  
  if ( $attr->{REQUEST_PARAMS} && ref $attr->{REQUEST_PARAMS} eq 'HASH' ) {
    foreach my $k ( keys %{ $attr->{REQUEST_PARAMS} } ) {
      # Skip false and undefined values
      next if ( !$k || !defined($attr->{REQUEST_PARAMS}->{$k}) );
      
      # If one of keys is array, add inner items to request
      if ( ref $attr->{REQUEST_PARAMS}->{$k} eq 'ARRAY' ) {
        foreach my $val ( @{ $attr->{REQUEST_PARAMS}->{$k} } ) {
          $val = urlencode($val);
          push @params, "$k=$val";
        }
      }
      else {
        $attr->{REQUEST_PARAMS}->{$k} = urlencode($attr->{REQUEST_PARAMS}->{$k});
        push @params, "$k=$attr->{REQUEST_PARAMS}->{$k}";
      }
    }
  }
  elsif ( $attr->{REQUEST_PARAMS_JSON} ) {
    foreach my $k ( keys %{ $attr->{REQUEST_PARAMS_JSON} } ) {
      next if ( !$k || !defined($attr->{REQUEST_PARAMS_JSON}->{$k}) );
      if ( ref $attr->{REQUEST_PARAMS_JSON}->{$k} eq 'ARRAY' ) {
        if ( $attr->{JSON_ARRAY_VARS} ) {
          push @params, " \\\"" . ($k || q{}) . "\\\" : ["
              . '\\"' . join('", "', @{ $attr->{REQUEST_PARAMS_JSON}->{$k} }) . '\\"'
              . q{] };
        }
        else {
          foreach my $val ( @{ $attr->{REQUEST_PARAMS_JSON}->{$k} } ) {
            $val = urlencode($val);
            push @params, qq{ \\\"$k\\\" : \\\"$val\\\" };
          }
        }
      }
      elsif ( ref $attr->{REQUEST_PARAMS_JSON}->{$k} eq 'HASH' ) {
        my @hash_params = ();
        foreach my $key ( keys %{ $attr->{REQUEST_PARAMS_JSON}->{$k} } ) {
          #$val = urlencode($val);
          
          my $val = $attr->{REQUEST_PARAMS_JSON}->{$k}->{$key};
          
          if ( $val ) {
            if ( ref $val eq 'ARRAY' ) {
              $val = '[\"' . join('\", \"', @{$val}) . '\"]';
            }
            else {
              $val = qq{\\\"$val\\\"};
            }
          }
          else {
            $val = qq{\\\"$val\\\"};
          }
          
          push @hash_params, qq{ \\\"$key\\\" : $val };
        }
        
        my $val = join(', ', @hash_params);
        
        push @params, qq{ \\\"$k\\\" : { $val } };
      }
      else {
        $attr->{REQUEST_PARAMS}->{$k} = urlencode($attr->{REQUEST_PARAMS_JSON}->{$k});
        
        if ( $attr->{REQUEST_PARAMS}->{$k} =~ /true|false/ ) {
          push @params, qq{ \\\"$k\\\" : $attr->{REQUEST_PARAMS}->{$k} };
        }
        else {
          push @params, qq{ \\\"$k\\\" : \\\"$attr->{REQUEST_PARAMS_JSON}->{$k}\\\" };
        }
      }
    }
    
  }
  elsif ( $attr->{POST} ) {
    @params = ($attr->{POST});
  }
  
  return wantarray ? @params : \@params;
}

#**********************************************************
=head2 _find_curl()

=cut
#**********************************************************
sub _find_curl {
  my $curl_file = `which curl` || '/usr/local/bin/curl';
  chomp($curl_file);
  
  if ( $curl_file =~ /(\S+)/ ) {
    $curl_file = $1 || '';
  }
  
  return $curl_file;
}


1;
