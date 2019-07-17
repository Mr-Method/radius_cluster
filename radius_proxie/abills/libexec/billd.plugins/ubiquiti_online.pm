# billd plugin

=head1 NAME

 DESCRIBE: Ubiquiti hotspot monitoring

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
our ($debug,
  %conf,
  $Admin,
  $var_dir,
  $db
);

our Dv_Sessions $Sessions;
our Nas $Nas;

use Unifi::Unifi;
use Acct;
use Dv;

ubiquiti_online();

#**********************************************************
=head2 ubiquiti_online()

=cut
#**********************************************************
sub ubiquiti_online{
  #my ($attr) = @_;

  my $Acct = Acct->new( $db, \%conf );
  my $Dv   = Dv->new( $db, $Admin, \%conf );
  my $Log  = Log->new( $db, $Admin );

  if($debug > 2) {
    $Log->{PRINT}=1;
  }
  else {
    $Log->{LOG_FILE} = $var_dir.'/log/ubiquiti_online.log';
  }

  if($debug) {
    print "ubiquiti_online\n";
    if($debug > 3) {
      $Acct->{debug}=1;
    }

    if ( $debug > 5 ){
      $Nas->{debug} = 1;
      $Sessions->{debug} = 1;
      $Dv->{debug} = 1;
    }
  }

  #Get users mac
  my $list = $Dv->list( {
    CID       => '!',
    TP_ID     => '_SHOW',
    PAGE_ROWS => 100000,
    COLS_NAME => 1
  } );

  my %users_mac = ();
  foreach my $line ( @{$list} ){
    $users_mac{lc $line->{cid}} = $line;
  }

  $list = $Nas->list( { %LIST_PARAMS,
    NAS_TYPE         => 'unifi',
    DISABLE          => 0,
    NAS_MNG_IP_PORT  => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_NAME         => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    MAC              => '_SHOW',
    NAS_IDENTIFIER   => '_SHOW',
    COLS_UPPER       => 1,
    COLS_NAME        => 1,
  });

  foreach my $nas_info ( @{$list} ){
    # check ips
    if ( $debug > 2 ){
      $Log->log_print('LOG_INFO', '',
        "NAS: $nas_info->{nas_id} MNG IP: $nas_info->{nas_mng_ip_port} SITE: $nas_info->{nas_identifier} MNG: $nas_info->{nas_mng_user}/$nas_info->{nas_mng_password}");
    }

    $conf{UNIFI_SITENAME}=$nas_info->{nas_identifier} || 'default';
    #Get billing online
    my %online_hash = ();
    $Sessions->online( {
      CLIENT_IP          => '_SHOW',
      ACCT_INPUT_OCTETS  => '_SHOW',
      ACCT_OUTPUT_OCTETS => '_SHOW',
      CID                => '_SHOW',
      STARTED            => '_SHOW',
      CONNECT_INFO       => '_SHOW',
      CALLS_TP_ID        => '_SHOW',
      NAS_ID             => $nas_info->{NAS_ID},
      SKIP_DEL_CHECK     => 1,
      COLS_NAME          => 1,
    });

    my $online_nas = $Sessions->{nas_sorted};

    foreach my $online ( @{ $online_nas->{ $nas_info->{nas_id} } } ){
      $online_hash{$online->{acct_session_id}} = $online;
    }

    my $Unifi = Unifi->new( \%conf );
    $Unifi->{unifi_url} = 'https://' . $nas_info->{nas_mng_ip_port};
    $Unifi->{login}     = $nas_info->{nas_mng_user};
    $Unifi->{password}  = $nas_info->{nas_mng_password};

    if ( $debug > 3 ){
      $Unifi->{debug} = 1;
    }

    #configureLWPUserAgent();
#    if ( !$Unifi->login() ){
#      $Log->log_print('LOG_ERR', '',
#        "Connect error: NAS: $nas_info->{nas_id} URL: $Unifi->{unifi_url} Error: $Unifi->{errno} $Unifi->{errstr}");
#      next;
#    }

    my $ap_user_list = $Unifi->users_list();

    if ( $Unifi->{errno} ){
      $Log->log_print('LOG_ERR', '',
        "NAS: $nas_info->{nas_id} SITE: $nas_info->{nas_identifier} Error: $Unifi->{errno} $Unifi->{errstr}");
      next;
    }

    #Get unifi logins
    my $total_sessions = $#{ $ap_user_list } + 1;
    for ( my $i = 0; $i <= $#{ $ap_user_list }; $i++ ){
      print "========> $i\n" if ($debug > 1);

      if ( $debug > 2 ){
        foreach my $key ( sort keys %{ $ap_user_list->[$i] } ){
          print "$key $ap_user_list->[$i]->{$key}\n";
        }
      }

      my $user_info = $ap_user_list->[$i];
      $user_info->{mac} = lc $user_info->{mac};

      if ( !$user_info->{ip} ){
        $user_info->{ip} = '0.0.0.0';
      }

      my %acct_data = (
        USER_NAME          => $user_info->{name} || $user_info->{user_id},
        ACCT_SESSION_ID    => $user_info->{_id},
        NAS_IP_ADDRESS     => $nas_info->{nas_ip},
        #NAS_PORT_ID          => 0,
        ACCT_SESSION_TIME  => $user_info->{'_uptime_by_uap'},
        ACCT_INPUT_OCTETS  => $user_info->{'rx_bytes'},
        ACCT_OUTPUT_OCTETS => $user_info->{'tx_bytes'},
        FRAMED_IP_ADDRESS  => "INET_ATON('$user_info->{ip}')",
        LUPDATED           => 'UNIX_TIMESTAMP()',
        SUM                => '0',
        CID                => $user_info->{mac},
        CONNECT_INFO       => "noise: $user_info->{noise} rx_rate $user_info->{rx_rate} tx_rate: $user_info->{tx_rate} tx_power: $user_info->{tx_power} $user_info->{user_id}, Signal: $user_info->{signal}",
        NAS_ID             => $nas_info->{NAS_ID},
        #        ACCT_INPUT_GIGAWORDS => $user_info->{},
        #        ACCT_OUTPUT_GIGAWORDS=> $user_info->{},
        GUEST              => ($user_info->{authorized}) ? 0 : 1,
      );

      if ( $users_mac{$user_info->{mac}} ){
        $acct_data{UID}   = $users_mac{$user_info->{mac}}->{uid} || 0,
        $acct_data{TP_ID} = $users_mac{$user_info->{mac}}->{tp_id} || 0,
      }

      if ( $online_hash{$user_info->{_id}} ){
        print "Online update: $user_info->{_id}\n" if ($debug > 1);
        $Sessions->online_update( {
          %acct_data,
          STATUS => 3,
        } );

        delete $online_hash{$user_info->{_id}};
      }
      else{
        print "Online add: $user_info->{_id}\n" if ($debug > 1);
        $Sessions->online_add( {
          %acct_data,
          STARTED         => 'NOW()', #$user_info->{first_seen},
          STATUS          => 1,
          REPLACE_RECORDS => 1
        });
      }
    }

    #stop unknown sessions
    my $stop_total = 0;
    foreach my $session_id ( sort keys  %online_hash ){
      if ( $debug > 1 ){
        print "Stop session: $session_id\n";
      }

      my $ACCT_INFO = $Sessions->online_info({
        NAS_ID          => $nas_info->{NAS_ID},
        NAS_PORT        => $online_hash{$session_id}{nas_port_id},
        ACCT_SESSION_ID => $session_id
      });

      if ( $Sessions->{errno} ){
        $Log->log_print('LOG_ERR', '', "[$Sessions->{errno}] $Sessions->{errstr}\n");
        next;
      }

      #Calculate session
      $ACCT_INFO->{INBYTE}                 = $Sessions->{ACCT_INPUT_OCTETS};
      $ACCT_INFO->{OUTBYTE}                = $Sessions->{ACCT_OUTPUT_OCTETS};
      $ACCT_INFO->{'Acct-Input-Gigawords'} = $Sessions->{ACCT_INPUT_GIGAWORDS},
      $ACCT_INFO->{'Acct-Output-Gigawords'}= $Sessions->{acct_output_gigawords},
      $ACCT_INFO->{INBYTE2}                = $Sessions->{EX_INPUT_OCTETS};
      $ACCT_INFO->{OUTBYTE2}               = $Sessions->{EX_OUTPUT_OCTETS};
      $ACCT_INFO->{'User-Name'}            = $Sessions->{USER_NAME};
      $ACCT_INFO->{'NAS-Port'}             = $Sessions->{NAS_PORT_ID};
      $ACCT_INFO->{'Acct-Status-Type'}     = 'Stop';
      $ACCT_INFO->{'Acct-Session-Time'}    = $Sessions->{ACCT_SESSION_TIME} || 0;
      $ACCT_INFO->{'Acct-Terminate-Cause'} = 'Lost-Alive';
      $ACCT_INFO->{'Acct-Session-Id'}      = $Sessions->{ACCT_SESSION_ID};
      $ACCT_INFO->{'Connect-Info'}         = $Sessions->{CONNECT_INFO};
      $ACCT_INFO->{'Framed-IP-Address'}    = $Sessions->{CLIENT_IP};
      $ACCT_INFO->{'Calling-Station-Id'}   = $Sessions->{CID};
      $stop_total++;
      $Acct->accounting( $ACCT_INFO, $nas_info );
    }

    if ( $debug > 1 ){
      print "$nas_info->{NAS_NAME} $conf{UNIFI_SITENAME} Total: $total_sessions Stoped: $stop_total\n";
    }

    #$Unifi->logout();
  }

  return 1;
}


1

