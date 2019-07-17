=head NAME

  Dillers interface

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array mk_unique_value sendmail);
use Cards;
use Tariffs;


our (
  $db,
  %conf,
  $admin,
  %lang,
  $html,
  %permissions,
  @MONTHES,
  @WEEKDAYS
);


my $Diller = Dillers->new($db, $admin, \%conf);
my $Cards  = Cards->new($db, $admin, \%conf);
$Cards->{INTERNET}=1;
my $Tariffs= Tariffs->new($db, \%conf, $admin);

my @status    = ($lang{ENABLE}, $lang{DISABLE}, $lang{USED}, $lang{DELETED}, $lang{RETURNED}, $lang{PROCESSING});
my @status_colors = ($_COLORS[9], $_COLORS[6], '#0000FF', '#808080', '#FF8000', '#008040');


#**********************************************************
=head2 cards_diller()

=cut
#**********************************************************
sub cards_diller {
  $Diller->{ACTION}     = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};

  my $uid = $FORM{UID} || 0;

  if ($FORM{change_permits}) {
    $Diller->diller_permissions_set({%FORM});
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif (!$FORM{SERIA}) {
    if ($FORM{add}) {
      $Diller->diller_add({%FORM});
      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, $lang{ADDED});
      }
      delete($FORM{add});
    }
    elsif ($FORM{change}) {
      $Diller->diller_change({%FORM});
      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, $lang{CHANGED});
      }
      delete($FORM{change});
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      $Diller->diller_del({
        UID       => $uid,
        DILELR_ID => $FORM{DILLER_ID}
      });

      if (!$Diller->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED}");
      }
      return 0;
    }
  }

  _error_show($Diller);

  $Diller->diller_info(\%FORM);
  my $diller_id = 0;

  if ($Diller->{TOTAL} > 0) {
    $Diller->{ACTION}        = 'change';
    $Diller->{LNG_ACTION}    = $lang{CHANGE};
    $diller_id              = $Diller->{ID};
    $pages_qs               = "&UID=$uid&DILLER_ID=$Diller->{ID}";
    $LIST_PARAMS{DILLER_ID} = $Diller->{ID};
    cards_main();
  }

  $Diller->{TARIF_PLAN_SEL} = $html->form_select(
    'TP_ID',
    {
      SELECTED       => $Diller->{TP_ID} || 0,
      SEL_LIST       => $Diller->dillers_tp_list({ COLS_NAME => 1 }),
      NO_ID          => 1,
      MAIN_MENU      => get_function_index('cards_dillers_tp'),
      MAIN_MENU_ARGV => ($Diller->{TP_ID}) ? "chg=$Diller->{TP_ID}" : ''
    }
  );

  if ($permissions{0} && $permissions{0}{14} && $Diller->{ID}) {
    $Diller->{DEL_BUTTON} =  $html->button( $lang{DEL}, "index=$index&del=1&UID=$uid&ID=$diller_id",
      {
        MESSAGE => "$lang{DEL} $lang{SERVICE} Internet $lang{FOR} $lang{USER} $uid?",
        class => 'btn btn-danger pull-right'
      });
  }

  $Diller->{DISABLE} = ($Diller->{DISABLE} && $Diller->{DISABLE} == 1) ? 'checked' : '';

  $html->tpl_show(_include('cards_dillers', 'Cards'), { %$Diller, ID => $diller_id });

  if (in_array('Multidoms', \@MODULES) && $LIST_PARAMS{DILLER_ID}) {
    my %ACTIONS = (
      $lang{ICARDS}      => 1,
      $lang{TARIF_PLANS} => 2,
      $lang{NAS}         => 3,
      $lang{DILLERS}     => 4,
      $lang{TEMPLATES}   => 5,
      $lang{REPORTS}     => 6,
      $lang{FINANCES}    => 7
    );

    my $permits = $Diller->diller_permissions_list({ %FORM, DILLER_ID => $LIST_PARAMS{DILLER_ID} });

    my $table = $html->table(
      {
        width      => '400',
        caption    => $lang{PERMISSION},
        title      => [ $lang{ACTION}, $lang{COMMENTS}, '-' ],
      }
    );

    foreach my $key (sort keys %ACTIONS) {
      $table->addrow(
        $key, '',
        $html->form_input(
          'PERMITS',
          $ACTIONS{$key},
          {
            TYPE  => 'checkbox',
            STATE => ($permits->{ $ACTIONS{$key} }) ? 'checked' : undef
          }
        )
      );
    }

    print $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => {
          index     => $index,
          DILLER_ID => $LIST_PARAMS{DILLER_ID},
          UID       => $uid
        },
        SUBMIT => { change_permits => $lang{CHANGE} },
      }
    );
  }

  return 1;
}

#**********************************************************
=head2 diller_add($attr)

=cut
#**********************************************************
sub diller_add {
  my ($attr) = @_;

  $Diller->{ACTION}     = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};
  $FORM{EXPORT}        = '' if (!$FORM{EXPORT});
  my $EXPIRE_DATE      = q{};

  if(! $FORM{SUM}){
    $FORM{SUM} = $FORM{SUM_NEW};
  }

  if ($FORM{add}) {
    if (!$FORM{TYPE} && defined($FORM{SUM}) && $FORM{SUM} <= 0) {
      if ($FORM{EXPORT} && $FORM{EXPORT} eq 'cards_server') {
        return { ERROR => 'ERR_WRONG_SUM' };
      }
      else {
        print $html->header();
        $html->message('err', $lang{ERROR}, "$lang{SUM}: $FORM{SUM} \n $lang{ERR_WRONG_SUM}", { ID => 673 });
        print $html->{OUTPUT};
      }
      exit;
    }

    my $fees = Finance->fees($db, $admin, \%conf);

    if ($FORM{EXPORT}) {
      if ($FORM{EXPORT} eq 'xml') {
        print "Content-Type: text/xml; filename=\"cards_$DATE.xml\"\n" . "Content-Disposition: attachment; filename=\"cards_$DATE.xml\"; size=" . "\n\n";
        print "<?xml version=\"1.0\" encoding=\"$html->{CHARSET}\"?>\n";
      }
      elsif ($FORM{EXPORT} eq 'text') {
        print "Content-Type: text/plain; filename=\"cards_$DATE.csv\"\n" . "Content-Disposition: attachment; filename=\"cards_$DATE.csv\"; size=" . "\n\n";
      }
    }
    else {
      print $html->header();
    }

    if ($COOKIES{OP_SID} && $FORM{OP_SID} && $FORM{OP_SID} eq $COOKIES{OP_SID}) {
      if ($FORM{EXPORT} eq 'cards_server') {
        return { ERROR => 'EXIST' };
      }

      $html->message('err', $lang{ERROR}, "$lang{EXIST}");
      print "$lang{ICARDS} $lang{EXIST} Error id: 674 ($FORM{OP_SID} // $COOKIES{OP_SID})";
      exit;
    }

    my $list = $Cards->cards_list(
      {
        SERIAL    => $conf{CARDS_DILLER_SERIAL} || '',
        NUMBER    => '_SHOW',
        PAGE_ROWS => 1,
        SORT      => 2,
        DESC      => 'DESC',
        COLS_NAME => 1,
      }
    );
    my $serial = 0;
    my $count = $FORM{COUNT} || 1;

    if ($Diller->{TOTAL} > 0) {
      $serial = $list->[0]->{number};
    }

    $serial++;

    if ($FORM{CARDS_PAYMENT_PIN_LENGTH}) {
      $FORM{CARDS_PAYMENT_PIN_LENGTH} = $conf{CARDS_PAYMENT_PIN_LENGTH} || 8;
    }

    #Get duiller TP info Take fees
    my $sum = 0;
    if ($Diller->{PERCENTAGE} && $Diller->{PERCENTAGE} > 0) {
    }
    else {
      $Diller->dillers_tp_info({ ID => $Diller->{TP_ID} });

      if ($Diller->{TOTAL} > 0) {
        if ($Diller->{PERCENTAGE} > 0) {
          $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $Diller->{PERCENTAGE})));
        }

        if ($Diller->{OPERATION_PAYMENT} > 0) {
          $sum += $Diller->{OPERATION_PAYMENT};
        }
      }
      else {
        $sum = $FORM{SUM};
      }
    }

    my @CARDS_OUTPUT = ();
    my $diller = $Diller;
    #Import from other systems
    if ($FORM{import}) {
    }
    else {
      if ($FORM{TYPE} && !$FORM{TP_ID}) {
        $html->message('err', "$lang{INFO}", "$lang{ERR_SELECT_TARIF_PLAN}");
      }
      elsif ($FORM{TYPE}) {
        load_module('Dv', $html);
        $FORM{add}    = 1;
        $FORM{create} = 1;
        if (!$FORM{BEGIN}) {
          $list = $users->list(
            {
              PAGE_ROWS => 1,
              SORT      => 8,
              DESC      => 'DESC',
              COLS_NAME => 1
            }
          );
          $FORM{BEGIN}       = $list->[0]->{uid};
          $FORM{LOGIN_BEGIN} = $list->[0]->{uid};
        }

        my $return = cards_users_add(
          {
            #EXTRA_TPL => $dv_tpl,
            NO_PRINT  => 1
          }
        );

        my $added_count = 0;

        if (ref($return) eq 'ARRAY') {
          foreach my $line (@$return) {
            $FORM{'1.LOGIN'}       = $line->{LOGIN};
            $FORM{'1.PASSWORD'}    = $line->{PASSWORD};
            $FORM{'1.CREATE_BILL'} = 1;
            $FORM{'4.TP_ID'}       = $FORM{TP_ID};
            $line->{UID} = dv_wizard_user({ SHORT_REPORT => 1 });

            if ($line->{UID} < 1) {
              $html->message('err', "$lang{ERROR}", "$lang{LOGIN}: '$line->{LOGIN}'");
              last if (!$line->{SKIP_ERRORS});
            }
            else {

              #Confim card creation
              $added_count++;
              $line->{NUMBER} = sprintf("%.11d", $line->{NUMBER});
              push @CARDS_OUTPUT,
                {
                  #PIN         => $pin,
                  LOGIN       => $FORM{'1.LOGIN'},
                  PASSWORD    => $FORM{'1.PASSWORD'},
                  PIN         => $FORM{'1.PASSWORD'},
                  NUMBER      => $line->{NUMBER},
                  SERIA       => $line->{SERIA},
                  EXPIRE_DATE => ($EXPIRE_DATE ne '0000-00-00') ? $EXPIRE_DATE : '',
                  DATE        => "$DATE $TIME",
                  SUM         => sprintf("%.2f", $FORM{SUM}),
                  DILLER_ID   => $Diller->{ID},
                  TARIF_PLAN  => $FORM{TP_ID}
                };

              #If prepaid or postpaid service
              if ($Diller->{PAYMENT_TYPE} < 2) {
                if ($Diller->{PERCENTAGE} > 0) {
                  $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $Diller->{PERCENTAGE})));
                }
                if ($sum > 0) {
                  $fees->take(
                    $user, $sum,
                    {
                      DESCRIBE     => "$lang{ICARDS} $line->{SERIA}$line->{NUMBER}",
                      METHOD       => 0,
                      EXT_ID       => "$Diller->{SERIAL}$line->{NUMBER}",
                      CHECK_EXT_ID => "$Diller->{SERIAL}$line->{NUMBER}"
                    }
                  );

                  _error_show($fees);
                }
              }

              if (cards_users_gen_confim({ %$line, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 }) == 0) {
                return 0;
              }
            }
          }
        }
      }
      else {
        for (my $i = $serial ; $i < $serial + $count ; $i++) {
          if ($FORM{TYPE}) {
            #my $password = mk_unique_value($FORM{PASSWD_LENGTH}, { SYMBOLS => $FORM{PASSWD_SYMBOLS} || $conf{PASSWD_SYMBOLS} || undef });
          }

          my $pin = mk_unique_value($FORM{CARDS_PAYMENT_PIN_LENGTH}, { SYMBOLS => $conf{CARDS_PIN_SYMBOLS} || '1234567890' });
          $EXPIRE_DATE = '0000-00-00';
          my $card_number =  sprintf("%.11d", $i);

          $Cards->cards_add(
            {
              SERIAL    => $conf{CARDS_DILLER_SERIAL} || '',
              NUMBER    => $card_number,
              PIN       => $pin,
              SUM       => $FORM{SUM},
              STATUS    => 0,
              EXPIRE    => $EXPIRE_DATE,
              DILLER_ID => $diller->{ID}
            }
          );

          if ($Diller->{errno}) {
            if ($FORM{EXPORT} eq 'cards_server') {
              return { ERROR => 'CARDS_GENERATION_ERROR' };
            }

            _error_show($Diller);
            return 0;
          }
          else {
            if ($Diller->{PAYMENT_TYPE} < 2) {
              if ($diller->{PERCENTAGE} > 0) {
                $sum = $FORM{SUM} - ($FORM{SUM} / 100 * (100 - (100 - $diller->{PERCENTAGE})));
              }
              my $serial_id = $Diller->{SERIAL} || q{};
              $fees->take(
                $user, $sum,
                {
                  DESCRIBE     => "$lang{ICARDS} $serial_id$i",
                  METHOD       => 0,
                  EXT_ID       => "$serial_id$i",
                  CHECK_EXT_ID => "$serial_id$i"
                }
              );
            }

            push @CARDS_OUTPUT,
              {
                LOGIN       => '-',
                PIN         => $pin,
                NUMBER      => $card_number,
                EXPIRE_DATE => ($EXPIRE_DATE ne '0000-00-00') ? $EXPIRE_DATE : '',
                DATE        => "$DATE $TIME",
                SUM         => sprintf("%.2f", $FORM{SUM}),
                DILLER_ID   => $diller->{ID}
              };
          }
        }
      }
    }

    #Show cards
    if ($FORM{EXPORT} eq 'xml') {
      print "<CARDS>";
      foreach my $card_info (@CARDS_OUTPUT) {
        print "<CARD>
          <LOGIN>$card_info->{PIN}</LOGIN>
          <PIN>$card_info->{PIN}</PIN>
          <NUMBER>$card_info->{NUMBER}</NUMBER>
          <EXPIRE_DATE>$card_info->{EXPIRE_DATE}</EXPIRE_DATE>
          <CREATED_DATE>$card_info->{DATE}</CREATED_DATE>
          <SUM>$card_info->{SUM}</SUM>
          <DILLER_ID>$card_info->{DILLER_ID}</DILLER_ID></CARD>\n";
      }
      print "</CARDS>";
    }
    elsif ($FORM{EXPORT} eq 'text') {
      foreach my $card_info (@CARDS_OUTPUT) {
        print "$card_info->{LOGIN}\t$card_info->{PIN}\t$card_info->{NUMBER}\t$card_info->{EXPIRE_DATE}\t$card_info->{DATE}\t$card_info->{SUM}\t$card_info->{DILLER_ID}\n";
      }
    }
    elsif ($FORM{EXPORT} eq 'order_print') {
      my $content = "Print Cards\n";
      foreach my $card_info (@CARDS_OUTPUT) {
        $content .= "$card_info->{PIN}\t$card_info->{NUMBER}\t$card_info->{EXPIRE_DATE}\t$card_info->{DATE}\t$card_info->{SUM}\t$card_info->{DILLER_ID}\n";
      }
      sendmail("$user->{FROM}", "$conf{ADMIN_MAIL}", "Cards Print", "$content", "$conf{MAIL_CHARSET}");
      $html->message('info', "$lang{INFO}", "$lang{SENDED} $lang{ORDER_PRINT}");
    }
    elsif ($FORM{EXPORT} eq 'cards_server') {
      foreach my $card_info (@CARDS_OUTPUT) {
        return {
          LOGIN       => $card_info->{LOGIN},
          PIN         => $card_info->{PIN},
          NUMBER      => $card_info->{NUMBER},
          EXPIRE_DATE => $card_info->{EXPIRE_DATE},
          DATE        => $card_info->{DATE},
          SUM         => $card_info->{SUM},
          DILLER_ID   => $card_info->{DILLER_ID}
        };
      }
    }
    else {
      foreach my $card_info (@CARDS_OUTPUT) {
        $html->tpl_show(_include('cards_check', 'Cards'), $card_info);
      }
    }

    return 1;
  }

  $Diller->{OP_SID} = mk_unique_value(16);

  if ($attr->{RESELLER}) {
    $Diller->{TYPE_SEL} = $html->form_select(
      'TYPE',
      {
        SELECTED     => $FORM{TYPE},
        SEL_ARRAY    => [ $lang{PAYMENTS}, "$lang{SERVICES} ($lang{LOGIN} + $lang{PASSWD})" ],
        ARRAY_NUM_ID => 1,
        EX_PARAMS    => 'onchange=\'samechanged(this)\''
      }
    );

    $Diller->{TP_SEL} = $html->form_select(
      'TP_ID',
      {
        SELECTED   => $FORM{TP_ID},
        SEL_LIST   => $Tariffs->list(
          {
            PAGE_ROWS => 1,
            SORT      => 1,
            DESC      => 'desc',
            DOMAIN_ID => $user->{DOMAIN_ID},
            COLS_NAME => 1
          }),
        EX_PARAMS         => '',    #'STYLE=\'background-color: #dddddd\' name=\'TP_ID\'',
        NO_ID             => 1
      }
    );

    $html->tpl_show(
      _include('cards_reseller_cod_gen', 'Cards'),
      {
        COUNT => 1,
        SUM   => 0.00,
        %$Diller
      },
      { ID => 'CARD_GEN' }
    );
  }
  else {
    $html->tpl_show(_include('cards_dillers_cod_gen', 'Cards'), { COUNT => 1, SUM => 0.00, %$Diller }, { ID => 'CARD_GEN' });
  }

  return 0;
}

#**********************************************************
=head2 dillers_list()

=cut
#**********************************************************
sub dillers_list {

  my $list  = $Diller->dillers_list({%LIST_PARAMS});
  my $table = $html->table(
    {
      width   => '100%',
      caption => "$lang{DILLERS}",
      title   => [ 'ID', "$lang{LOGIN}", "$lang{NAME}", "$lang{ADDRESS}", "E-Mail", "$lang{REGISTRATION}", "$lang{PERCENTAGE}", "$lang{STATE}", "$lang{COUNT}", "$lang{ENABLE}" ],
      qs         => $pages_qs,
      pages      => $Diller->{TOTAL},
      ID         => 'CARDS_DILLERS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->[0],
      $html->button($line->[1], "index=15&UID=$line->[10]&MODULE=Cards"),
      $line->[2],
      $line->[3],
      $line->[4],
      $line->[5],
      $line->[6],
      $status[ $line->[7] ],
      $line->[8],
      $line->[9]
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_dillers_tp($attr)

=cut
#**********************************************************
sub cards_dillers_tp {

  $Diller->{LNG_ACTION} = $lang{ADD};
  $Diller->{ACTION}     = 'add';

  my @payment_types = ($lang{PREPAID}, $lang{POSTPAID}, $lang{ACTIVATION_PAYMENTS});

  if ($FORM{add}) {
    $Diller->dillers_tp_add({%FORM});
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Diller->dillers_tp_change({%FORM});
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{chg}) {
    $Diller->dillers_tp_info({ ID => $FORM{chg} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGING});
    }

    $FORM{add_form}      = 1;
    $Diller->{ACTION}     = 'change';
    $Diller->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Diller->dillers_tp_del({ ID => $FORM{del} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Diller);

  $Diller->{PAYMENT_TYPE_SEL} = $html->form_select(
    'PAYMENT_TYPE',
    {
      SELECTED     => $Diller->{PAYMENT_TYPE},
      SEL_ARRAY    => \@payment_types,
      ARRAY_NUM_ID => 1
    }
  );

  $Diller->{NAS_TP} = ($Diller->{NAS_TP}) ? 'checked' : '';
  if($FORM{add_form}) {
    $html->tpl_show(_include('cards_dillers_tp', 'Cards'), $Diller);
  }

  my $list  = $Diller->dillers_tp_list({%LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{TARIF_PLANS},
      border     => 1,
      title      => [ $lang{NAME}, $lang{PERCENTAGE}, $lang{OPERATION_PAYMENT}, $lang{PAYMENT_TYPE}, '-' ],
      ID         => 'DILLERS_TARIF_PLANS',
      MENU       => "$lang{ADD}:index=$index&add_form=1:add;"
    }
  );

  my ($delete, $change);
  foreach my $line (@$list) {
    if ($permissions{4}{1}) {
      $delete = $html->button($lang{DEL}, "index=$index&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{name}?", class => 'del' });
      $change = $html->button($lang{CHANGE}, "index=$index&chg=$line->{id}", { class => 'change' });
    }

    if ($FORM{chg} && $FORM{chg} eq $line->{id}) {
      $table->{rowcolor} = 'bg-success';
    }
    else {
      delete($table->{rowcolor});
    }

    $table->addrow($html->button($line->{name}, "index=$index&TP_ID=$line->{id}"),
      $line->{percentage},
      $line->{operation_payment},
      $payment_types[ $line->{payment_type} ],
      $change . $delete);
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b($Tariffs->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_diller_stats()

=cut
#**********************************************************
sub cards_diller_stats {

  %LIST_PARAMS = ();
  my $diller = $Diller;
  $LIST_PARAMS{DILLER_ID} = $diller->{ID};
  $LIST_PARAMS{SERIAL}    = '';

  $FORM{PAGE_ROWS} = $FORM{rows} if ($FORM{rows});

  if ($FORM{print}) {
    $LIST_PARAMS{CREATED_DATE} = $FORM{print};
    print "Content-Type: text/html\n\n";

    my $list = $Cards->cards_list({
      COUNT     =>  '_SHOW',
      SUM       =>  '_SHOW',
      %LIST_PARAMS,
      PAGE_ROWS => 1000000,
      COLS_NAME => 1,
    });

    my $total_count = 0;
    my $total_sum   = 0;

    foreach my $line (@$list) {
      $total_count += $line->{cards_count};
      $total_sum   += $line->{sum};
    }

    $html->tpl_show(
      _include('cards_diller_sum_check', 'Cards'),
      {
        DATE        => "$DATE $TIME",
        TOTAL_COUNT => $total_count,
        TOTAL_SUM   => sprintf("%.2f", $total_sum),
        DILLER_ID   => $diller->{ID},
        DETAILS     => undef
      }
    );
    return 0;
  }
  elsif ($FORM{print_cards}) {
    cards_print();
    exit;
  }

  my $table = $html->table(
    {
      width    => '100%',
      rows     => [
        [
          "$lang{FROM}: ",
          $html->date_fld2('CREATED_FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'cards_list', WEEK_DAYS => \@WEEKDAYS }),
          "$lang{TO}: ",
          $html->date_fld2('CREATED_TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'cards_list', WEEK_DAYS => \@WEEKDAYS }),
          $html->form_select(
            'TYPE',
            {
              SELECTED => $FORM{TYPE},
              SEL_HASH => {
                CARDS => $lang{ICARDS},
                DAYS  => $lang{DAYS}
              },
              SORT_KEY => 1,
              NO_ID    => 1
            }
          ),
          "$lang{STATUS}: "
            . $html->form_select(
            'STATUS',
            {
              SELECTED => $FORM{STATUS},
              SEL_HASH => {
                '' => "$lang{ALL}",
                1  => "$lang{ENABLE}",
                3  => "$lang{USED}"
              },
              SORT_KEY => 1,
              NO_ID    => 1
            }
          ),
          "$lang{ROWS}: " . $html->form_input('rows', ($FORM{rows} || int($conf{list_max_recs})), { SIZE => 4, OUTPUT2RETURN => 1 }),
          $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 })

        ]
      ],
    }
  );

  print $html->form_main(
    {
      CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
      HIDDEN  => {
        index => "$index",
        SERIA => '',
        sid   => $sid,
        UID   => $FORM{UID},
      },
      NAME => 'cards_list'
    }
  );

  $LIST_PARAMS{LOGIN} = undef;

  my @pin = ();
  @pin = ("PIN") if ($conf{CARDS_SHOW_PINS});
  if ($FORM{ID}) {
    $FORM{ID}=~s/, /;/g;
    $LIST_PARAMS{ID} = $FORM{ID};
  }
  elsif ($FORM{CREATED_FROM_DATE} && $FORM{CREATED_TO_DATE}) {
    $pages_qs                       = "&CREATED_TO_DATE=$FORM{CREATED_TO_DATE}&CREATED_FROM_DATE=$FORM{CREATED_FROM_DATE}";
    $LIST_PARAMS{CREATED_FROM_DATE} = $FORM{CREATED_FROM_DATE};
    $LIST_PARAMS{CREATED_TO_DATE}   = $FORM{CREATED_TO_DATE};
    $LIST_PARAMS{PAGE_ROWS}         = $FORM{rows};
  }
  else {
    my ($Y, $M) = split(/-/, $DATE);
    $LIST_PARAMS{CREATED_MONTH} = "$Y-$M";
    $pages_qs = "&CREATED_MONTH=$Y-$M";
  }

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  if (defined($FORM{STATUS}) && $FORM{STATUS} ne '') {
    $LIST_PARAMS{STATUS} = $FORM{STATUS};
    $pages_qs .= "&STATUS=$FORM{STATUS}";
  }

  #Group by TP
  if ($FORM{TYPE} && $FORM{TYPE} eq 'TP') {
    $pages_qs .= "&TYPE=TP&PAGE_ROWS=$PAGE_ROWS";

    if ($FORM{CREATED_DATE}) {
      $LIST_PARAMS{CREATED_DATE} = "$FORM{CREATED_DATE}";
      $pages_qs .= "&CREATED_DATE=$LIST_PARAMS{CREATED_DATE}";
    }

    if ($FORM{TP_ID}) {
      $LIST_PARAMS{TP_ID} = $FORM{TP_ID};
      $pages_qs .= "&TP_ID=$FORM{TP_ID}";
    }

    $LIST_PARAMS{TYPE} = 'TP';

    if ($FORM{print_cards}) {
      cards_print();
      exit;
    }

    $table = $html->table(
      {
        width => '200',
        qs    => $pages_qs,
        ID    => 'PRINT_CARDS_LIST',
        rows  => [ [
          $html->button("$lang{PRINT} PDF", "qindex=$index&pdf=1&print_cards=1&$pages_qs", { ex_params => 'target=_new', BUTTON => 1 }),
          $html->button('CSV', "qindex=$index&csv=1&print_cards=1&$pages_qs", { ex_params => 'target=_new', BUTTON => 1 })
        ] ]
      }
    );
    print $table->show();

    my @caption = ("$lang{DATE}", "$lang{TARIF_PLAN}", "$lang{COUNT}", "$lang{SUM}", "-");
    %LIST_PARAMS = ( DATE => '_SHOW',
      TP_ID=> '_SHOW',
      COUNT=> '_SHOW',
      SUM  => '_SHOW',
      %LIST_PARAMS
    );

    if ($FORM{TP_ID}) {
      @caption = ("$lang{NUM}", "$lang{LOGIN}", "$lang{PASSWD}", "$lang{TARIF_PLAN}", "$lang{USED} $lang{DATE}");
      %LIST_PARAMS = ( NUMBER => '_SHOW',
        LOGIN  => '_SHOW',
        PIN    => '_SHOW',
        TP_ID  => '_SHOW',
        USED   => '_SHOW',
        %LIST_PARAMS
      );
    }

    my $list = $Cards->cards_list({
      %LIST_PARAMS,
      COLS_NAME => 1,
    });

    $table = $html->table(
      {
        width      => '100%',
        caption    => $lang{LOG},
        title      => \@caption,
        qs         => $pages_qs,
        pages      => $Diller->{TOTAL},
        ID         => 'CARDS_LIST',
      }
    );

    my @rows = ();
    foreach my $line (@$list) {
      my $tp_id = $line->{tp_id} || 0;
      if ($FORM{TP_ID}) {
        @rows = ($line->{number},
          $line->{login},
          $line->{pin},
          $line->{tp_name},
          $line->{used}
        );
      }
      else {
        @rows = (
          $html->button($line->{date}, "&index=$index&CREATED_DATE=".
            ($LIST_PARAMS{CREATED_DATE} || q{})
            . "&PAGE_ROWS=" . ($LIST_PARAMS{PAGE_ROWS} || 25)
            . (($tp_id > 0) ? "&TYPE=TP&TP_ID=$tp_id" : '&TYPE=CARDS&PAYMENTS=1')),
            (!$line->{count}) ? $lang{PAYMENTS} : $html->button($line->{tp_name}, "&index=$index$pages_qs&TP_ID=$tp_id"),
          $line->{count},
          $line->{sum}
        );
      }

      $table->addrow(@rows);
    }

    print $table->show();

    $table = $html->table(
      {
        width      => '100%',
        rows       => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}), "$lang{SUM}:", $html->b($Diller->{TOTAL_SUM}) ] ]
      }
    );
    print $table->show();
  }
  elsif ($FORM{TYPE} && $FORM{TYPE} eq 'CARDS') {
    if (!$FORM{sort}) {
      $LIST_PARAMS{SORT} = 1;
      $LIST_PARAMS{DESC} = 'DESC';
    }

    $pages_qs .= "&TYPE=CARDS&PAGE_ROWS=$FORM{PAGE_ROWS}";

    if ($FORM{CREATED_DATE}) {
      $LIST_PARAMS{CREATED_DATE} = "$FORM{CREATED_DATE}";
      $pages_qs .= "&CREATED_DATE=$LIST_PARAMS{CREATED_DATE}";
    }

    if ($FORM{PAYMENTS}) {
      $LIST_PARAMS{PAYMENTS} = 1;
      $pages_qs .= "&PAYMENTS=1";
    }

    if ($FORM{print_cards}) {
      cards_print();
      exit;
    }

    my $list = $Cards->cards_list({ %LIST_PARAMS,
      SERIAL     => '',
      NUMBER     => '_SHOW',
      LOGIN      => '_SHOW',
      SUM        => '_SHOW',
      STATUS     => '_SHOW',
      EXPIRE     => '_SHOW',
      CREATED    => '_SHOW',
      UID        => '_SHOW',
      COLS_NAME  => 1
    });

    $table = $html->table(
      {
        width   => '100%',
        caption => $lang{LOG},
        title   => [ $lang{SERIAL}, $lang{NUM}, $lang{LOGIN}, $lang{SUM}, $lang{STATUS}, $lang{EXPIRE}, $lang{ADDED} ],
        qs      => $pages_qs,
        pages   => $Diller->{TOTAL},
        ID      => 'CARDS_LIST',
      }
    );

    foreach my $line (@$list) {
      @pin = ($line->{pin}) if ($conf{CARDS_SHOW_PINS});
      $table->addrow(
        $html->form_input("ID", "$line->{id}", { TYPE => 'checkbox', OUTPUT2RETURN => 1 }).$line->{serial},
        $line->{number},
          ($user->{UID}) ? "$lang{PAYMENTS}" : $html->button($line->{login}, "&index=11&UID=$line->{uid}"),
        $line->{sum},
        $html->color_mark($status[ $line->{status} ],
          $status_colors[ $line->{status} ]),
        $line->{expire},
        $line->{created}
      );
    }

    my %hidden_params = ();
    my @p = split(/&/, $pages_qs);
    foreach my $l (@p) {
      my ($k, $v) = split(/=/, $l, 2);
      $hidden_params{$k}=$v if($k);
    }

    print $html->form_main(
      {
        CONTENT =>
        $html->form_input('pdf', 'pdf', { TYPE => 'submit', OUTPUT2RETURN => 1 }). ' '.
          $html->form_input('csv', 'csv', { TYPE => 'submit', OUTPUT2RETURN => 1 }). ' '.
          $table->show({ OUTPUT2RETURN => 1  }),
        #ENCTYPE => 'multipart/form-data',
        HIDDEN => { qindex     => $index,
          print_cards=> 1,
          %hidden_params
        },
      }
    );

    $table = $html->table(
      {
        width      => '100%',
        rows       => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}), "$lang{SUM}:", $html->b($Diller->{TOTAL_SUM}) ] ]
      }
    );
    print $table->show();
  }
  else {
    $table = $html->table(
      {
        width       => '100%',
        caption     => $lang{LOG},
        title       => [ $lang{DATE}, $lang{COUNT}, $lang{SUM}, '-' ],
        qs          => $pages_qs,
        pages       => $Diller->{TOTAL},
        ID          => 'CARDS_REPORTS_DAYS'
      }
    );

    my $list = $Cards->cards_report_days({
      %LIST_PARAMS,
      SERIA       => '',
      COLS_NAME   => 1
    });

    foreach my $line (@$list) {
      $table->addrow(
        $html->button($line->{date}, "index=$index&TYPE=TP$pages_qs&sid=$FORM{sid}" . (($line->{date} =~ /(\d{4}-\d{2}-\d{2})/) ? "&CREATED_DATE=$1" : '')),
        $line->{count},
        $line->{sum},
        $html->button(
          "$lang{PRINT} $lang{SUM}",
          '#',
          {
            NEW_WINDOW      => "$SELF_URL?qindex=$index&print=$line->{date}&sid=$FORM{sid}",
            NEW_WINDOW_SIZE => "480:640",
            class           => 'print'
          }
        ),
      );
    }

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 cards_dillers() - Cards diller interface

=cut
#**********************************************************
sub cards_dillers {

  $Diller->{ACTION}     = 'add';
  $Diller->{LNG_ACTION} = $lang{ADD};

  if ($FORM{info}) {
    $pages_qs = "&info=$FORM{info}";
    $LIST_PARAMS{DILLER_ID} = $FORM{info};

    $Diller = $Diller->diller_info({ ID => $FORM{info} });
    $html->tpl_show(_include('cards_diller_info', 'Cards'), $Diller);
    cards_main();
    return 0;
  }
  elsif ($FORM{add}) {
    $Diller->diller_add({%FORM});
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{ADDED});
    }
  }
  elsif ($FORM{change}) {
    $Diller->diller_change({%FORM});
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
    }
  }
  elsif ($FORM{chg}) {
    $Diller->diller_info({ ID => $FORM{chg} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, $lang{CHANGING});
    }
    $Diller->{ACTION}     = 'change';
    $Diller->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Diller->diller_del({ ID => $FORM{del} });
    if (!$Diller->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }

  _error_show($Diller);

  $Diller->{TARIF_PLAN_SEL} = $html->form_select(
    'TP_ID',
    {
      SELECTED => $Diller->{TP_ID},
      SEL_LIST => $Diller->dillers_tp_list({ COLS_NAME => 1 }),
    }
  );

  $Diller->{DISABLE} = ($Diller->{DISABLE} == 1) ? 'checked' : '';
  $html->tpl_show(_include('cards_dillers', 'Cards'), $Diller);

  my $list = $Diller->dillers_list({%LIST_PARAMS});
  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{DILLERS},
      title      => [ 'ID', $lang{NAME}, $lang{ADDRESS}, "E-Mail", $lang{REGISTRATION}, $lang{PERCENTAGE}, $lang{STATE},
        $lang{COUNT}, $lang{ENABLE}, '-' ],
      qs         => $pages_qs,
      pages      => $Diller->{TOTAL},
      ID         => 'DILLER_LIST'
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $line->[0],
      $line->[1],
      $line->[2],
      $line->[3],
      $line->[4],
      $line->[5],
      $status[ $line->[6] ],
      $line->[7],
      $line->[8],
      $html->button($lang{INFO},   "index=$index$pages_qs&info=$line->[0]", { class => 'show' })
        .$html->button($lang{CHANGE}, "index=$index$pages_qs&chg=$line->[0]",  { class => 'change' })
        .$html->button($lang{DEL}, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$lang{DEL} [$line->[0]] ?", class => 'del' })
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      rows       => [ [ "$lang{TOTAL}:", $html->b($Diller->{TOTAL}) ] ]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 cards_reseller_face()

=cut
#**********************************************************
sub cards_reseller_face {
  #my ($attr) = @_;
  $Diller->diller_info({ UID => $user->{UID} });

  if ($Diller->{TOTAL} < 1) {
    $html->set_cookies('sid', "", "Fri, 1-Jan-2038 00:00:01");
    $html->header() if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ACCOUNT} $lang{NOT_EXIST}");
    return 0;
  }

  if ($user->{DEPOSIT} + $user->{CREDIT} > 0) {

    #Generate Cards
    if (diller_add({ RESELLER => 1 }) > 0) {
      return 0;
    }
  }
  else {
    print "Content-Type: text/html\n\n" if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ERR_SMALL_DEPOSIT}");
  }

  $Diller->{DISABLE} = $status[ $Diller->{DISABLE} ];
  $html->tpl_show(_include('cards_diller_info', 'Cards'), { %$Diller, %$user }, { ID => 'DILLER_INFO' });

  return 0;
}

#**********************************************************
=head2 cards_diller_face()

=cut
#**********************************************************
sub cards_diller_face {
  my ($attr) = @_;

  $users = $attr->{USER_INFO};
  $Diller->diller_info({ UID => $users->{UID} });

  if (! $Diller->{ID}) {
    $html->set_cookies('sid', "", "Fri, 1-Jan-2038 00:00:01");
    $html->header() if ($FORM{qindex});
    $html->message('info', $lang{DILLERS}, "$lang{ACCOUNT} $lang{NOT_EXIST}", { ID => 671 });
    return 0;
  }

  if (($users->{DEPOSIT} + $users->{CREDIT} > 0 && $Diller->{PAYMENT_TYPE} == 0) || $Diller->{PAYMENT_TYPE} > 0) {
    if (diller_add() > 0) {
      return 0;
    }
  }
  else {
    print "Content-Type: text/html\n\n" if ($FORM{qindex});
    $html->message('info', $lang{INFO}, "$lang{ERR_SMALL_DEPOSIT}", { ID => 672  });
  }

  $Diller->{DISABLE} = $status[ $Diller->{DISABLE} ];
  $html->tpl_show(_include('cards_diller_info', 'Cards'), { %$Diller, %$user }, { ID => 'DILLER_INFO' });

  return 1;
}


1;