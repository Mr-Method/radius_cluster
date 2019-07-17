package Eltex_smg;

=head1 NAME
   Eltex_smg VoIP AAA functions
   http://eltex.nsk.ru/product/smg-1016m

  Auth
  http://tools.ietf.org/html/draft-smith-sipping-auth-examples-01

=cut
#**********************************************************

use strict;
# User name expration
use main;
use Billing;
use Auth;

our @ISA = ("main");
my ($conf, $Billing);

my %RAD_PAIRS  = ();
my %ACCT_TYPES = ('Start' =>          1, 
                  'Stop'  =>          2, 
                  'Alive' =>          3, 
                  'Interim-Update'=>  3,
                  'Accounting-On' =>  7, 
                  'Accounting-Off'=>  8
                 );

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($conf)   = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  my $Auth = Auth->new($self->{db}, $conf);
  $Billing = Billing->new($self->{db}, $conf);

  return $self;
}

#**********************************************************
# Pre_auth
#**********************************************************
sub pre_auth {
  my ($self, $RAD, $attr) = @_;

  $self->{'RAD_CHECK'}{'Auth-Type'} = "Accept";
  return 0;
}

#**********************************************************
# Preproces
#**********************************************************
sub preproces {
  my ($RAD) = @_;

  my %CALLS_ORIGIN = (
    answer    => 0,
    originate => 1,
    proxy     => 2
  );

  (undef, $RAD->{H323_CONF_ID}) = split(/=/, $RAD->{H323_CONF_ID}, 2) if ($RAD->{H323_CONF_ID} =~ /=/);
  $RAD->{H323_CONF_ID} =~ s/ //g;

  if ($RAD->{H323_CALL_ORIGIN}) {
    (undef, $RAD->{H323_CALL_ORIGIN}) = split(/=/, $RAD->{H323_CALL_ORIGIN}, 2) if ($RAD->{H323_CALL_ORIGIN} =~ /=/);
    $RAD->{H323_CALL_ORIGIN} = $CALLS_ORIGIN{ $RAD->{H323_CALL_ORIGIN} } if ($RAD->{H323_CALL_ORIGIN} ne 1);
  }

  (undef, $RAD->{H323_DISCONNECT_CAUSE}) = split(/=/, $RAD->{H323_DISCONNECT_CAUSE}, 2) if (defined($RAD->{H323_DISCONNECT_CAUSE}));

  $RAD->{CLIENT_IP_ADDRESS} = $RAD->{FRAMED_IP_ADDRESS} if ($RAD->{FRAMED_IP_ADDRESS});
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = '';
  if (defined($RAD->{H323_CALL_ORIGIN}) && $RAD->{H323_CALL_ORIGIN} == 0) {
    $WHERE = "number='$RAD->{CALLED_STATION_ID}'";
    $RAD->{USER_NAME} = $RAD->{CALLED_STATION_ID};
  }
  else {
    $WHERE = "number='$RAD->{USER_NAME}'";
  }

  $self->query2("SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   INET_NTOA(voip.ip) AS ip,
   DECODE(password, '$conf->{secretkey}') AS password,
   if (voip.logins=0, if(voip.logins is null, 0, tp.logins), voip.logins) AS logins,
   voip.allow_answer,
   voip.allow_calls,
   voip.disable AS voip_disable,
   u.disable AS user_disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
  UNIX_TIMESTAMP() AS session_start,
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year,
   if(voip.filter_id<>'', voip.filter_id, tp.filter_id) AS filter_id,
   tp.payment_type,
   tp.uplimit,
   tp.age AS account_age,
   voip.expire AS voip_expire
   FROM voip_main voip 
   INNER JOIN users u ON (u.uid=voip.uid)
   LEFT JOIN tarif_plans tp ON (tp.tp_id=voip.tp_id)
   WHERE
   $WHERE
   AND (voip.expire='0000-00-00' or voip.expire > CURDATE());",
  undef,
  { INFO => 1 }
  );

  if($self->{errno}) {
    if($self->{errno} == 2) {
    }
    return $self;
  }

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);

  $self->check_bill_account();
  if ($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'} = $self->{errstr};
    return 1, \%RAD_PAIRS;
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub number_expr {
  my ($RAD) = @_;
  my @num_expr = split(/;/, $conf->{VOIP_NUMBER_EXPR});

  my $number = $RAD->{CALLED_STATION_ID};
  for (my $i = 0 ; $i <= $#num_expr ; $i++) {
    my ($left, $right) = split(/\//, $num_expr[$i]);
    my $r = eval "\"$right\"";
    if ($RAD->{CALLED_STATION_ID} =~ s/$left/$r/) {
      last;
    }
  }

  return 0;
}

#**********************************************************
# Accounting Work_
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  if (defined($RAD->{H323_CONF_ID})) {
    preproces($RAD);
  }

  $self->{INFO}='';
  my $cnu    = $RAD->{CALLED_STATION_ID} || '';

  # For Cisco
  if ($RAD->{USER_NAME} =~ /(\S+):(\d+)/) {
    $RAD->{USER_NAME} = $2;
  }

  if ($conf->{VOIP_NUMBER_EXPR}) {
    number_expr($RAD);
  }

  %RAD_PAIRS = ();
  $self->user_info($RAD, $NAS);

  if ($self->{errno}) {
  	my $message = '';
  	if ($self->{errno} == 2) {
  		$message = "User not exist '$RAD->{USER_NAME}'";
  	}
  	else {
  		$message = "[$self->{errno}] $self->{errstr}";
  	}

    $RAD_PAIRS{'Reply-Message'} = $message;
    return 1, \%RAD_PAIRS;
  }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    if (!$RAD->{H323_CALL_ORIGIN}) {
      $RAD_PAIRS{'Reply-Message'} = "Answer Number Not Exist '$RAD->{USER_NAME}'";
      $RAD_PAIRS{'Filter-Id'}='answer_not_exist';
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = "Caller Number Not Exist '$RAD->{USER_NAME}'";
      $RAD_PAIRS{'Filter-Id'}='call_not_exist';
    }
    return 1, \%RAD_PAIRS;
  }

  if ($RAD->{'DIGEST_USERNAME'}) {
    if ($RAD->{DIGEST_METHOD}) {
    	$self->{INFO}.= "$RAD->{DIGEST_METHOD}/". (($RAD->{H323_CONF_ID}) ? $RAD->{H323_CONF_ID} : '');
    }

    my $method = 'REGISTER';
    my $uri    = 'sip:'. scalar $RAD->{DIGEST_REALM};

    # If outgoing call
    my $outgoing = 0;
    if ($RAD->{H323_GW_ID}) {
      $method = 'INVITE';
      $uri    = $RAD->{DIGEST_URI}; #$cnu . '@' . $RAD->{H323_GW_ID};
      $outgoing = 1;
    }

  	my $res = generate_DigestResponce($RAD->{'DIGEST_USERNAME'}, 
                        $RAD->{'DIGEST_REALM'},
                        $RAD->{'DIGEST_NONCE'},
                        $uri,
                        $RAD->{'DIGEST_METHOD'},
                        $self->{PASSWORD}
                        );

    if ($RAD->{DIGEST_RESPONSE} ne "$res") {
      $RAD_PAIRS{'Reply-Message'} = "Wrong Digest auth $RAD->{DIGEST_RESPONSE} -> $res";
      return 1, \%RAD_PAIRS;
    }
  }
  elsif (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE})) {
    if (check_chap("$RAD->{CHAP_PASSWORD}", "$self->{PASSWORD}", "$RAD->{CHAP_CHALLENGE}", 0) == 0) {
      $RAD_PAIRS{'Reply-Message'} = "Wrong CHAP password '$self->{PASSWORD}'";
      return 1, \%RAD_PAIRS;
    }
  }
  else {
    if ($self->{IP} ne '0.0.0.0' && $self->{IP} ne $RAD->{FRAMED_IP_ADDRESS}) {
      $RAD_PAIRS{'Reply-Message'} = "Not allow IP '$RAD->{FRAMED_IP_ADDRESS}' / $self->{IP} ";
      $RAD_PAIRS{'Filter-Id'}='not_allow_ip';
      return 1, \%RAD_PAIRS;
    }
  }

  #DIsable
  if ($self->{VOIP_DISABLE}) {
    if ($self->{VOIP_DISABLE} == 2 && $RAD->{H323_CALL_ORIGIN} == 1) {
      $RAD_PAIRS{'Reply-Message'} = "Incoming only";
      $RAD_PAIRS{'Filter-Id'} = 'incoming_only';
      return 1, \%RAD_PAIRS;
    }
    else {
      $RAD_PAIRS{'Reply-Message'} = "Service Disable";
      $RAD_PAIRS{'Filter-Id'} = 'service_disabled';
      return 1, \%RAD_PAIRS;
    }
  }
  elsif ($self->{USER_DISABLE}) {
    $RAD_PAIRS{'Reply-Message'} = "Account Disable";
     $RAD_PAIRS{'Filter-Id'} = 'user_disable';
    return 1, \%RAD_PAIRS;
  }

  # 
  if ($self->{LOGINS} > 0) {
    $self->query2("SELECT count(*) FROM voip_calls 
       WHERE (calling_station_id='$RAD->{CALLING_STATION_ID}' OR called_station_id='$RAD->{CALLING_STATION_ID}')
       AND status<>2;");

    if ($self->{TOTAL} && $self->{list}->[0]->[0] >= $self->{LOGINS}) {
      $RAD_PAIRS{'Reply-Message'} = "More then allow calls ($self->{LOGINS}/$self->{list}->[0]->[0])";
      return 1, \%RAD_PAIRS;
    }
  }

  if ($self->{FILTER_ID}) {
    $RAD_PAIRS{'Filter-Id'} = $self->{FILTER_ID};
  }

  #$self->{PAYMENT_TYPE} = 0;
  if ($self->{PAYMENT_TYPE} == 0) {
    $self->{DEPOSIT}           = $self->{DEPOSIT} + $self->{CREDIT};    #-$self->{CREDIT_TRESSHOLD};
    $RAD->{H323_CREDIT_AMOUNT} = $self->{DEPOSIT};

    #One month freeperiod
    if ($conf->{VOIP_ONEMONTH_INCOMMING_ALLOW} && ! $self->{VOIP_DISABLE}) {

    }
    #Check deposit
    elsif ($self->{DEPOSIT} <= 0) {
      $RAD_PAIRS{'Reply-Message'} = "Negativ deposit '$self->{DEPOSIT}'. Rejected!";
      $RAD_PAIRS{'Filter-Id'}='neg_deposit';
      return 1, \%RAD_PAIRS;
    }

    if ($self->{DEPOSIT} < $self->{UPLIMIT}) {
      $RAD_PAIRS{'Reply-Message'} = "Too small deposit please recharge balace ($self->{DEPOSIT})";
      $RAD_PAIRS{'Filter-Id'}='deposit_alert';
    }
  }
  else {
    $self->{DEPOSIT} = 0;
  }

  # if call
  if ($RAD->{H323_CONF_ID}) {
    if ($self->{ALLOW_ANSWER} < 1 && $RAD->{H323_CALL_ORIGIN} == 0) {
      $RAD_PAIRS{'Reply-Message'} = "Not allow answer";
      $RAD_PAIRS{'Filter-Id'} ='not_allow_answer';
      return 1, \%RAD_PAIRS;
    }
    elsif ($self->{ALLOW_CALLS} < 1 && $RAD->{H323_CALL_ORIGIN} == 1) {
      $RAD_PAIRS{'Reply-Message'} = "Not allow calls";
      $RAD_PAIRS{'Filter-Id'}='not_allow_call';
      return 1, \%RAD_PAIRS;
    }

    $self->get_route_prefix($RAD);
    if ($self->{TOTAL} < 1) {
      $RAD_PAIRS{'Reply-Message'} = "No route '" . $RAD->{'CALLED_STATION_ID'} . "'";
      $RAD_PAIRS{'Filter-Id'}='no_route';
      return 1, \%RAD_PAIRS;
    }
    elsif ($self->{ROUTE_DISABLE} == 1) {
      $RAD_PAIRS{'Reply-Message'} = "Route disabled '" . $RAD->{'CALLED_STATION_ID'} . "'";
      $RAD_PAIRS{'Filter-Id'}='route_disable';
      return 1, \%RAD_PAIRS;
    }

    #Get intervals and prices
    #originate
    if (($RAD->{H323_CALL_ORIGIN} && $RAD->{H323_CALL_ORIGIN} == 1) ||
       ($RAD->{DIGEST_METHOD} && $RAD->{DIGEST_METHOD} eq "INVITE") ) {
      $self->{INFO} .= " $RAD->{'CALLED_STATION_ID'}";
      $self->get_intervals();

      if ($self->{TOTAL} < 1) {
        $RAD_PAIRS{'Reply-Message'} = "No price for route prefix '$self->{PREFIX}' number '" . $RAD->{'CALLED_STATION_ID'} . "'";
        $RAD_PAIRS{'Filter-Id'}='no_price_for_route';
        return 1, \%RAD_PAIRS;
      }

      my ($session_timeout, $ATTR) = $Billing->remaining_time(
        $self->{DEPOSIT},
        {
          TIME_INTERVALS      => $self->{TIME_PERIODS},
          INTERVAL_TIME_TARIF => $self->{PERIODS_TIME_TARIF},
          SESSION_START       => $self->{SESSION_START},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          REDUCTION           => $self->{REDUCTION},
          POSTPAID            => $self->{PAYMENT_TYPE},
          PRICE_UNIT          => 'Min'
        }
      );

      if ($session_timeout > 0) {
        $RAD_PAIRS{'Session-Timeout'} = $session_timeout;
        $RAD_PAIRS{'h323-credit-time'}= $session_timeout;
      }
#      elsif ($session_timeout == -2) {
#        $RAD_PAIRS{'Reply-Message'} = "Not allow period prefix: $self->{PREFIX}";
#        $RAD_PAIRS{'Filter-Id'}='not_allow_period';
#        return 1, \%RAD_PAIRS;
#      }
      elsif ($self->{PAYMENT_TYPE} == 0 && $session_timeout <= 0) {
        $RAD_PAIRS{'Reply-Message'} = "Too small deposit for call (". sprintf("%.2f", $self->{DEPOSIT}). ")";
        $RAD_PAIRS{'Filter-Id'}='too_small_deposit';
        return 1, \%RAD_PAIRS;
      }

      #Make trunk data for asterisk
      if ($NAS->{NAS_TYPE} eq 'asterisk' and $self->{TRUNK_PROTOCOL}) {
        $self->{prepend} = '';

        my $number = $RAD->{'CALLED_STATION_ID'};
        if (defined($self->{REMOVE_PREFIX})) {
          $number =~ s/^$self->{REMOVE_PREFIX}//;
        }

        if (defined($self->{ADDPREFIX})) {
          $number = $self->{ADDPREFIX} . $number;
        }

        if ($self->{TRUNK_PROTOCOL} eq "Local") {
          $RAD_PAIRS{'next-hop-ip'} = "Local/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER} . "/n";
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "IAX2") {
          $RAD_PAIRS{'next-hop-ip'} = "IAX2/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "Zap") {
          $RAD_PAIRS{'next-hop-ip'} = "Zap/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "SIP") {
          $RAD_PAIRS{'next-hop-ip'} = "SIP/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "OH323") {
          $RAD_PAIRS{'next-hop-ip'} = "OH323/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "OOH323C") {
          $RAD_PAIRS{'next-hop-ip'} = "OOH323C/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }
        elsif ($self->{TRUNK_PROTOCOL} eq "H323") {
          $RAD_PAIRS{'next-hop-ip'} = "H323/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
        }

        $RAD_PAIRS{'session-protocol'} = $self->{TRUNK_PROTOCOL};

      }
    }
    else {
      $RAD->{USER_NAME} = "$RAD->{CALLED_STATION_ID}";
    }

    #Make start record in voip_calls
    my $SESSION_START = 'now()';
    $self->query2("INSERT INTO voip_calls 
   (  status,
      user_name,
      started,
      lupdated,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address,
      conf_id,
      call_origin,
      uid,
      bill_id,
      tp_id,
      route_id,
      reduction
   )
   values ('0', '$RAD->{USER_NAME}', $SESSION_START, UNIX_TIMESTAMP(), 
      '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', '$NAS->{NAS_ID}',
      INET_ATON('". ($RAD->{CLIENT_IP_ADDRESS} || '0.0.0.0') ."'),
      '$RAD->{H323_CONF_ID}',
      '". ($RAD->{H323_CALL_ORIGIN} || 0)."',
      '$self->{UID}',
      '$self->{BILL_ID}',
      '$self->{TP_ID}',
      '$self->{ROUTE_ID}',
      '$self->{REDUCTION}');", 'do'
    );

    #   }
  }

  if ($self->{ACCOUNT_AGE} > 0 && $self->{VOIP_EXPIRE} eq '0000-00-00') {
    $self->query2("UPDATE voip_main SET expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
     WHERE uid='$self->{UID}';", 'do');
  }

  return 0, \%RAD_PAIRS;
}

#**********************************************************
#
#**********************************************************
sub get_route_prefix {
  my $self = shift;
  my ($RAD) = @_;

  # Get route
  my $query_params = '';

  for (my $i = 1 ; $i <= length($RAD->{'CALLED_STATION_ID'}) ; $i++) {
    $query_params .= '\'' . substr($RAD->{'CALLED_STATION_ID'}, 0, $i) . '\',';
  }
  chop($query_params);

  $self->query2("SELECT r.id AS route_id,
      r.prefix AS prefix,
      r.gateway_id AS gateway_id,
      r.disable AS route_disable
     FROM voip_routes r
      WHERE r.prefix in ($query_params)
      ORDER BY 2 DESC LIMIT 1;",
      undef,
      {INFO => 1}
  );

  #if ($self->{TOTAL} < 1) {
  #  return $self;
  #}
  #($self->{ROUTE_ID}, $self->{PREFIX}, $self->{GATEWAY_ID}, $self->{ROUTE_DISABLE}, $self->{TRUNK_PROTOCOL}, $self->{TRUNK_PATH}) = @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
#
#**********************************************************
 sub get_intervals {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT i.day, TIME_TO_SEC(i.begin), TIME_TO_SEC(i.end), 
    rp.price, i.id, rp.route_id,
    if (t.protocol IS NULL, '', t.protocol),
    if (t.protocol IS NULL, '', t.provider_ip),
    if (t.protocol IS NULL, '', t.addparameter),
    if (t.protocol IS NULL, '', t.removeprefix),
    if (t.protocol IS NULL, '', t.addprefix),
    if (t.protocol IS NULL, '', t.failover_trunk),
    rp.extra_tarification
      from intervals i, voip_route_prices rp
      LEFT JOIN voip_trunks t ON (rp.trunk=t.id)
      where
         i.id=rp.interval_id 
         and i.tp_id  = '$self->{TP_ID}'
         and rp.route_id = '$self->{ROUTE_ID}';"
  );

  my $list                = $self->{list};
  my %time_periods        = ();
  my %periods_time_tarif  = ();
  $self->{TRUNK_PATH}     = '';
  $self->{TRUNK_PROVIDER} = '';

  foreach my $line (@$list) {
    #$time_periods{INTERVAL_DAY}{INTERVAL_START}="INTERVAL_ID:INTERVAL_END";
    $time_periods{ $line->[0] }{ $line->[1] } = "$line->[4]:$line->[2]";

    #$periods_time_tarif{INTERVAL_ID} = "INTERVAL_PRICE";
    $periods_time_tarif{ $line->[4] } = $line->[3];
    $self->{TRUNK_PROTOCOL}           = $line->[6];
    $self->{TRUNK_PROVIDER}           = $line->[7];
    $self->{ADDPARAMETER}             = $line->[8];
    $self->{REMOVE_PREFIX}            = $line->[9];
    $self->{ADDPREFIX}                = $line->[10];
    $self->{FAILOVER_TRUNK}           = $line->[11];
    $self->{EXTRA_TARIFICATION}       = $line->[12];
  }
  $self->{TIME_PERIODS}       = \%time_periods;
  $self->{PERIODS_TIME_TARIF} = \%periods_time_tarif;

  return $self;
}

#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $acct_status_type = $ACCT_TYPES{ $RAD->{ACCT_STATUS_TYPE} };
  my $SESSION_START    = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ? "FROM_UNIXTIME($RAD->{SESSION_START})" : 'now()';
  my $sesssion_sum     = 0;
  $RAD->{CLIENT_IP_ADDRESS} = '0.0.0.0' if (!$RAD->{CLIENT_IP_ADDRESS});

  preproces($RAD);

  if ($NAS->{NAS_TYPE} eq 'cisco_voip') {
    if ($RAD->{USER_NAME} =~ /(\S+):(\d+)/) {
      $RAD->{USER_NAME} = $2;
    }
  }

  if ($conf->{VOIP_NUMBER_EXPR}) {
    number_expr($RAD);
  }

#while(my ($k, $v)=each %{ $RAD } ) {
#	print "$k, $v\n";
#}

  #Start
  if ($acct_status_type == 1) {

    if ($NAS->{NAS_TYPE} eq 'eltex_smg') {
      # For Cisco
      $self->user_info($RAD, $NAS);

      my $sql = "INSERT INTO voip_calls 
      (  status,
       user_name,
       started,
       lupdated,
       calling_station_id,
       called_station_id,
       nas_id,
       conf_id,
       call_origin,
       uid,
       bill_id,
       tp_id,
       reduction,
       acct_session_id,
       route_id
      )
     values ($acct_status_type, '$RAD->{USER_NAME}', $SESSION_START, UNIX_TIMESTAMP(), 
       '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', '$NAS->{NAS_ID}',
       '$RAD->{H323_CONF_ID}',
       '$RAD->{H323_CALL_ORIGIN}',
       '$self->{UID}',
       '$self->{BILL_ID}',
       '$self->{TP_ID}',
       '$self->{REDUCTION}',
       '$RAD->{ACCT_SESSION_ID}',
       ''
       );";

      $self->query2($sql, 'do');
    }
    else {
      $self->query2("UPDATE voip_calls SET
      status='$acct_status_type',
      acct_session_id='$RAD->{ACCT_SESSION_ID}'
      WHERE conf_id='$RAD->{H323_CONF_ID}';", 'do'
      );
    }
  }

  # Stop status
  elsif ($acct_status_type == 2) {
    if ($RAD->{ACCT_SESSION_TIME} > 0) {
      $self->query2("SELECT 
      UNIX_TIMESTAMP(started) AS session_start,
      lupdated AS last_update,
      acct_session_id,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address,
      conf_id,
      call_origin,
      uid,
      reduction,
      bill_id,
      c.tp_id,
      route_id,
      tp.time_division,
      UNIX_TIMESTAMP() AS session_stop,
      UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')) AS day_begin,
      DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_week,
      DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())) AS day_of_year
    FROM voip_calls c, voip_tps tp
      WHERE  c.tp_id=tp.id
      and conf_id='$RAD->{H323_CONF_ID}'
      and call_origin='$RAD->{H323_CALL_ORIGIN}';",
      undef,
      { INFO => 1 }
      );


      if ($self->{errno}) {
        if ($self->{TOTAL} < 1) {
          $self->{errno}  = 1;
          $self->{errstr} = "Call not exists $RAD->{H323_CONF_ID}/$RAD->{H323_CALL_ORIGIN}";
          return $self;
        }
        else {
          $self->{errno}  = 1;
          $self->{errstr} = "SQL error";
          return $self;
        }
      }

      if ($self->{UID} == 0) {
        $self->{errno}  = 110;
        $self->{errstr} = "Number not found '" . $RAD->{'USER_NAME'} . "'";
        return $self;
      }
      elsif ($RAD->{H323_CALL_ORIGIN} == 1) {
        if (!$self->{ROUTE_ID}) {
          $self->get_route_prefix($RAD);
        }

        $self->get_intervals();
        if ($self->{TOTAL} < 1) {
          $self->{errno}  = 111;
          $self->{errstr} = "No price for route prefix '$self->{PREFIX}' number '" . $RAD->{'CALLED_STATION_ID'} . "'";
          return $self;
        }

        # Extra tarification
        if ($self->{EXTRA_TARIFICATION}) {
          $self->query2("SELECT prepaid_time FROM voip_route_extra_tarification WHERE id='$self->{EXTRA_TARIFICATION}';");
          $self->{PREPAID_TIME} = $self->{list}->[0]->[0];
          if ($self->{PREPAID_TIME} > 0) {
            $self->{LOG_DURATION} = 0;
            my $sql = "SELECT sum(duration) FROM voip_log l, voip_route_prices rp WHERE l.route_id=rp.route_id
               AND uid='$self->{UID}' AND rp.extra_tarification='$self->{EXTRA_TARIFICATION}'";
            $self->query2("$sql");
            $self->{LOG_DURATION} = 0;
            if ($self->{TOTAL} > 0) {
              $self->{LOG_DURATION} = $self->{list}->[0]->[0];
            }
            if ($RAD->{ACCT_SESSION_TIME} + $self->{LOG_DURATION} < $self->{PREPAID_TIME}) {
              $self->{PERIODS_TIME_TARIF} = undef;
            }
            elsif ($self->{LOG_DURATION} < $self->{PREPAID_TIME} && $RAD->{ACCT_SESSION_TIME} + $self->{LOG_DURATION} > $self->{PREPAID_TIME}) {
              $self->{PAID_SESSION_TIME} = $RAD->{ACCT_SESSION_TIME};
            }
          }
        }

        #Id defined time tarif
        if ($self->{PERIODS_TIME_TARIF}) {
          my $duration = $self->{PAID_SESSION_TIME} || $RAD->{ACCT_SESSION_TIME};

          if ($self->{TIME_DIVISION}) {
            my $periods = $duration / $self->{TIME_DIVISION};
            if ($periods != int($periods)) {
              $duration = $self->{TIME_DIVISION} * (int($periods) + 1);
            }
          }

          $Billing->time_calculation(
            {
              REDUCTION          => $self->{REDUCTION},
              TIME_INTERVALS     => $self->{TIME_PERIODS},
              PERIODS_TIME_TARIF => $self->{PERIODS_TIME_TARIF},
              SESSION_START      => $self->{SESSION_STOP} - $RAD->{ACCT_SESSION_TIME},
              ACCT_SESSION_TIME  => $duration,
              DAY_BEGIN          => $self->{DAY_BEGIN},
              DAY_OF_WEEK        => $self->{DAY_OF_WEEK},
              DAY_OF_YEAR        => $self->{DAY_OF_YEAR},
              PRICE_UNIT         => 'Min',
            }
          );

          $sesssion_sum = $Billing->{SUM};
          if ($Billing->{errno}) {
            $self->{errno}  = $Billing->{errno};
            $self->{errstr} = $Billing->{errstr};
            return $self;
          }
        }
      }

      my $filename;
      $self->query2("INSERT INTO voip_log (uid, start, duration, calling_station_id, called_station_id,
              nas_id, client_ip_address, acct_session_id, 
              tp_id, bill_id, sum,
              terminate_cause, route_id) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}),  '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', 
        '$NAS->{NAS_ID}', INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'), '$RAD->{ACCT_SESSION_ID}', 
        '$self->{TP_ID}', '$self->{BILL_ID}', '$sesssion_sum',
        '$RAD->{ACCT_TERMINATE_CAUSE}', '$self->{ROUTE_ID}');", 'do'
      );

      if ($self->{errno}) {
        $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
        $self->{LOG_WARNING} = "ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
        $Billing->mk_session_log($RAD);
      }

      # If SQL query filed
      else {
        if ($Billing->{SUM} > 0) {
          $self->query2("UPDATE bills SET deposit=deposit-$Billing->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
        }
      }
    }
    else {

    }

    # Delete from session wtmp
    $self->query2("DELETE FROM voip_calls 
     WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
     and nas_id='$NAS->{NAS_ID}'
     and conf_id='$RAD->{H323_CONF_ID}';", 'do'
    );
  }

  #Alive status 3
  elsif ($acct_status_type eq 3) {
    $self->query2("UPDATE voip_calls SET
    status='$acct_status_type',
    client_ip_address=INET_ATON('". ($RAD->{FRAMED_IP_ADDRESS}|| '0.0.0.0') ."'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
    user_name='$RAD->{USER_NAME}';", 'do'
    );
  }
  else {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
  }

  if ($self->{errno}) {
    $self->{errno}  = 1;
    $self->{errstr} = "ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error: $self->{errstr}";
  }

  return $self;
}


#**********************************************************
# generate_DigestResponce(
#          $digest{'Digest-User-Name'},
#          $digest{'Digest-Realm'},
#          $digest{'Digest-Nonce'},
#          $digest{'Digest-URI'},
#          $RAD->{'Digest-Algorithm'},
#          $dbdata{'eppassword'}) ne $digest{'Digest-Response'}) { push(@errors,'1'); }
#**********************************************************
sub generate_DigestResponce {
  my ($username, $realm, $nonce, $uri, $method, $password) = @_;

  use Digest::MD5;
  my $md5 = new Digest::MD5; 
  my $a1 = new Digest::MD5; 
  my $a2 = new Digest::MD5;

  $md5->reset; 
  $a1->reset; 
  $a2->reset;

  $a1->add("$username:$realm:$password");
  $a2->add("$method:$uri");

  my $s1 = $a1->hexdigest();
  my $s2 = $a2->hexdigest();

  $md5->add($s1.":$nonce:".$s2);

  return $md5 -> hexdigest();
}


1


__END__


=comments


rad_recv: Access-Request packet from host 77.232.143.240 port 60567, id=180, length=332
        NAS-IP-Address = 172.16.16.5
        NAS-Port = 48359
        NAS-Port-Type = Async
        Service-Type = Login-User
        Framed-Protocol = SLIP
        User-Name = "0074832599457"
        Called-Station-Id = "675065"
        Calling-Station-Id = "0074832599457"
        h323-conf-id = "110003f6 52fa39eb 110003f6 52fa39eb"
        h323-gw-id = "172.16.16.5"
        Attr-108 = 0x494e56495445
        Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
        Attr-104 = 0x3137322e31362e31362e35
        Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
        Attr-111 = 0x4d4435
        Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
        Attr-115 = 0x30303734383332353939343537
        Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
        Message-Authenticator = 0xd38fa8f62b39364fd4f88ff5a39ac704
# Executing section authorize from file /usr/local/freeradius/etc/raddb/sites-enabled/abills_default
+group authorize {
++[preprocess] = ok
++[mschap] = noop
[files] users: Matched entry DEFAULT at line 38
++[files] = ok
rlm_perl: Added pair Attr-111 = 0x4d4435
rlm_perl: Added pair NAS-Port-Type = Async
rlm_perl: Added pair Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
rlm_perl: Added pair Attr-108 = 0x494e56495445
rlm_perl: Added pair h323-gw-id = 172.16.16.5
rlm_perl: Added pair Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
rlm_perl: Added pair Service-Type = Login-User
rlm_perl: Added pair Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
rlm_perl: Added pair Called-Station-Id = 675065
rlm_perl: Added pair Message-Authenticator = 0xd38fa8f62b39364fd4f88ff5a39ac704
rlm_perl: Added pair h323-conf-id = 110003f6 52fa39eb 110003f6 52fa39eb
rlm_perl: Added pair NAS-IP-Address = 172.16.16.5
rlm_perl: Added pair Attr-104 = 0x3137322e31362e31362e35
rlm_perl: Added pair Calling-Station-Id = 0074832599457
rlm_perl: Added pair Framed-Protocol = SLIP
rlm_perl: Added pair Attr-115 = 0x30303734383332353939343537
rlm_perl: Added pair User-Name = 0074832599457
rlm_perl: Added pair Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
rlm_perl: Added pair NAS-Port = 48359
rlm_perl: Added pair Reply-Message = Unknow server '172.16.16.5'
rlm_perl: Added pair Auth-Type = Perl
++[perl] = reject
+} # group authorize = reject
Using Post-Auth-Type REJECT
# Executing group from file /usr/local/freeradius/etc/raddb/sites-enabled/abills_default
+group REJECT {
!!!!!!!!!!!!!!!!!! Can't connect db: 0 !!!!!!!!!!!!!!
rlm_perl: Added pair NAS-Port-Type = Async
rlm_perl: Added pair Attr-111 = 0x4d4435
rlm_perl: Added pair Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
rlm_perl: Added pair h323-gw-id = 172.16.16.5
rlm_perl: Added pair Attr-108 = 0x494e56495445
rlm_perl: Added pair Service-Type = Login-User
rlm_perl: Added pair Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
rlm_perl: Added pair Called-Station-Id = 675065
rlm_perl: Added pair Message-Authenticator = 0xd38fa8f62b39364fd4f88ff5a39ac704
rlm_perl: Added pair NAS-IP-Address = 172.16.16.5
rlm_perl: Added pair h323-conf-id = 110003f6 52fa39eb 110003f6 52fa39eb
rlm_perl: Added pair Attr-104 = 0x3137322e31362e31362e35
rlm_perl: Added pair Calling-Station-Id = 0074832599457
rlm_perl: Added pair X-Ascend-Modem-ShelfNo = 0x7369703a30303734383332353939343537403137322e31362e31362e35
rlm_perl: Added pair Framed-Protocol = SLIP
rlm_perl: Added pair User-Name = 0074832599457
rlm_perl: Added pair Attr-115 = 0x30303734383332353939343537
rlm_perl: Added pair Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
rlm_perl: Added pair NAS-Port = 48359
rlm_perl: Added pair Reply-Message = Unknow server '172.16.16.5'
rlm_perl: Added pair Auth-Type = Perl
rlm_perl: Added pair Post-Auth-Type = REJECT
++[perl] = ok
+} # group REJECT = ok
Delaying reject of request 0 for 1 seconds
Going to the next request
Waking up in 0.9 seconds.
rad_recv: Access-Request packet from host 77.232.143.240 port 53749, id=180, length=332
        NAS-IP-Address = 172.16.16.5
        NAS-Port = 48359
        NAS-Port-Type = Async
        Service-Type = Login-User
        Framed-Protocol = SLIP
        User-Name = "0074832599457"
        Called-Station-Id = "675065"
        Calling-Station-Id = "0074832599457"
        h323-conf-id = "110003f6 52fa39eb 110003f6 52fa39eb"
        h323-gw-id = "172.16.16.5"
        Attr-108 = 0x494e56495445
        Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
        Attr-104 = 0x3137322e31362e31362e35
        Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
        Attr-111 = 0x4d4435
        Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
        Attr-115 = 0x30303734383332353939343537
        Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
        Message-Authenticator = 0x28172d0246806e3815f62676d3105641
# Executing section authorize from file /usr/local/freeradius/etc/raddb/sites-enabled/abills_default
+group authorize {
++[preprocess] = ok
++[mschap] = noop
[files] users: Matched entry DEFAULT at line 38
++[files] = ok
rlm_perl: Added pair Attr-111 = 0x4d4435
rlm_perl: Added pair NAS-Port-Type = Async
rlm_perl: Added pair Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
rlm_perl: Added pair Attr-108 = 0x494e56495445
rlm_perl: Added pair h323-gw-id = 172.16.16.5
rlm_perl: Added pair Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
rlm_perl: Added pair Service-Type = Login-User
rlm_perl: Added pair Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
rlm_perl: Added pair Called-Station-Id = 675065
rlm_perl: Added pair Message-Authenticator = 0x28172d0246806e3815f62676d3105641
rlm_perl: Added pair h323-conf-id = 110003f6 52fa39eb 110003f6 52fa39eb
rlm_perl: Added pair NAS-IP-Address = 172.16.16.5
rlm_perl: Added pair Attr-104 = 0x3137322e31362e31362e35
rlm_perl: Added pair Calling-Station-Id = 0074832599457
rlm_perl: Added pair Framed-Protocol = SLIP
rlm_perl: Added pair Attr-115 = 0x30303734383332353939343537
rlm_perl: Added pair User-Name = 0074832599457
rlm_perl: Added pair Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
rlm_perl: Added pair NAS-Port = 48359
rlm_perl: Added pair Reply-Message = Unknow server '172.16.16.5'
rlm_perl: Added pair Auth-Type = Perl
++[perl] = reject
+} # group authorize = reject
Using Post-Auth-Type REJECT
# Executing group from file /usr/local/freeradius/etc/raddb/sites-enabled/abills_default
+group REJECT {
!!!!!!!!!!!!!!!!!! Can't connect db: 0 !!!!!!!!!!!!!!
rlm_perl: Added pair NAS-Port-Type = Async
rlm_perl: Added pair Attr-111 = 0x4d4435
rlm_perl: Added pair Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
rlm_perl: Added pair h323-gw-id = 172.16.16.5
rlm_perl: Added pair Attr-108 = 0x494e56495445
rlm_perl: Added pair Service-Type = Login-User
rlm_perl: Added pair Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
rlm_perl: Added pair Called-Station-Id = 675065
rlm_perl: Added pair Message-Authenticator = 0x28172d0246806e3815f62676d3105641
rlm_perl: Added pair NAS-IP-Address = 172.16.16.5
rlm_perl: Added pair h323-conf-id = 110003f6 52fa39eb 110003f6 52fa39eb
rlm_perl: Added pair Attr-104 = 0x3137322e31362e31362e35
rlm_perl: Added pair Calling-Station-Id = 0074832599457
rlm_perl: Added pair X-Ascend-Modem-ShelfNo = 0x7369703a30303734383332353939343537403137322e31362e31362e35
rlm_perl: Added pair Framed-Protocol = SLIP
rlm_perl: Added pair User-Name = 0074832599457
rlm_perl: Added pair Attr-115 = 0x30303734383332353939343537
rlm_perl: Added pair Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
rlm_perl: Added pair NAS-Port = 48359
rlm_perl: Added pair Reply-Message = Unknow server '172.16.16.5'
rlm_perl: Added pair Auth-Type = Perl
rlm_perl: Added pair Post-Auth-Type = REJECT
++[perl] = ok
+} # group REJECT = ok
Delaying reject of request 1 for 1 seconds
Going to the next request
Waking up in 0.2 seconds.
Sending delayed reject for request 0
Sending Access-Reject of id 180 to 77.232.143.240 port 60567
        Reply-Message = "Unknow server '172.16.16.5'"
Waking up in 0.7 seconds.
rad_recv: Access-Request packet from host 77.232.143.240 port 51029, id=180, length=332
        NAS-IP-Address = 172.16.16.5
        NAS-Port = 48359
        NAS-Port-Type = Async
        Service-Type = Login-User
        Framed-Protocol = SLIP
        User-Name = "0074832599457"
        Called-Station-Id = "675065"
        Calling-Station-Id = "0074832599457"
        h323-conf-id = "110003f6 52fa39eb 110003f6 52fa39eb"
        h323-gw-id = "172.16.16.5"
        Attr-108 = 0x494e56495445
        Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
        Attr-104 = 0x3137322e31362e31362e35
        Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
        Attr-111 = 0x4d4435
        Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
        Attr-115 = 0x30303734383332353939343537
        Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
        Message-Authenticator = 0xa42b52aa932d8a8b6042d3faebfa0947
# Executing section authorize from file /usr/local/freeradius/etc/raddb/sites-enabled/abills_default
+group authorize {
++[preprocess] = ok
++[mschap] = noop
[files] users: Matched entry DEFAULT at line 38
++[files] = ok
rlm_perl: Added pair Attr-111 = 0x4d4435
rlm_perl: Added pair NAS-Port-Type = Async
rlm_perl: Added pair Attr-109 = 0x7369703a363735303635403137322e31362e31362e35
rlm_perl: Added pair Attr-108 = 0x494e56495445
rlm_perl: Added pair h323-gw-id = 172.16.16.5
rlm_perl: Added pair Attr-103 = 0x6364353439363637353137666532313438303233656462386261366262393462
rlm_perl: Added pair Service-Type = Login-User
rlm_perl: Added pair Attr-122 = 0x7369703a30303734383332353939343537403137322e31362e31362e35
rlm_perl: Added pair Called-Station-Id = 675065
rlm_perl: Added pair Message-Authenticator = 0xa42b52aa932d8a8b6042d3faebfa0947
rlm_perl: Added pair h323-conf-id = 110003f6 52fa39eb 110003f6 52fa39eb
rlm_perl: Added pair NAS-IP-Address = 172.16.16.5
rlm_perl: Added pair Attr-104 = 0x3137322e31362e31362e35
rlm_perl: Added pair Calling-Station-Id = 0074832599457
rlm_perl: Added pair Framed-Protocol = SLIP
rlm_perl: Added pair Attr-115 = 0x30303734383332353939343537
rlm_perl: Added pair User-Name = 0074832599457
rlm_perl: Added pair Attr-105 = 0x6535643335393463653437643864626533313364363563383635646366346539
rlm_perl: Added pair NAS-Port = 48359
rlm_perl: Added pair Reply-Message = Unknow server '172.16.16.5'
rlm_perl: Added pair Auth-Type = Perl
++[perl] = reject
+} # group authorize = reject
rad_recv: Accounting-Request packet from host 77.232.143.240 port 60841, id=42, length=683
        Acct-Status-Type = Start
        User-Name = "0074832599457"
        Calling-Station-Id = "0074832599457"
        Called-Station-Id = "675065"
        Acct-Session-Id = "110003f6 52fa39ed 2830f830 28fd2a93"
        Event-Timestamp = "����. 11 2014 16:55:42 EET"
        NAS-Port = 285213686
        NAS-Port-Type = Async
        Cisco-NAS-Port = "SIPT:03f6"
        Cisco-AVPair = "xpgk-src-number-in=0074832599457"
        Cisco-AVPair = "xpgk-src-number-out=599457"
        Cisco-AVPair = "xpgk-dst-number-in=675065"
        Cisco-AVPair = "xpgk-dst-number-out=675065"
        Cisco-AVPair = "xpgk-route-retries=1"
        Cisco-AVPair = "h323-remote-id=TrunkGroup00"
        Cisco-AVPair = "h323-call-id=110003f6 52fa39ed 2830f830 28fd2a93"
        Cisco-AVPair = "h323-incoming-conf-id=110003f6 52fa39ed 2830f830 28fd2a93"
        h323-conf-id = "110003f6 52fa39ed 2830f830 28fd2a93"
        h323-setup-time = "18:55:41.000 GMT+4 Tue Feb 11 2014"
        h323-call-origin = "originate"
        h323-call-type = "VoIP"
        h323-connect-time = "18:55:42.000 GMT+4 Tue Feb 11 2014"
        Acct-Delay-Time = 1
        NAS-IP-Address = 172.16.16.5
        Cisco-AVPair = "h323-gw-address=172.16.16.5"
        h323-gw-id = "172.16.16.5"
rad_recv: Accounting-Request packet from host 77.232.143.240 port 60841, id=43, length=706
        Acct-Status-Type = Interim-Update
        User-Name = "0074832599457"
        Calling-Station-Id = "0074832599457"
        Called-Station-Id = "675065"
        Acct-Session-Id = "110003f6 52fa39ed 2830f830 28fd2a93"
        Event-Timestamp = "����. 11 2014 16:56:02 EET"
        NAS-Port = 285213686
        NAS-Port-Type = Async
        Cisco-NAS-Port = "SIPT:03f6"
        Cisco-AVPair = "xpgk-src-number-in=0074832599457"
        Cisco-AVPair = "xpgk-src-number-out=599457"
        Cisco-AVPair = "xpgk-dst-number-in=675065"
        Cisco-AVPair = "xpgk-dst-number-out=675065"
        Cisco-AVPair = "xpgk-route-retries=1"
        Cisco-AVPair = "h323-remote-id=TrunkGroup00"
        Cisco-AVPair = "h323-call-id=110003f6 52fa39ed 2830f830 28fd2a93"
        Cisco-AVPair = "h323-incoming-conf-id=110003f6 52fa39ed 2830f830 28fd2a93"
        h323-conf-id = "110003f6 52fa39ed 2830f830 28fd2a93"
        h323-setup-time = "18:55:41.000 GMT+4 Tue Feb 11 2014"
        h323-call-origin = "originate"
        h323-call-type = "VoIP"
        h323-connect-time = "18:55:42.000 GMT+4 Tue Feb 11 2014"
        Eltex-AVPair = "session-time=19"
        Acct-Delay-Time = 5
        NAS-IP-Address = 172.16.16.5
        Cisco-AVPair = "h323-gw-address=172.16.16.5"
        h323-gw-id = "172.16.16.5"

Sending Accounting-Response of id 43 to 77.232.143.240 port 60841
        Reply-Message = "Unknow server '172.16.16.5'"
Finished request 4.
Cleaning up request 4 ID 43 with timestamp +94
Going to the next request
Ready to process requests.
rad_recv: Accounting-Request packet from host 77.232.143.240 port 60841, id=44, length=801
        Acct-Status-Type = Stop
        User-Name = "0074832599457"
        Calling-Station-Id = "0074832599457"
        Called-Station-Id = "675065"
        Acct-Session-Id = "110003f6 52fa39ed 2830f830 28fd2a93"
        Event-Timestamp = "����. 11 2014 16:56:21 EET"
        NAS-Port = 285213686
        NAS-Port-Type = Async
        Cisco-NAS-Port = "SIPT:03f6"
        Cisco-AVPair = "xpgk-src-number-in=0074832599457"
        Cisco-AVPair = "xpgk-src-number-out=599457"
        Cisco-AVPair = "xpgk-dst-number-in=675065"
        Cisco-AVPair = "xpgk-dst-number-out=675065"
        Cisco-AVPair = "xpgk-route-retries=1"
        Cisco-AVPair = "h323-remote-id=TrunkGroup00"
        Cisco-AVPair = "h323-call-id=110003f6 52fa39ed 2830f830 28fd2a93"
        Cisco-AVPair = "h323-incoming-conf-id=110003f6 52fa39ed 2830f830 28fd2a93"
        h323-conf-id = "110003f6 52fa39ed 2830f830 28fd2a93"
        h323-setup-time = "18:55:41.000 GMT+4 Tue Feb 11 2014"
        h323-call-origin = "originate"
        h323-call-type = "VoIP"
        h323-connect-time = "18:55:42.000 GMT+4 Tue Feb 11 2014"
        h323-disconnect-time = "18:56:22.000 GMT+4 Tue Feb 11 2014"
        h323-disconnect-cause = "10"
        Cisco-AVPair = "xpgk-local-disconnect-cause=1"
        Acct-Session-Time = 40
        Eltex-AVPair = "session-time=40"
        Acct-Delay-Time = 2
        NAS-IP-Address = 172.16.16.5
        Cisco-AVPair = "h323-gw-address=172.16.16.5"
        h323-gw-id = "172.16.16.5"

Sending Accounting-Response of id 44 to 77.232.143.240 port 60841
        Reply-Message = "Unknow server '172.16.16.5'"
Finished request 5.
Cleaning up request 5 ID 44 with timestamp +113
Going to the next request
Ready to process requests.



=cut