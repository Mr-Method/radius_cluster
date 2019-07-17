#!perl
=head1 NAME

  Users slides

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sec2date);
our Users $users;

our(
  %lang,
  $html,
  $db,
  $admin,
  $user,
  %permissions
);

#**********************************************************
=head2 quick_info_user($attr) User information for slides

=cut
#**********************************************************
sub quick_info_user {
  my ($attr)  = @_;

  if($user && ref $user eq 'Users') {
    $users = $user;
  }

  $users->info($attr->{UID});

  if ($permissions{0} && !$permissions{0}{12}) {
    $users->{DEPOSIT} = '--';
  }

  if($users->{DISABLE}) {
    $users->{DISABLE} = $lang{DISABLE};
  }
  else {
    $users->{DISABLE} = $lang{ENABLE};
  }

  return $users;
}

#**********************************************************
=head2 quick_info_portal_session() User portal sessions

=cut
#**********************************************************
sub quick_info_portal_session {
  my ($attr)  = @_;

  $users->web_session_info({ UID => $attr->{UID} });
  $users->{DATETIME}=sec2date($users->{DATETIME});

  return $users;
}

#**********************************************************
=head2 quick_info_pi() User personal  information for slides

=cut
#**********************************************************
sub quick_info_pi {
  my ($attr)  = @_;

  $users->pi({ UID => $attr->{UID} });

  return $users;
}

#**********************************************************
=head2 quick_info_payments() User personal  information for slides

=cut
#**********************************************************
sub quick_info_payments {
  my ($attr)  = @_;

  my $Payments = Finance->payments($db, $admin, \%conf);

  my $list = $Payments->list({
    UID          => $attr->{UID},
    DESCRIBE     => '_SHOW',
    DATETIME     => '_SHOW',
    SUM          => '_SHOW',
    METHOD       => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    COLS_UPPER   => 1,
    PAGE_ROWS    => 1
  });

  my $result = [];
  if($Payments->{TOTAL} && $Payments->{TOTAL} > 0) {
    #_bp($Payments->{TOTAL}, $list);
    $result = $list->[0];
    my $payments_methods = get_payment_methods();
    $result->{METHOD} = $payments_methods->{$result->{METHOD}};
  }

  return $result;
}

#**********************************************************
=head2 quick_info_fees() User personal  information for slides

=cut
#**********************************************************
sub quick_info_fees {
  my ($attr)  = @_;

  my $Fees = Finance->fees($db, $admin, \%conf);

  my $list = $Fees->list({
    UID          => $attr->{UID},
    DATETIME     => '_SHOW',
    SUM          => '_SHOW',
    LAST_DEPOSIT => '_SHOW',
    METHOD       => '_SHOW',
    DESC         => 'DESC',
    COLS_NAME    => 1,
    COLS_UPPER   => 1,
    PAGE_ROWS    => 1
  });

  my $result = $list->[0];

  return $result;
}

#**********************************************************
=head2 form_slides_info() - Slides information
=cut
#**********************************************************
sub form_slides_info {

  my @base_slides = (
    { ID     => 'MAIN_INFO',
      HEADER => "$lang{USER}",
      PROPORTION => 3,
      FIELDS => {
        LOGIN  => $lang{LOGIN},
        DEPOSIT=> $lang{DEPOSIT},
        CREDIT => $lang{CREDIT},
        UID    => 'UID',
        DISABLE=> $lang{STATUS},
      },
      FN      => 'quick_info_user',
    },
    { ID     => 'PERSONAL_INFO',
      HEADER => $lang{USER_INFO},
      PROPORTION => 3,
      FIELDS => {
        EMAIL       => 'E-mail',
        FIO         => $lang{FIO},
        PHONE       => $lang{PHONE},
        CONTRACT_ID => $lang{CONTRACT},
        COMMENTS    => $lang{COMMENTS},
      },
      FN      => 'quick_info_pi'
    },
    { ID     => 'INFO_FIELDS',
      HEADER => $lang{INFO_FIELDS},
      FIELDS => {
      },
      FN      => 'quick_info_info_fields'
    },
    { ID     => 'PAYMENTS',
      HEADER => $lang{PAYMENTS},
      PROPORTION => 3,
      FIELDS => {
        DATETIME     => $lang{DATE},
        SUM          => $lang{SUM},
        METHOD       => $lang{PAYMENT_METHOD},
        LAST_DEPOSIT => $lang{DEPOSIT}
      },
      FN      => 'quick_info_payments'
    },
    { ID     => 'FEES',
      HEADER => $lang{FEES},
      PROPORTION => 3,
      FIELDS => {
        DATETIME     => $lang{DATE},
        SUM          => $lang{SUM},
        METHOD       => $lang{TYPE},
        LAST_DEPOSIT => $lang{DEPOSIT}
      },
      FN      => 'quick_info_fees'
    },
    { ID     => 'PORTAL_SESSION',
      PROPORTION => 3,
      HEADER => $lang{USER_PORTAL},
      FIELDS => {
        DATETIME    => $lang{DATE},
        LOGIN       => 'LOGIN',
        REMOTE_ADDR => 'IP',
        #ACTIVATE    => $lang{ACTIVE},
        SID         => 'sid'
      },
      FN      => 'quick_info_portal_session'
    },
  );

  foreach my $module (@MODULES) {
    load_module($module, $html);
    my $fn = lc($module) . '_quick_info';
    if (defined(&$fn)) {
      my $slide_info = &{ \&$fn }({ GET_PARAMS => 1 });

      $slide_info->{FN} = $fn;
      $slide_info->{ID} = uc($module);
      $slide_info->{MODULE} = $module;
      push @base_slides, $slide_info;
    }
  }

  require Admin_slides;
  my $Admin_slides = Admin_slides->new($db, $admin, \%conf);

  if ($FORM{action}) {
    $Admin_slides->add(\%FORM);
  }

  my $list = $Admin_slides->list({
    AID       => $admin->{AID},
    SIZE      => '_SHOW',
    PRIORITY  => '_SHOW',
    COLS_NAME => 1
  });

  my %admin_slides = ();

  foreach my $line (@$list) {
    $admin_slides{$line->{slide_name}}{$line->{field_id}}       = 1;
    $admin_slides{$line->{slide_name}}{'w_'. $line->{field_id}} = $line->{field_warning};
    $admin_slides{$line->{slide_name}}{'c_'. $line->{field_id}} = $line->{field_comments};
    $admin_slides{$line->{slide_name}}{'PRIORITY'}              = $line->{priority};
    $admin_slides{$line->{slide_name}}{'SIZE'}                  = $line->{size};
  }

  return \@base_slides, \%admin_slides;
}

#**********************************************************
=head2 user_full_info($attr) - Show user json info

  Arguments:
    $attr
      SHOW_ID   -
      UID

=cut
#**********************************************************
sub user_full_info {
  my ($attr) = @_;

  my ($base_slides, $active_slides) = form_slides_info();
  my $content;
  my $info     = '';
  my @info_arr = ();
  my $uid      = $attr->{UID} || $FORM{UID} || $LIST_PARAMS{UID};

  if(! $uid) {
    push @info_arr, q/{ "ERROR" : 'Undefined UID' }/;
    return $info = "[". join(",\n", @info_arr) ."]";
  }

  for(my $slide_num=0; $slide_num <= $#{ $base_slides }; $slide_num++ ) {
    my @content_arr = ();

    my $slide_name   = $base_slides->[$slide_num]->{ID};

    if (scalar keys %$active_slides > 0 && ! $active_slides->{$slide_name} ) {
      next;
    }

    my $field_info;
    if($base_slides->[$slide_num]->{FN}) {
      if(defined(&{$base_slides->[$slide_num]{FN}}))  {
        my $fn = $base_slides->[$slide_num]->{FN};
        $field_info = &{ \&$fn }({ UID => $uid });
        next if (!$field_info);
      }
      else {
        next;
      }
    }

    if ($base_slides->[$slide_num]{SLIDES}) {
      my @slides = ();
      foreach my $slide_line ( @{ $field_info } ) {
        my @slide_arr = ();
        foreach my $filed_name ( @{ $base_slides->[$slide_num]->{SLIDES} }) {
          while(my ($k, $v) = each %$filed_name) {
            push @slide_arr, (($attr->{SHOW_ID}) ? qq{"$k" : "} : '"'. ((defined($v)) ? $v : q{}) .'" : "')
              . ((defined($slide_line->{$k})) ? $slide_line->{$k} : q{}) . '"';
          }
        }
        push @slides, '{'. join(', ', @slide_arr) .'}';
      }

      $content = '"SLIDES": [ '. join(",\n", @slides ) .' ]' ;
    }
    else {
      foreach my $field_name ( sort keys %{ $base_slides->[$slide_num]{FIELDS} } ) {
        $field_name //= '';
        my $field_value = ($base_slides->[$slide_num]{FIELDS}->{$field_name}) ? $base_slides->[$slide_num]{FIELDS}->{$field_name} : q{};
        if($conf{DEPOSIT_FORMAT} && $field_name eq 'DEPOSIT') {
          $field_info->{$field_name} = sprintf("$conf{DEPOSIT_FORMAT}", $field_info->{$field_name}) if ($field_info->{$field_name} =~ /\d+/);
        }

        my $information = (($attr->{SHOW_ID}) ? qq{"$field_name" : "} : qq{"$field_value" : "});
          if(ref $field_info eq 'ARRAY') {
           $information .= '-';
         }
         elsif(defined($field_info->{$field_name})) {
           $information .= $field_info->{$field_name};
         }

        $information .= qq{" };

        push @content_arr, $information;
      }

      $content = '"CONTENT" : {'. join(",\n", @content_arr) . '}' ;
    }

    foreach my $field_name ( keys %{ $base_slides->[$slide_num]{FIELDS} } ) {
      my $field_value = ($base_slides->[$slide_num]{FIELDS}->{$field_name}) ? $base_slides->[$slide_num]{FIELDS}->{$field_name} : q{};
      push @content_arr, qq{"$field_value" : "}. (ref $field_info eq 'HASH' && defined($field_info->{$field_name}) ? $field_info->{$field_name} : $field_name ) . qq{" };
    }

    my $slide_info =  qq/
  "NAME": "$slide_name",
  "HEADER": "/. ( $base_slides->[$slide_num]->{HEADER} || $slide_name ) . qq/",
  "SIZE": "/. (($active_slides->{$slide_name} && $active_slides->{$slide_name}->{SIZE}) ? $active_slides->{$slide_name}->{SIZE} : 1 ) . qq/",
  "PROPORTION": "/ . ( $base_slides->[$slide_num]->{PROPORTION} || 2 ) . '",'
  . (($base_slides->[$slide_num]->{MODULE}) ? qq/"MODULE" : "$base_slides->[$slide_num]->{MODULE}",\n/ : '')
  . (($base_slides->[$slide_num]->{QUICK_TPL}) ? qq/"QUICK_TPL" : "$base_slides->[$slide_num]->{QUICK_TPL}",\n/ : '')
  . qq/$content /;
    push @info_arr, "{ $slide_info }";
  }

  $info = "[". join(",\n", @info_arr) ."]";

  return $info;
}

1;
