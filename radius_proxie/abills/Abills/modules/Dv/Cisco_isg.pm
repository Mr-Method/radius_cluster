=head2 NAME

  Cisco ISG web requests

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(ip2int);
use Radius;

our(
  $db,
  $admin,
  %conf,
  $html,
  $base_dir,
  %lang,
  $Isg
);

our Log $Log;
my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 cisco_isg_cmd($user_ip, $command, $attr) - Cisco ISG functions
  Arguments:
    $user_ip - User IP
    $command - Command
       account-status-query
       account-logon
       deactivate-service
       activate-service
       account-logon
       account-logoff

    $attr    -
      USER_NAME
      SERVICE_NAME
      CURE_SERVICE
      User-Password

  Results:
    True or False

=cut
#**********************************************************
sub cisco_isg_cmd {
  my ($user_ip, $command, $attr) = @_;

  my $debug = $conf{ISG_DEBUG} || 0;
  my $service_name = $attr->{SERVICE_NAME};

  if ($debug > 0) {
    print "Content-Type: text/html\n\n";
    print "Command: $command" . $html->br();
    print "User name: $attr->{USER_NAME}" . $html->br();
    print "User IP: $user_ip" . $html->br();
  }

  if (! $conf{DV_ISG}) {
    return 1;
  }

  #Get user NAS server from ip pools
  if (!$Nas->{NAS_ID}) {
    my $list = $Nas->nas_ip_pools_list({ COLS_NAME => 1 });
    foreach my $line (@$list) {
      if ($line->{ip} <= ip2int($user_ip) && ip2int($user_ip) <= $line->{last_ip_num}) {
        $Nas->info({ NAS_ID => $line->{active_nas_id} });
        last;
      }
    }
  }

  if (!$Nas->{NAS_ID}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_UNKNOWN_IP}, { ID => 913 });
    return 0;
  }

  #Get Active session info
  my %RAD_PAIRS = ();
  my $type;

  my $r = Radius->new(
    Host   => $Nas->{NAS_MNG_IP_PORT},
    Secret => $Nas->{NAS_MNG_PASSWORD}
  ) or return "Can't connect '$Nas->{NAS_MNG_IP_PORT}' $!";

  $conf{'dictionary'} = $base_dir . '/lib/dictionary' if (!$conf{'dictionary'});
  $r->load_dictionary($conf{'dictionary'});

  $r->clear_attributes();
  $r->add_attributes({ Name => 'User-Name',          Value => "$attr->{USER_NAME}" });
  $r->add_attributes({ Name => 'Cisco-Account-Info', Value => "S$user_ip" });
  $r->add_attributes({ Name => 'Cisco-AVPair',       Value => "subscriber:command=$command" });

  # Deactivate cur service
  if ($attr->{CURE_SERVICE}) {
    $r->add_attributes({ Name => 'Cisco-AVPair', Value => "subscriber:service-name=$attr->{CURE_SERVICE}" });
  }

  if($attr->{'User-Password'}) {
    $r->add_attributes({ Name => 'User-Password',  Value => $attr->{'User-Password'} });
  }

  $r->send_packet(43) and $type = $r->recv_packet;

  if (!defined $type) {
    my $message = "No responce from CoA server NAS ID: $Nas->{NAS_ID} '$Nas->{NAS_MNG_IP_PORT}' $! / ";
    $html->message('err', $lang{ERROR}, $message, { ID => 106 });
    $Log->log_add(
      {
        LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
        ACTION    => 'AUTH',
        USER_NAME => $attr->{USER_NAME} || '-',
        MESSAGE   => $message,
        DB        => 1,
        NAS_ID    => $Nas->{NAS_ID} || 0
      }
    );

    return 0;
  }

  if ($command eq 'account-status-query') {
    for my $ra ($r->get_attributes) {
      if ($ra->{'Value'} =~ /\$MA(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }
      elsif($ra->{'Name'} eq 'Reply-Message') {
        $Isg->{MESSAGE} = $ra->{'Value'};
      }
      elsif ($ra->{'Value'} =~ /^S(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }
      elsif ($ra->{'Value'} =~ /^N1TURBO_SPEED(\d+);(\d+)/) {
        $Isg->{TURBO_MODE_RUN} = $2 || '';
      }
      elsif ($ra->{'Value'} =~ /^N1(TP_[0-9\_]+);(\d+)/) {
        $Isg->{CURE_SERVICE}         = $1 || '';
        $Isg->{ISG_SESSION_DURATION} = $2 || 0;
      }

      $RAD_PAIRS{ $ra->{'Name'} } = $ra->{'Value'};
      if ($debug > 0) {
        print "$ra->{'Name'} -> $ra->{'Value'}" . $html->br();
      }
    }

    # name=Cisco-Account-Info value=N1TP_100;3541;test;8657;8149;1781505;2915555
    # name=User-Name value=test
    # name=Cisco-Command-Code value=1
    # name=Cisco-Account-Info value=S85.132.11.5
    # name=Cisco-AVPair value=sg-version=1.0
    # name=Cisco-NAS-Port value=0/0/1/40
    # name=NAS-Port value=0
    # name=NAS-Port-Id value=0/0/1/40
    # name=Framed-IP-Address value=85.132.11.5 Content-Type: text/html

    # If ISG return error push error to log
    if ($RAD_PAIRS{'Error-Cause'}) {
      my $message = "NAS: $Nas->{NAS_ID}, $RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}";
      $html->message('err', $lang{ERROR}, $message, { ID => 100 });
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => $message,
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );

      return 0;
    }
    else {
      if (!$Isg->{ISG_CID_CUR}) {
        $html->message('err', $lang{ERROR}, "$lang{NOT_EXIST} ID: '$user_ip' ", { ID => 11 });
      }
      elsif ($Isg->{ISG_CID_CUR} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        my $DHCP_INFO = dv_dhcp_get_mac($Isg->{ISG_CID_CUR});
        $Isg->{ISG_CID_CUR} = $DHCP_INFO->{MAC} || '';
        if ($Isg->{ISG_CID_CUR} eq '') {
          $html->message('err', $lang{ERROR}, "IP: '$user_ip', MAC $lang{NOT_EXIST}. DHCP $lang{ERROR} ", { ID => 12 });
          return 0;
        }
      }
    }
  }
  elsif ($command eq 'deactivate-service') {
  }
  elsif ($command eq 'activate-service') {
    for my $ra ($r->get_attributes) {

      #MAC as ID
      if ($ra->{'Value'} =~ /\$MA(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1;
      }
      #IP user ID
      elsif ($ra->{'Value'} =~ /S(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }
      $RAD_PAIRS{ $ra->{'Name'} } = $ra->{'Value'};
    }

    if ($RAD_PAIRS{'Error-Cause'}) {
      $html->message('err', $lang{ERROR}, "$RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}", { ID => 101 });
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Service Enable IP: $user_ip '$service_name' Error: $RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{SERVICE} $lang{ENABLE}");
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Service Enable '$service_name' IP: $user_ip",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );
      return 0;
    }
  }
  elsif ($command eq 'account-logon') {
    for my $ra ($r->get_attributes) {
      #MAC as ID
      if ($ra->{'Value'} =~ /\$MA(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1;
      }

      #IP user ID
      elsif ($ra->{'Value'} =~ /S(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }
      $RAD_PAIRS{ $ra->{'Name'} } = $ra->{'Value'};

      if ($debug > 0) {
        print "$ra->{'Name'} -> $ra->{'Value'}" . $html->br();
      }
    }

    if ($RAD_PAIRS{'Error-Cause'}) {
      $html->message('err', $lang{ERROR}, "$lang{LOGON} $lang{ERROR} [$RAD_PAIRS{'Error-Cause'}] $RAD_PAIRS{'Reply-Message'}", { ID => 101 });
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Logon Error: $RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{LOGON}");
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Logon",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );

      return 0;
    }
  }
  elsif ($command eq 'account-logoff') {
    for my $ra ($r->get_attributes) {
      #MAC as ID
      if ($ra->{'Value'} =~ /\$MA(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }
      #IP user ID
      elsif ($ra->{'Value'} =~ /S(\S+)/) {
        $Isg->{ISG_CID_CUR} = $1 || '';
      }

      $RAD_PAIRS{ $ra->{'Name'} } = $ra->{'Value'};

      if ($debug > 0) {
        print "$ra->{'Name'} -> $ra->{'Value'}" . $html->br();
      }
    }

    if ($RAD_PAIRS{'Error-Cause'}) {
      $html->message('err', $lang{ERROR}, "$lang{LOGON} $lang{ERROR} [$RAD_PAIRS{'Error-Cause'}] $RAD_PAIRS{'Reply-Message'}", { ID => 101 });
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_WARNING'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Logon Error: $RAD_PAIRS{'Error-Cause'} / $RAD_PAIRS{'Reply-Message'}",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{LOGON}");
      $Log->log_add(
        {
          LOG_TYPE  => $Log::log_levels{'LOG_INFO'},
          ACTION    => 'AUTH',
          USER_NAME => $attr->{USER_NAME} || '-',
          MESSAGE   => "Logon",
          DB        => 1,
          NAS_ID    => $Nas->{NAS_ID} || 0
        }
      );

      return 0;
    }
  }

  return 1;
}


1;
