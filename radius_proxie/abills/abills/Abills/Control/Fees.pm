=head1 NAME

   Fees managment

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(date_diff in_array);

our(
  $db,
  $admin,
  %conf,
  %permissions,
  %lang,
  $html,
  @bool_vals,
  @state_colors
);


#**********************************************************
=head2 form_fees($attr)

=cut
#**********************************************************
sub form_fees {
  my ($attr) = @_;
  my $period = $FORM{period} || 0;

  return 0 if (!defined($permissions{2}));

  my $Fees = Finance->fees($db, $admin, \%conf);
  my %BILL_ACCOUNTS = ();

  my $FEES_METHODS = get_fees_types();

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    my $Shedule = Shedule->new($db, $admin, \%conf);

    if ($conf{EXT_BILL_ACCOUNT}) {
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{BILL_ID} } = "$lang{PRIMARY} : $attr->{USER_INFO}->{BILL_ID}" if ($attr->{USER_INFO}->{BILL_ID});
      $BILL_ACCOUNTS{ $attr->{USER_INFO}->{EXT_BILL_ID} } = "$lang{EXTRA} : $attr->{USER_INFO}->{EXT_BILL_ID}" if ($attr->{USER_INFO}->{EXT_BILL_ID});
    }

    if (! $user->{BILL_ID} || $user->{BILL_ID} < 1) {
      form_bills({ USER_INFO => $user });
      return 0;
    }

    $Fees->{UID} = $user->{UID};
    if ($FORM{take} && $FORM{SUM}) {
      $FORM{SUM} =~ s/,/\./g;

      # add to shedule
      if ($FORM{ER} && $FORM{ER} ne '') {
        my $er = $Fees->exchange_info($FORM{ER});
        $FORM{ER}  = $er->{ER_RATE};
        $FORM{SUM} = $FORM{SUM} / $FORM{ER};
      }

      if ($period == 2) {
        my $FEES_DATE = $FORM{DATE} || $DATE;
        if (date_diff($DATE, $FEES_DATE) < 1) {
          $Fees->take($user, $FORM{SUM}, \%FORM);
          if (! _error_show($Fees)) {
            $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM} $lang{DATE}: $FEES_DATE" );
          }
        }
        else {
          my ($Y, $M, $D) = split(/-/, $FEES_DATE);
          $FORM{METHOD} //= 0;
          $Shedule->add(
            {
              DESCRIBE => $FORM{DESCR},
              D        => $D,
              M        => $M,
              Y        => $Y,
              UID      => $user->{UID},
              TYPE     => 'fees',
              ACTION   => ($conf{EXT_BILL_ACCOUNT}) ? "$FORM{SUM}:$FORM{DESCRIBE}:BILL_ID=$FORM{BILL_ID}:$FORM{METHOD}" : "$FORM{SUM}:$FORM{DESCRIBE}::$FORM{METHOD}"
            }
          );

          if(! _error_show($Shedule)) {
            $html->message( 'info', $lang{SHEDULE}, $lang{ADDED});
          }
        }
      }

      #take now
      else {
        delete $FORM{DATE};
        $Fees->take($user, $FORM{SUM}, \%FORM);
        if (! _error_show($Fees)) {
          $html->message( 'info', $lang{FEES}, "$lang{TAKE} $lang{SUM}: $Fees->{SUM}" );

          #External script
          if ($conf{external_fees}) {
            if (!_external($conf{external_fees}, {%FORM})) {
              return 0;
            }
          }
        }
      }
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{2}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $lang{ERR_ACCESS_DENY}" );
        return 0;
      }

      $Fees->del($user, $FORM{del}, { COMMENTS => $FORM{COMMENTS} });

      if (! _error_show($Fees)) {
        $html->message( 'info', $lang{FEES}, "$lang{DELETED} ID: $FORM{del}" );
      }
    }

    my $list = $Shedule->list(
      {
        UID  => $user->{UID},
        TYPE => 'fees'
      }
    );

    if ($Shedule->{TOTAL} > 0) {
      my $table2 = $html->table(
        {
          width       => '100%',
          caption     => $lang{SHEDULE},
          title_plain => [ '#', $lang{DATE}, $lang{SUM}, '-' ],
          qs          => $pages_qs,
          ID          => 'USER_SHEDULE'
        }
      );

      foreach my $line (@$list) {
        my ($sum, undef) = split(/:/, $line->[7]);
        my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL}, "index=85&del=$line->[14]",
          { MESSAGE => "$lang{DEL} ID: $line->[13]?", class => 'del' } ) : '';

        $table2->addrow($line->[13], "$line->[3]-$line->[2]-$line->[1]", sprintf('%.2f', $sum), $delete);
      }

      $Fees->{SHEDULE_FORM} = $table2->show();
    }

    $Fees->{PERIOD_FORM} = form_period($period, { TD_EXDATA => "colspan='2'" });

    if ($permissions{2} && $permissions{2}{1}) {
      #exchange rate sel
      $Fees->{SEL_ER} = $html->form_select(
        'ER',
        {
          SELECTED   => undef,
          SEL_LIST   => $Fees->exchange_list({ COLS_NAME => 1 }),
          SEL_KEY    => 'id',
          SEL_VALUE  => 'money,short_name',
          NO_ID      => 1,
          MAIN_MENU     => get_function_index('form_exchange_rate'),
          MAIN_MENU_ARGV=> "chg=". ($FORM{ER} || q{}),
          SEL_OPTIONS=> { '' => ''}
        }
      );

      if ($conf{EXT_BILL_ACCOUNT}) {
        $Fees->{EXT_DATA_FORM}=$html->tpl_show(templates('form_row'), {
          ID    => 'BILL_ID',
          NAME  => $lang{BILL},
          VALUE => $html->form_select('BILL_ID',
            {
              SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
              SEL_HASH => \%BILL_ACCOUNTS,
              NO_ID    => 1
            }) }, { OUTPUT2RETURN => 1 });
      }

      $Fees->{SEL_METHOD} = $html->form_select(
        'METHOD',
        {
          SELECTED      => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
          SEL_HASH      => $FEES_METHODS,
          NO_ID         => 1,
          SORT_KEY_NUM  => 1,
          MAIN_MENU     => get_function_index('form_fees_types'),
        }
      );

      $html->tpl_show(templates('form_fees'), $Fees, { ID => 'form_fees' }) if (!$attr->{REGISTRATION});
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    form_users();
    return 0;
  }
  elsif ($index != 7) {
    $FORM{type} = $FORM{subf} if ($FORM{subf});
    if ($FORM{search_form} || $FORM{search}) {
      form_search(
        {
          HIDDEN_FIELDS => {
            ($FORM{DATE} ? (DATE => $FORM{DATE}) : ()),
            subf       => ($FORM{subf}) ? $FORM{subf} : undef,
            COMPANY_ID => $FORM{COMPANY_ID},
          }
        }
      );
    }
  }

  return 0 if (!$permissions{2}{0});

  form_fees_list({
    USER_INFO    => $attr->{USER_INFO},
    FEES_METHODS => $FEES_METHODS,
    BILL_ACCOUNTS=> \%BILL_ACCOUNTS
  });

  return 1;
}


#**********************************************************
=head2 form_fees_list($attr)

=cut
#**********************************************************
sub form_fees_list {
  my ($attr)=@_;

  my $FEES_METHODS = $attr->{FEES_METHODS};
  my $BILL_ACCOUNTS= $attr->{BILL_ACCOUNTS};

  if($FEES_METHODS) {
    $FEES_METHODS = get_fees_types();
  }

  my $Fees = Finance->fees($db, $admin, \%conf);

  my @service_status = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
    "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT});
  my @service_status_colors = ($_COLORS[9], $_COLORS[6], '#808080', '#0000FF', '#FF8000', '#009999');

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my Abills::HTML $table;
  my $fees_list;
  ($table, $fees_list) = result_former({
    INPUT_DATA      => $Fees,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'ID,LOGIN,DATETIME,DSC,SUM,LAST_DEPOSIT,METHOD,ADMIN_NAME',
    FUNCTION_FIELDS => 'del',
    EXT_TITLES      => {
      'id'           => $lang{NUM},
      'datetime'     => $lang{DATE},
      'dsc'          => $lang{DESCRIBE},
      'sum'          => $lang{SUM},
      'last_deposit' => $lang{OPERATION_DEPOSIT},
      'deposit'      => $lang{CURRENT_DEPOSIT},
      'method'       => $lang{TYPE},
      'ip'           => 'IP',
      'reg_date'     => "$lang{FEES} $lang{REGISTRATION}",
      'admin_name'   => $lang{ADMIN},
      'tax'          => $lang{TAX},
      'tax_sum'      => "$lang{TAX} $lang{SUM}"
    },
    TABLE => {
      width   => '100%',
      caption => $lang{FEES},
      qs      => $pages_qs,
      pages   => $Fees->{TOTAL},
      ID      => 'FEES',
      EXPORT  => 1,
      MENU    => "$lang{SEARCH}:search_form=1&index=3:search",
    }
  });

  $table->{SKIP_FORMER}=1;

  $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $line (@$fees_list) {
    my $delete = ($permissions{2}{2}) ? $html->button( $lang{DEL},
      "index=3&del=$line->{id}$pages_qs" . (($pages_qs !~ /UID=/) ? "&UID=$line->{uid}" : ''),
      { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';

    my @fields_array = ();
    for (my $i = 0; $i < 1+$Fees->{SEARCH_FIELDS_COUNT}; $i++) {
      my $field_name = $Fees->{COL_NAMES_ARR}->[$i];

      if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif($field_name eq 'deleted') {
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      elsif($field_name eq 'login' && $line->{uid}) {
        $line->{login} = $html->button($line->{login}, "index=15&UID=$line->{uid}");
      }
      elsif($field_name eq 'dsc') {
        $line->{$field_name} = Abills::Base::convert($line->{$field_name}, { text2html => 1 });
        $line->{inner_describe} = Abills::Base::convert($line->{inner_describe}, { text2html => 1 }) if ($line->{inner_describe});

        $line->{dsc} //= '';
        if ($line->{dsc} =~ /# (\d+)/ && in_array('Msgs', \@MODULES)) {
          $line->{dsc} = $html->button($line->{dsc}, "index=". get_function_index('msgs_admin')."&chg=$1");
        }

        if ($line->{dsc} =~ /\$/) {
          $line->{dsc} = _translate($line->{dsc});
        }
        # old. remove if everything ok.
        # $line->{dsc} = $line->{dsc}.$html->br().$html->b($line->{inner_describe}) if ($line->{inner_describe});
        $line->{dsc} = ($line->{dsc} || q{}) . $html->b(" ($line->{inner_describe})") if ($line->{inner_describe});
      }
      elsif($field_name =~ /deposit/ && defined($line->{$field_name})) {
        $line->{$field_name} = ($line->{$field_name} < 0) ? $html->color_mark($line->{$field_name}, $_COLORS[6]) : $line->{$field_name};
      }
      elsif($field_name eq 'method') {
        $line->{method} //= 0;
        $line->{method} = ($FORM{METHOD_NUM}) ? $line->{method} : ($FEES_METHODS->{ $line->{method} } || $line->{method} );
      }
      elsif($field_name eq 'login_status' && defined($line->{$field_name})) {
        $line->{login_status} = ($line->{login_status} > 0) ? $html->color_mark($service_status[ $line->{login_status} ], $service_status_colors[ $line->{login_status} ]) : $service_status[$line->{login_status}];
      }
      elsif($field_name eq 'bill_id') {
        $line->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? ($BILL_ACCOUNTS->{ $line->{bill_id} } || q{--}) : $line->{bill_id};
      }
      #      elsif($field_name eq 'invoice_num') {
      #        if (in_array('Docs', \@MODULES) && ! $FORM{xml}) {
      #          my $payment_sum = $line->{sum};
      #          my $i2p         = '';
      #
      #          if ($i2p_hash{$line->{id}}) {
      #            foreach my $val ( @{ $i2p_hash{$line->{id}} }  ) {
      #              my ($invoice_id, $invoiced_sum, $invoice_num)=split(/:/, $val);
      #              $i2p .= $invoiced_sum ." $lang{PAID} $lang{INVOICE} #". $html->button($invoice_num, "index=". get_function_index('docs_invoices_list'). "&ID=$invoice_id&search=1"  ) . $html->br();
      #              $payment_sum -= $invoiced_sum;
      #            }
      #          }
      #
      #          if ($payment_sum > 0) {
      #            $i2p .= sprintf("%.2f", $payment_sum). ' '. $html->color_mark("$lang{UNAPPLIED}", $_COLORS[6]) .' ('. $html->button($lang{APPLY}, "index=". get_function_index('docs_invoices_list') ."&UNINVOICED=1&PAYMENT_ID=$fees->{id}&UID=$line->{uid}") .')';
      #          }
      #
      #          $line->{invoice_num} .= $i2p;
      #        }
      #      }

      push @fields_array, $line->{$field_name};
    }

    $table->addrow(@fields_array, $delete);
  }

  print $table->show();

  if (!$admin->{MAX_ROWS}) {
    $table = $html->table(
      {
        width      => '100%',
        rows       =>
          [ [ "$lang{TOTAL}:", $html->b( $Fees->{TOTAL} ), "$lang{USERS}:", $html->b( $Fees->{TOTAL_USERS} ),
            "$lang{SUM}:", $html->b( $Fees->{SUM} ) ] ],
        rowcolor   => 'even'
      }
    );
    print $table->show();
  }

  return 1;
}


1;