=head1 NAME

  Invoices managment

=cut
use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2ml mk_unique_value in_array days_in_month);
use Customers;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  @units,
  @MONTHES,
  @WEEKDAYS,
  @MONTHES_LIT,
  %permissions,
  $users,

  @one,
  @ones,
  @onest,
  @twos,
  @fifth,
  @ten,
  @tens,
  @hundred,
  @money_unit_names,
);

my $Docs     = Docs->new( $db, $admin, \%conf );
my $Payments = Payments->new( $db, $admin, \%conf );
my @service_status_colors = ($_COLORS[9], $_COLORS[6]);
my @service_status = ($lang{ENABLE}, $lang{DISABLE});

my $debug    = $FORM{debug} || 0;

#**********************************************************
=head2 docs_invoice_company($attr)

=cut
#**********************************************************
sub docs_invoice_company{

  $FORM{ALL_SERVICES} = 1;

  docs_invoice();

  return 1;
}

#**********************************************************
=head2 docs_invoices_add_payments($attr) - Invoices list

=cut
#**********************************************************
sub docs_invoices_add_payments{
  my ($attr) = @_;

  my $total_sum = 0;
  my $total_count = 0;
  my $skip_count = 0;

  if ( !$attr->{IDS} ){
    $html->message( 'err', $lang{ERROR}, $lang{NO_DATA}, { ID => 530 } );
    return 0;
  }

  my $ids = $attr->{IDS};
  $ids =~ s/, /;/g;
  my $list = $Docs->invoices_list( {
    ID        => $ids,
    UID       => '_SHOW',
    BILL_ID   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1000000
  } );

  foreach my $line ( @{$list} ){
    if ( $line->{payment_sum} ){
      $skip_count++;
      next;
    }

    $Payments->add( { UID => $line->{uid},
        BILL_ID           => $line->{bill_id}
      },
      {
        METHOD => $FORM{METHOD},
        SUM    => $line->{total_sum}
      } );

    $Docs->invoices2payments( {
      PAYMENT_ID => $Payments->{INSERT_ID},
      INVOICE_ID => $line->{id},
      SUM        => $line->{total_sum}
    } );

    $total_sum += $line->{total_sum};
    $total_count++;
  }

  $html->message( 'info', $lang{INFO}, "$lang{ADD} $lang{PAYMENTS}\n$lang{SUM}: " . sprintf( "%.2f",
      $total_sum ) . "\n$lang{COUNT}: $total_count\n$lang{SKIP_PAY_ADD}: $skip_count" );

  return 1;
}

#**********************************************************
=head2 docs_invoices_list($attr) - Invoices list

=cut
#**********************************************************
sub docs_invoices_list{
  my ($attr) = @_;

  if($attr->{USER_INFO}) {
    $FORM{UID}        = $attr->{USER_INFO}->{UID} ;
    $LIST_PARAMS{UID} = $attr->{USER_INFO}->{UID} ;
  }

  #my @payments_status = ("$lang{UNPAID}", "$lang{PAID}", "$lang{PARTLY_PAID}");
  if ( $FORM{UNINVOICED} ){
    if ( $FORM{apply} ){
      my $payment_list = $Payments->list( {
        ID        => $FORM{PAYMENT_ID},
        SUM       => '_SHOW',
        COLS_NAME => 1
      } );

      if ( $Payments->{TOTAL} > 0 ){
        if ( $FORM{SUM} && $FORM{SUM} =~ /[\.\,0-9]+/ && $FORM{SUM} > $payment_list->[0]->{sum} ){
          $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_SUM} );
          return 0;
        }

        docs_payments_maked( \%FORM );
        if ( !_error_show( $Docs, { ID => 570 } ) ){
          $html->message( 'info', $lang{ADDED},
            "$lang{PAYMENTS}: $payment_list->[0]->{id} -> $lang{INVOICE}: $FORM{INVOICE_ID}\n$lang{SUM}: $FORM{SUM}" );
        }
      }
    }
    else{
      my $payments_list = $Docs->invoices_list( {
        %LIST_PARAMS,
        %FORM,
        UNINVOICED => 1,
        COLS_NAME  => 1,
      });

      my $table = $html->table(
        {
          width      => '100%',
          title      => [ '#', $lang{DATE}, $lang{DESCRIBE}, "$lang{PAYMENTS} $lang{SUM}", "$lang{INVOICES} $lang{SUM}", $lang{REST} ],
          qs         => $pages_qs,
          pages      => $Docs->{TOTAL},
          ID         => 'UNINVOICED_PAYMENTS'
        }
      );

      $pages_qs .= "&subf=2" if (!$FORM{subf});
      foreach my $payment ( @{$payments_list} ){
        $table->{rowcolor} = ($FORM{PAYMENT_ID} && $FORM{PAYMENT_ID} == $payment->{id}) ? $_COLORS[0] : undef;
        $table->addrow(
          $html->form_input( 'PAYMENT_ID', $payment->{id}, { TYPE => 'radio',
              STATE                                               =>
                ($FORM{PAYMENT_ID} && $FORM{PAYMENT_ID} == $payment->{id}) ? 'checked' : undef
            } ) .
            $html->b( $payment->{id} ),
          $payment->{date},
          ($payment->{dsc} || q{}) . (($payment->{inner_describe}) ? $html->br() . $html->b( $payment->{inner_describe} ) : ''),
          $payment->{payment_sum},
          $payment->{invoiced_sum} || '0.00',
          $payment->{remains}
        );
      }

      $Docs->{PAYMENTS_LIST} = $table->show( { OUTPUT2RETURN => 1 } );

      $Docs->{INVOICE_SEL} = $html->form_select(
        "INVOICE_ID",
        {
          SELECTED         => $FORM{INVOICE_ID} || $FORM{UNINVOICED},
          SEL_LIST         => $Docs->invoices_list( {
            UID       => $FORM{UID},
            UNPAIMENT => 1,
            PAGE_ROWS => 200,
            SORT      => 2,
            DESC      => 'DESC',
            COLS_NAME => 1 } ),
          SEL_KEY          => 'id',
          SEL_VALUE        => 'invoice_num,date,total_sum,payment_sum',
          SEL_VALUE_PREFIX => "$lang{NUM}: ,$lang{DATE}: ,$lang{SUM}: ,$lang{PAYMENTS}: ",
          SEL_OPTIONS      => { 0 => '', %{  (!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? {create => $lang{CREATE}} : {}} },
          NO_ID            => 1,
          MAIN_MENU        => get_function_index( 'docs_invoices_list' ),
          MAIN_MENU_ARGV   => (($FORM{UID}) ? "UID=$FORM{UID}" :  q{} ) . "&INVOICE_ID=". ($FORM{INVOICE_ID} || q{})
        }
      );

      $html->tpl_show( _include( 'docs_payment2invoice', 'Docs' ), { %{$Docs}, %FORM }, { ID => 'docs_payment2invoice'  } );

      return 0;
    }
  }
  elsif ( $FORM{SHOW_PAYMENTS} ){
    my @payments_ids_arr = ();
    my $i2p_list = $Docs->invoices2payments_list( { INVOICE_ID => $FORM{SHOW_PAYMENTS}, COLS_NAME => 1 } );
    foreach my $i2p ( @{ $i2p_list } ){
      push @payments_ids_arr, $i2p->{payment_id};
    }
    $FORM{ID} = join( ';', @payments_ids_arr );
    delete $FORM{UID};
    form_payments();
    return 0;
  }
  elsif ( $attr->{COMPANY} ){
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $index = $FORM{index};
  }
  elsif ( !$user->{UID} && $FORM{add_payment} ){
    docs_invoices_add_payments( \%FORM );
  }
  elsif ( $FORM{COMPANY_ID} && !$attr->{COMPANY} && !$FORM{qindex} && !$attr->{USER_INFO} ){
    $FORM{subf} = $FORM{index};
    $index = get_function_index('form_companies');
    form_companies();
    return 0;
  }
  elsif ( $FORM{print} ){
    docs_invoice_print( $FORM{print}, { UID => $FORM{UID} } );
    return 0;
  }

  my $PAYMENTS_METHODS = get_payment_methods();
  if ( $LIST_PARAMS{UID} || $FORM{UID} ){
    my $res = docs_invoice( $attr );

    if ( $res == 0 ){
      return 1;
    }
  }
  elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
    $Docs->invoice_del( $FORM{del} );

    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{DELETED} N: [$FORM{del}]" );
    }
    elsif ( _error_show( $Docs ) ){
      return 0;
    }
  }
  elsif ( $FORM{search_form} || $FORM{search} ){
    my %info = ();
    $info{PAID_STATUS_SEL} = $html->form_select(
      'PAID_STATUS',
      {
        SELECTED     => $FORM{PAID_STATUS},
        ARRAY_NUM_ID => 1,
        SEL_ARRAY    => [ $lang{ALL}, $lang{UNPAID}, $lang{PAID}, ],
        NO_ID        => 1
      }
    );

    $info{PAYMENT_METHOD_SEL} = $html->form_select(
      'PAYMENT_METHOD',
      {
        SELECTED => (defined( $FORM{PAYMENT_METHOD} ) && $FORM{PAYMENT_METHOD} ne '') ? $FORM{METHOD} : '',
        SEL_HASH => { '' => $lang{ALL}, %{$PAYMENTS_METHODS} },
        NO_ID    => 1,
        SORT_KEY => 1
      }
    );

    $info{CUSTOMER_TYPE_SEL} = $html->form_select(
      'CUSTOMER_TYPE',
      {
        SELECTED => $FORM{CUSTOMER_TYPE} || '',
        SEL_HASH => {
          ''   => $lang{ALL},
          '=0' => $lang{USERS},
          ">0" => $lang{COMPANIES}
        },
        NO_ID    => 1,
        SORT_KEY => 1
      }
    );

    form_search( { SEARCH_FORM =>
        ($FORM{pdf}) ? '' : $html->tpl_show( _include( 'docs_invoice_search', 'Docs' ), { %info, %FORM },
          { notprint => 1 } ), SHOW_PERIOD => 1 } );
  }

  if ( $LIST_PARAMS{COMPANY_ID} || $FORM{CUSTOMER_TYPE} ){
    $LIST_PARAMS{COMPANY_ID} = $LIST_PARAMS{COMPANY_ID} || $FORM{CUSTOMER_TYPE};
  }

  if ( !$FORM{sort} ){
    $LIST_PARAMS{SORT} = '2 desc, 1';
    $LIST_PARAMS{DESC} = 'DESC';
  }

  if ( $FORM{print_list} ){
    print "Content-Type: text/html\n\n" if ($debug > 2);
    #Get payments
    my $i2p_list = $Docs->invoices2payments_list( { %LIST_PARAMS,
      COLS_NAME => 1,
    } );

    my %payments_list = ();
    my $i = 1;
    if($Docs->{TOTAL}) {
      foreach my $i2p (@{ $i2p_list }) {
        $payments_list{$i2p->{invoice_id}}{'PAYMENT_DATE_'.$i} = $i2p->{date};
        $payments_list{$i2p->{invoice_id}}{'PAYMENT_COMMENTS_'.$i} = $i2p->{dsc};
        $payments_list{$i2p->{invoice_id}}{'PAYMENT_SUM_'.$i} = $i2p->{payment_sum};
        $payments_list{$i2p->{invoice_id}}{'PAYMENT_ID_'.$i} = $i2p->{payment_id};
        $payments_list{$i2p->{invoice_id}}{'PAYMENT_ALT_SUM_'.$i} = sprintf( "%.2f", $i2p->{amount} );
        $i++;
      }
    }

    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});

    my $invoices_list = $Docs->invoices_list( {
      ORDERS_LIST    => 1,
      COLS_NAME      => 1,
      REPRESENTATIVE => '_SHOW',
      DOCS_DEPOSIT   => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      ADDRESS_STREET => '_SHOW',
      ADDRESS_BUILD  => '_SHOW',
      ADDRESS_FLAT   => '_SHOW',
      PHONE          => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      CONTRACT_DATE  => '_SHOW',
      BILL_ID        => '_SHOW',
      EMAIL          => '_SHOW',
      FIO            => '_SHOW',
      CREATED        => '_SHOW',
      ALT_SUM        => '_SHOW',
      EXCHANGE_RATE  => '_SHOW',
      CURRENCY       => '_SHOW',
      %LIST_PARAMS,
      LOGIN          => (!$LIST_PARAMS{LOGIN}) ? '_SHOW' : $LIST_PARAMS{LOGIN},
      %FORM,
      COLS_UPPER     => 1
    });
    my @MULTI_ARR = ();
    my $doc_num = 0;

    foreach my $d ( @{$invoices_list} ){
      $d->{AMOUNT_FOR_PAY} = ($d->{DEPOSIT} < 0) ? abs( $d->{DEPOSIT} ) : 0 - $d->{DEPOSIT};
      $d->{NUMBER} = $d->{INVOICE_NUM} || '-';
      my ($year, $month, $day) = split( /-/, $d->{DATE}, 3 );
      $d->{FROM_DATE_LIT} = "$day " . $MONTHES_LIT[ int( $month ) - 1 ] . " $year $lang{YEAR_SHORT}";
      $d->{DATE_EURO_STANDART} = "$day.$month.$year";
      $d->{FIO} = $d->{CUSTOMER} if ($d->{CUSTOMER});
      $d->{ADDRESS_FULL} = "$d->{ADDRESS_STREET}, $d->{ADDRESS_BUILD}, $d->{ADDRESS_FLAT}";
      $d->{TOTAL_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} );
      $d->{A_FIO} = $d->{ADMIN_FIO};
      $d->{DEPOSIT} = sprintf( "%.2f", $d->{DOCS_DEPOSIT} );
      $d->{DOC_ID} = $d->{ID};
      $d->{AMOUNT_FOR_PAY} = ($d->{DEPOSIT} < 0) ? abs( $d->{DEPOSIT} ) : 0 - $d->{DEPOSIT};
      $FORM{COMPANY_ID} = $d->{COMPANY_ID};

      if ( $conf{DOCS_VAT_INCLUDE} ){
        $d->{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
          $d->{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
        $d->{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $d->{TOTAL_SUM} - $d->{ORDER_TOTAL_SUM_VAT} );
        $d->{TOTAL_SUM_VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );
      }

      $i = 0;

      foreach my $order ( @{ $Docs->{ORDERS}->{$d->{DOC_ID}} } ){
        $i++;
        $d->{ORDER} .= sprintf(
          "<tr><td align=right>%d</td><td>%s</td><td align=right>%d</td><td align=right>%d</td><td align=right>%.2f</td><td align=right>%.2f</td></tr>\n"
          , $i, $order->{orders}, $order->{unit}, $order->{counts}, $order->{price},
          ($order->{counts} * $order->{price}) ) if (!$conf{DOCS_PDF_PRINT});

        my $count = $order->{counts} || 1;
        my $sum = sprintf( "%.2f", $count * $order->{price} );

        $d->{ 'LOGIN_' . $i } = $d->{LOGIN};
        $d->{ 'ORDER_NUM_' . $i } = $i;
        $d->{ 'ORDER_NAME_' . $i } = $order->{orders};
        $d->{ 'ORDER_COUNT_' . $i } = $count;
        $d->{ 'ORDER_PRICE_' . $i } = $order->{price};
        $d->{ 'ORDER_SUM_' . $i } = $sum;

        $d->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            ($conf{DOCS_VAT_INCLUDE}) ? $order->{price} - $order->{price} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $order->{price} );
        $d->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );

        if ( $order->{fees_id} == 0 ){
          $d->{AMOUNT_FOR_PAY} += $d->{ 'ORDER_COUNT_' . $i } * $d->{ 'ORDER_PRICE_' . $i }
        }

        if ( $d->{EXCHANGE_RATE} > 0 ){
          $d->{ 'ORDER_ALT_SUM_' . $i } = sprintf( "%.2f", $d->{ 'ORDER_SUM_' . $i } * $d->{EXCHANGE_RATE} );
          $d->{ 'ORDER_ALT_PRICE_' . $i } = sprintf( "%.2f", $d->{ 'ORDER_PRICE_' . $i } * $d->{EXCHANGE_RATE} );
          $d->{ 'ORDER_ALT_VAT_' . $i } = sprintf( "%.2f", $d->{ 'ORDER_VAT_' . $i } * $d->{EXCHANGE_RATE} );
          $d->{ 'ORDER_ALT_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            $d->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } * $d->{EXCHANGE_RATE} );
          $d->{ 'ORDER_ALT_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
            $d->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } * $d->{EXCHANGE_RATE} );
        }
      }

      $d->{TOTAL_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} );
      $d->{AMOUNT_FOR_PAY} = sprintf( "%.2f", $d->{AMOUNT_FOR_PAY} );
      if ( $d->{EXCHANGE_RATE} > 0 ){
        $d->{TOTAL_ALT_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} * $d->{EXCHANGE_RATE} );
        $d->{AMOUNT_FOR_PAY_ALT} = sprintf( "%.2f", $d->{AMOUNT_FOR_PAY} * $d->{EXCHANGE_RATE} );
        $d->{DEPOSIT_ALT} = sprintf( "%.2f", $d->{DEPOSIT} * $d->{EXCHANGE_RATE} );
        $d->{CHARGED_ALT_SUM} = sprintf( "%.2f", $d->{CHARGED_SUM} * $d->{EXCHANGE_RATE} );
      }

      $d = { %{ $payments_list{$d->{ID}} }, %{$d} };
      $d->{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $d->{TOTAL_SUM} - ($d->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $d->{TOTAL_SUM} );
      $d->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $d->{TOTAL_SUM} - $d->{'TOTAL_SUM_WITHOUT_VAT'} );

      $d->{SUM_LIT} = int2ml( "$d->{TOTAL_SUM}",
        {
          ONES             => \@ones,
          TWOS             => \@twos,
          FIFTH            => \@fifth,
          ONE              => \@one,
          ONEST            => \@onest,
          TEN              => \@ten,
          TENS             => \@tens,
          HUNDRED          => \@hundred,
          MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names,
          LOCALE           => $conf{LOCALE}
        }
      );

      if ( $d->{TOTAL_ALT_SUM} ){
        $d->{SUM_ALT_LIT} = int2ml( "$d->{TOTAL_ALT_SUM}",
          {
            ONES             => \@ones,
            TWOS             => \@twos,
            FIFTH            => \@fifth,
            ONE              => \@one,
            ONEST            => \@onest,
            TEN              => \@ten,
            TENS             => \@tens,
            HUNDRED          => \@hundred,
            MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names,
            LOCALE           => $conf{LOCALE}
          }
        );
      }

      push @MULTI_ARR, { %{$d}, DOC_NUMBER => sprintf( "%.6d", $doc_num ), };
      $doc_num++;
      print "UID: LOGIN: $d->{LOGIN} FIO: $d->{FIO} SUM: $d->{TOTAL_SUM}\n" if ($debug > 2);
    }

    print $html->header() if ($FORM{qindex});
    my $tpl = ($FORM{COMPANY_ID}) ? 'docs_invoice_company' : 'docs_invoice';
    $tpl .= '_alt' if ($FORM{alt_tpl});

    $html->tpl_show(
      _include( $tpl, 'Docs', { pdf => $FORM{pdf} } ),
      undef,
      {
        MULTI_DOCS => \@MULTI_ARR,
        debug      => $debug
      }
    );
    return 0;
  }

  if ( !$user->{UID} ){
    if($attr->{USER_INFO}) {
      %LIST_PARAMS = (  UID => $attr->{USER_INFO}->{UID} );
    }

    $LIST_PARAMS{ORDERS_LIST} = $FORM{xml} if ($FORM{xml});
    $LIST_PARAMS{LOGIN} = '_SHOW' if (!$FORM{UID});
    $LIST_PARAMS{ALT_SUM} = ($conf{DOCS_CURRENCY}) ? '_SHOW' : undef;
  }

  my $PAYMENT_METHODS = get_payment_methods();
  my Abills::HTML $table;
  my $invoice_list;

  ($table, $invoice_list) = result_former( {
    INPUT_DATA      => $Docs,
    FUNCTION        => 'invoices_list',
    BASE_FIELDS     => (!$user->{UID}) ? 5 : 3,
    DEFAULT_FIELDS  =>
      ($FORM{UID}) ? 'INVOICE_NUM,DATE,CUSTOMER,PAYMENT_SUM' : 'INVOICE_NUM,DATE,CUSTOMER,PAYMENT_SUM,LOGIN',
    HIDDEN_FIELDS   => 'CURRENCY',
    FUNCTION_FIELDS =>
      (!$user->{UID}) ? (($conf{DOCS_INVOICE_ALT_TPL}) ? 'print,' : '') . 'print,payment,show,send,del' : 'print',
    MULTISELECT     => ($FORM{UID}) ? 'UID:uid' : '',
    EXT_TITLES      => {
      invoice_num    => '#',
      date           => $lang{DATE},
      customer       => $lang{CUSTOMER},
      total_sum      => "$lang{SUM}",
      payment_id     => "$lang{PAYMENTS} ID",
      login          => "$lang{USER}",
      admin_name     => "$lang{ADMIN}",
      created        => "$lang{CREATED}",
      payment_method => "$lang{PAYMENT_METHOD}",
      ext_id         => "EXT ID",
      group_name     => "$lang{GROUP} $lang{NAME}",
      currency       => "$lang{CURRENCY}",
      alt_sum        => "$lang{ALT} $lang{SUM}",
      exchange_rate  => "$lang{EXCHANGE_RATE}",
      payment_sum    => "$lang{SUM} $lang{PAYMENTS}",
      docs_deposit   => "$lang{OPERATION_DEPOSIT}",
      deposit        => "$lang{CURRENT_DEPOSIT}"
    },
    TABLE           => {
      width      => '100%',
      caption    => $lang{INVOICES},
      qs         => $pages_qs,
      ID         => 'DOCS_INVOICES_LIST',
      #header     => $status_bar,
      EXPORT     => 1,
      #SELECT_ALL => (!$user->{UID}) ? 1 : undef,
      SELECT_ALL => ($user && $user->{UID}) ? undef : "DOCS_INVOICES_LIST:IDS:$lang{SELECT_ALL}",
      MENU       => "$lang{SEARCH}:index=$index&search_form=1" . (($FORM{UID}) ? "&UID=$FORM{UID}" : '') . ":search",
    },
  });

  my $invoice_list_fields = $Docs->{SEARCH_FIELDS_COUNT};
  my %i2p_hash = ();
  my @invoice_id_arr = ();

  foreach my $invoice ( @{$invoice_list} ){
    push @invoice_id_arr, $invoice->{id};
  }

  my $i2p_list = $Docs->invoices2payments_list({
    INVOICE_ID => join( ';', @invoice_id_arr ),
    COLS_NAME  => 1,
    PAGE_ROWS  => 100000
  });

  foreach my $i2p ( @{$i2p_list} ){
    push @{ $i2p_hash{($i2p->{invoice_id} || '')} }, "$i2p->{payment_id}:" . ($i2p->{invoiced_sum} || 0);
  }

  my %orders_hash = ();

  if ( $Docs->{ORDERS} ){
    %orders_hash = %{ $Docs->{ORDERS} };
  }

  foreach my $invoice ( @{$invoice_list} ){
    my @fields_array = ();

    if ( !$user->{UID} && !$FORM{qindex} ){
      push @fields_array, $html->form_input( 'IDS', $invoice->{id}, {
            TYPE    => 'checkbox',
            STATE   => (in_array( $invoice->{id}, [ split( /, /, $FORM{IDS} || '' ) ] )) ? 'checked' : undef,
            FORM_ID => 'DOCS_INVOICES_LIST',
          });
    }

    for ( my $i = 0; $i < ((!$user->{UID}) ? 5 : 3) + $invoice_list_fields; $i++ ){
      my $val = '';
      my $field_name = $Docs->{COL_NAMES_ARR}->[$i] || '';

      if ( $field_name eq 'date' ){
        $val = $html->button( "$invoice->{date}",
          "qindex=$index&print=$invoice->{id}"
            . ((! $FORM{UID}) ? "&UID=$invoice->{uid}" : q{})
            . $pages_qs . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
          , { ex_params => 'target=_new' } ),
      }
      elsif ( $field_name eq 'login_status' ){
        $val = ($invoice->{$field_name} && $invoice->{$field_name} > 0) ? $html->color_mark($service_status[ $invoice->{$field_name} ],
            $service_status_colors[ $invoice->{$field_name} ] ) : $service_status[$invoice->{$field_name}];
      }
      elsif ( $field_name eq 'payment_sum' ){
        my $invoice_sum = $invoice->{total_sum};
        $val = '';

        if ( $i2p_hash{$invoice->{id}} && !$user->{UID} ){
          foreach my $p2i_val ( @{ $i2p_hash{$invoice->{id}} } ){
            my ($payment_id, $invoiced_sum) = split( /:/, $p2i_val );
            $val .= $html->button( $invoiced_sum,
              "index=" . get_function_index( 'form_payments' ) . "&ID=$payment_id&search=1" ) . $html->br();
            $invoice_sum -= $invoiced_sum;
          }
        }

        if ( $invoice_sum > 0 ){
          $val .= $html->color_mark( sprintf( "%.2f", $invoice_sum ),
            $_COLORS[6] ) . $html->br() . ((!$user->{UID} ) ? $html->button(
              "$lang{SEARCH} $lang{PAYMENTS}", "index=$index&UID=$invoice->{uid}&UNINVOICED=$invoice->{id}",
              { class => 'search' } )                       : '');
        }
      }
      elsif ( $field_name eq 'login' ){
        $val = $html->button( $invoice->{login},
          "index=11&UID=$invoice->{uid}" ) . (($invoice->{company_id}) ? $html->br() . $html->button(
              ($invoice->{company_name}) ? substr( $invoice->{company_name}, 0, 30 ) : '',
            "index=13&COMPANY_ID=$invoice->{company_id}", { class => 'small' } ) : '');
      }
      elsif ( $field_name =~ /deposit/ ){
        $val = ($invoice->{$field_name} && $invoice->{$field_name} < 0) ? $html->color_mark( $invoice->{$field_name},
            $_COLORS[6] )                    : $invoice->{$field_name};
      }
      elsif ( $field_name eq 'payment_method' ){
        $val = ($invoice->{payment_method} && $PAYMENT_METHODS->{ $invoice->{payment_method} }) ? $PAYMENT_METHODS->{ $invoice->{payment_method} } : $invoice->{payment_method};
      }
      elsif ( $field_name eq 'alt_sum' ){
        $val = _alt_sum_filter($invoice->{$field_name}, $invoice->{currency});
      }
      else{
        $val = $invoice->{$field_name};
      }

      unless ( $field_name eq 'currency'){
        push @fields_array, $val;
      }
    }

    my @function_fields = ($html->button( $lang{PRINT},
      "qindex=$index&print=$invoice->{id}"
        . ((! $FORM{UID}) ? "&UID=$invoice->{uid}" : q{})
        . $pages_qs . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
      , { ex_params => 'target=_new', class => 'print' } )
    );

    if ( !$user->{UID} ){
      if ( $conf{DOCS_INVOICE_ALT_TPL} ){
        push @function_fields, $html->button($lang{PRINT_EXT},
            "qindex=$index&print=$invoice->{id}&UID=$invoice->{uid}&alt_tpl=1" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
            , { ex_params => 'target=_new', class => 'glyphicon glyphicon-print text-success' } );
      }

      $invoice->{alt_sum} //= 0;
      my $payments_info = ($invoice->{currency} && $invoice->{currency} > 0 && !$conf{DOCS_PAYMENT_SYSTEM_CURRENCY}) ? "&SUM=$invoice->{alt_sum}&ISO=$invoice->{currency}" : "&SUM=$invoice->{total_sum}";

      if ( $conf{DOCS_INVOICE_TERMO_PRINTER} ){
        push @function_fields, $html->button('',
            "qindex=$index&print=$invoice->{id}&UID=$invoice->{uid}&termo_printer_tpl=1" . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
            , { ex_params => 'target=_new ', class => 'glyphicon glyphicon-print text-warning', title => $lang{PRINT_TERMO_PRINTER} } );
      }

      push @function_fields,
        $html->button( $lang{PAYMENTS}, "index=2&INVOICE_ID=$invoice->{id}&UID=$invoice->{uid}$payments_info",
          { class => 'payments' } )
        , $html->button( $lang{INFO}, "index=$index&SHOW_ORDERS=$invoice->{id}&UID=$invoice->{uid}", {
            class           => 'show',
            NEW_WINDOW      => "$SELF_URL?qindex=$index&SHOW_ORDERS=$invoice->{id}&UID=$invoice->{uid}&header=1",
            NEW_WINDOW_SIZE => "640:600"
          } )
        , $html->button( $lang{SEND_MAIL},
          "qindex=" . get_function_index( 'docs_invoices_list' ) . "&sendmail=$invoice->{id}&UID=$invoice->{uid}",
          { ex_params => 'target=_new', class => 'sendmail' } )
        , (($permissions{1} && $permissions{1}{2})  ? $html->button( $lang{DEL},
            "index=$index&del=$invoice->{id}&UID=$invoice->{uid}",
            { MESSAGE => "$lang{DEL} ID $invoice->{id} ?", class => 'del' } ) : '')
      ;

      if ( $FORM{xml} ){
        my $orders = '';
        my $i = 1;
        foreach my $order ( @{ $Docs->{ORDERS}{$invoice->{id}} } ){
          $orders .= "<orders>
                    <num>$i</num>
                    <order>". ($order->{orders} || '') ."</order>
                    <unit>". ($order->{unit} || '') ."</unit>
                    <counts>". ($order->{counts} || '') ."</counts>
                    <price>". ($order->{price} || '') ."</price>
                   </orders>";
          $i++;
        }
        push @fields_array, $orders;
      }
    }

    $table->addrow( @fields_array, join(' ', @function_fields) );
  }


  if ( $user && $user->{UID} ){
    printf $table->show();
  }
  else{
    my $payment_method = $html->form_select(
      'METHOD',
      {
        SELECTED     => (defined( $FORM{METHOD} ) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
        SEL_HASH     => get_payment_methods(),
        SORT_KEY_NUM => 1,
        NO_ID        => 1,
        FORM_ID      => 'DOCS_INVOICES_LIST',
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    print $html->form_main({
      CONTENT => $table->show( { OUTPUT2RETURN => 1 } ) . (($FORM{json} && $payment_method) ? ",$payment_method" : $payment_method  ),
      HIDDEN  => {
        index => $index,
        pg    => $FORM{pg} || undef,
        sort  => $FORM{sort} || undef,
      },
      SUBMIT  => { 'add_payment' => "$lang{ADD} $lang{PAYMENTS}" },
      NAME    => 'DOCS_INVOICES_LIST',
      ID      => 'DOCS_INVOICES_LIST',
    });
  }

  if ( $FORM{pg} ){
    $pages_qs .= "&pg=$FORM{pg}";
  }

  if (!$admin->{MAX_ROWS}) {
    my @total_result = ();

    push @total_result, [ "$lang{TOTAL}:", $html->b($Docs->{TOTAL_INVOICES} || 0) ];
    push @total_result,
      [ "$lang{USERS}:", $html->b($Docs->{TOTAL_USERS}) ] if ($Docs->{TOTAL_USERS} && $Docs->{TOTAL_USERS} > 1);

    if ($Docs->{TOTAL_INVOICES}) {
      push @total_result,
        [ (($user->{UID}) ? '' : $html->button("$lang{PRINT} $lang{LIST}",
              "qindex=" . $index . "&print_list=1$pages_qs" .
                (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { BUTTON => 1, ex_params => 'target=new' })) .
            (($conf{DOCS_INVOICE_ALT_TPL} && !$user->{UID})                                              ? $html->button(
                "$lang{PRINT_EXT_LIST}", "qindex=" . $index . "&print_list=1$pages_qs&alt_tpl=1" .
                  (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { BUTTON => 1, ex_params => 'target=new' }) : ''),
          '' ],
        [ "$lang{SUM}:", $html->b(sprintf("%.2f", $Docs->{TOTAL_SUM} || 0)) ],
        [ "$lang{UNPAID}:", $html->b(sprintf("%.2f", ($Docs->{TOTAL_SUM} - ($Docs->{PAYMENT_SUM} || 0)))) ];
    }

    $table = $html->table(
      {
        width => '100%',
        rows  => \@total_result,
        ID    => 'DOCS_INVOICE_TOTALS'
      }
    );

    print $table->show();
  }

  return 1;
}


#**********************************************************
=head2 docs_invoices_multi_create($attr)

=cut
#**********************************************************
sub docs_invoices_multi_create{
  my ($attr) = @_;

  if ( $FORM{create} ){
    if ( $FORM{SUM} < 0.01 ){
      $html->message( 'err', "$lang{ERROR}", "$lang{WRONG_SUM}" );
      return 0;
    }

    my @uids_arr = split( /, /, $FORM{UIDS} );

    my $count = 0;
    my $total_sum = 0;
    foreach my $uid ( @uids_arr ){
      $count++;
      $FORM{UID} = $uid;
      $Docs->invoice_add( { %FORM } );
      delete( $FORM{create} );
      if ( !$Docs->{errno} ){
        if ( $conf{DOCS_PDF_PRINT} ){
          if ( $FORM{SEND_EMAIL} ){
            $FORM{pdf} = 1;
            $FORM{print} = $Docs->{DOC_ID};

            docs_invoice(
              {
                GET_EMAIL_INFO => 1,
                SEND_EMAIL   => 1,
                EMAIL        => $FORM{EMAIL},
                %{$attr}
              }
            );
          }
        }
      }
    }

    $total_sum = $count * $FORM{SUM};
    $html->message( 'info', "$lang{INVOICE} $lang{CREATED}", "$lang{INVOICE} $lang{CREATED}\n $lang{COUNT}: $count \n $lang{SUM}: $total_sum" );
    return 0;
  }

  # $FORM{GROUP_SEL} = sel_groups();
  # $html->tpl_show( _include( 'docs_invoice_multi_sel', 'Docs' ), { %FORM, GROUP_SEL => sel_groups() } );
  %LIST_PARAMS = (%LIST_PARAMS, %FORM);

  my ($result) = result_former( {
    INPUT_DATA     => $users,
    FUNCTION       => 'list',
    DEFAULT_FIELDS => 'LOGIN,FIO',
    MULTISELECT    => 'UIDS:uid:multi_add',
    TABLE          => {
      width       => '100%',
      caption     => $lang{USERS},
      qs          => $pages_qs,
      ID          => 'DOCS_INVOICE_USERS',
      SELECT_ALL  => 'users_list:UIDS:$lang{SELECT_ALL}'
    },
    MAKE_ROWS     => 1,
    TOTAL         => 1,
    OUTPUT2RETURN => 1
  } );

  $Docs->{USERS_TABLE} = $result;
  $Docs->{DATE} = $DATE;
  $Docs->{SUM} = $FORM{SUM} || 0.00;

  $html->tpl_show( _include( 'docs_invoice_multi_add', 'Docs' ), $Docs );

  return 1;
}

#**********************************************************
=head2 docs_invoice($attr)

  Arguments:
    $attr
      INVOICE_DATA - Invoice date
      UID
      QUITE
      REGISTRATION

  Retunr:
    TRUE or FALSE

=cut
#**********************************************************
sub docs_invoice{
  my ($attr) = @_;

  $users = $user if ($user && $user->{UID});
  $Docs->invoice_defaults();

  my %invoice_create_info = ();
  if ( $attr->{INVOICE_DATA} ){
    %invoice_create_info = %{ $attr->{INVOICE_DATA} };
  }
  else {
    %invoice_create_info = %FORM;
  }

  $Docs->{DATE} = $DATE;
  if (!$invoice_create_info{UID}) {
    if ($LIST_PARAMS{UID}) {
      $invoice_create_info{UID} = $LIST_PARAMS{UID};
    }
    else {
      $invoice_create_info{UID} = $attr->{UID};
    }
  }

  my $uid = $invoice_create_info{UID} || 0;

  $invoice_create_info{ORDER} .= ' ' . $invoice_create_info{ORDER2} if ($invoice_create_info{ORDER2});

  if ( $invoice_create_info{create} ){
    $invoice_create_info{SUM} =~ s/\,/\./g if ($invoice_create_info{SUM});
    if ( $invoice_create_info{OP_SID} && $invoice_create_info{OP_SID} eq ($COOKIES{OP_SID} || '') ){
      $html->message( 'err', "$lang{DOCS} : $lang{ERROR}", $lang{EXIST}, { ID => 511 } );
    }
    elsif ( !$invoice_create_info{IDS} && (! $invoice_create_info{SUM} || $invoice_create_info{SUM} !~ /^[0-9,\.]+$/ || $invoice_create_info{SUM} < 0.01)){
      $html->message( 'err', "$lang{DOCS} :$lang{ERROR}", $lang{WRONG_SUM}, { ID => 512 } );
    }
    elsif ( $invoice_create_info{PREVIEW} ){
      docs_preview( 'invoice', \%invoice_create_info );
      return 1;
    }
    else{
      if ( $invoice_create_info{VAT} && $invoice_create_info{VAT} == 1 ){
        $invoice_create_info{VAT} = $conf{DOCS_VAT_INCLUDE};
      }

      $invoice_create_info{DOCS_CURRENCY} = $invoice_create_info{CURRENCY};

      if ( ($conf{SYSTEM_CURRENCY} && $conf{DOCS_CURRENCY})
        && $conf{SYSTEM_CURRENCY} ne $conf{DOCS_CURRENCY} )
      {
        require Finance;
        Finance->import();
        my $Finance = Finance->new( $db, $admin, \%conf );
        $Finance->exchange_info( 0, { ISO => $invoice_create_info{DOCS_CURRENCY} || $conf{DOCS_CURRENCY} } );
        $invoice_create_info{EXCHANGE_RATE} = $Finance->{ER_RATE};
        $invoice_create_info{DOCS_CURRENCY} = $Finance->{ISO};
      }

      $Docs->invoice_add( {
        %invoice_create_info,
        DEPOSIT => ($invoice_create_info{INCLUDE_DEPOSIT}) ? $users->{DEPOSIT} : 0
      });

      if ( !$Docs->{errno} ){
        #Add date of last invoice
        if ( $attr->{REGISTRATION} ){
          my ($Y, $M) = split( /-/, $DATE, 3 );
          $Docs->user_change(
            {
              UID          => $uid,
              INVOICE_DATE => ($users->{ACTIVATE} ne '0000-00-00') ? $DATE : "$Y-$M-01",
              CHANGE_DATE  => 1
            }
          );
          delete($Docs->{errno});
        }

        $FORM{INVOICE_ID} = $Docs->{DOC_ID};
        #$Docs->invoice_info( $Docs->{DOC_ID}, { UID => $FORM{UID} } );
        $Docs->{CUSTOMER} ||= $Docs->{COMPANY_NAME} || $Docs->{FIO} || '-';

        my $list = $Docs->{ORDERS};
        my $i = 0;

        foreach my $line ( @{ $list } ){
          $i++;
          my $sum = sprintf( "%.2f", $line->[2] * $line->[4] );
          if ( !$FORM{pdf} ){
            $Docs->{ORDER} .= $html->tpl_show(
              _include( 'docs_invoice_order_row', 'Docs' ),
              {
                %$Docs,
                NUMBER => $i,
                NAME   => $line->[1],
                COUNT  => $line->[2] || 1,
                UNIT   => $units[$line->[3]] || 1,
                PRICE  => $line->[4],
                SUM    => $sum
              },
              { OUTPUT2RETURN => 1 }
            );
          }
        }

        $FORM{pdf} = $conf{DOCS_PDF_PRINT};

        if ( !$attr->{QUITE} ){
          my $qs = "qindex=" . get_function_index( 'docs_invoices_list' ) . "&INVOICE_ID=$Docs->{DOC_ID}&UID=$uid";
          $html->message(
            'info',
            "$lang{INVOICE} $lang{CREATED}",
            "$lang{INVOICE} $lang{NUM}: [$Docs->{INVOICE_NUM}]\n $lang{DATE}: $Docs->{DATE}\n $lang{TOTAL} $lang{SUM}: $Docs->{TOTAL_SUM}\n"
              . (($invoice_create_info{DOCS_CURRENCY} && $invoice_create_info{EXCHANGE_RATE} && $invoice_create_info{EXCHANGE_RATE} > 0)  ? "$lang{ALT} $lang{SUM}: " . sprintf( "%.2f",
                ($invoice_create_info{EXCHANGE_RATE} * $Docs->{TOTAL_SUM}) ) . "\n" : '')
              . $html->button( "$lang{SEND} E-mail", "$qs&sendmail=$Docs->{DOC_ID}",
              { ex_params => 'target=_new', class => 'sendmail' } )
              . ' '
              . $html->button( $lang{PRINT}, "$qs&print=$Docs->{DOC_ID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
              { ex_params => 'target=_new', class => 'print' } )
          );
        }

        $attr->{OUTPUT2RETURN}=1 if($FORM{SKIP_SEND_MAIL});
        $attr->{OUTPUT2RETURN}=1 if(! $FORM{pdf});
        docs_invoice_print( $Docs->{DOC_ID}, {
          GET_EMAIL_INFO => 1,
          SEND_EMAIL     => (defined( $FORM{SEND_EMAIL} )) ? $FORM{SEND_EMAIL} : $attr->{SEND_EMAIL},
          EMAIL          => $invoice_create_info{EMAIL},
          UID            => $uid,
          DOC_INFO       => $Docs,
          %{$attr}
        });

        return ($attr->{REGISTRATION}) ? 1 : $Docs->{DOC_ID};
      }
      else{
        if ( !$invoice_create_info{QUICK} ){
          _error_show( $Docs, { MESSAGE => $lang{INVOICE} } );
        }
      }
    }
  }
  elsif ( $FORM{print} ){
    docs_invoice_print( $FORM{print}, { UID => $uid } );
    return 0;
  }
  elsif ( $FORM{sendmail} ){
    my $res = docs_invoice_print( $FORM{sendmail},
      { UID            => $uid,
        SEND_EMAIL     => 1,
        GET_EMAIL_INFO => 1
      } );

    if ( $res ){
      $html->message( 'info', "$lang{INFO}", "E-Mail $lang{SENDED} " );
    }
    else{
      $html->message( 'info', "$lang{ERROR}", "E-Mail $lang{SENDED} Error: $FORM{ERR_MESSAGE} " );
    }

    return 0;
  }
  elsif ( $FORM{change} && $FORM{ID} ){
    $Docs->invoice_change( { %FORM, UID => $users->{UID} } );
    if ( !$Docs->{errno} ){
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED} N: [ ". ($FORM{ID} || q{}) ." ]" );
    }
  }
  elsif ( defined( $FORM{chg} ) ){
    $Docs->invoice_info( $FORM{chg} );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{CHANGING} N: [$FORM{chg}]" );
    }
  }
  elsif ( defined( $FORM{del} ) && $FORM{COMMENTS} ){
    $Docs->invoice_del( $FORM{del} );
    if ( !$Docs->{errno} ){
      $html->message( 'info', "$lang{INFO}", "$lang{DELETED} ID: [$FORM{del}]" );
    }
  }
  elsif ( $FORM{SHOW_ORDERS} ){
    $Docs->invoice_info( $FORM{SHOW_ORDERS}, { UID => $uid } );

    my $table = $html->table(
      {
        width       => ($user && $user->{UID}) ? '600' : '100%',
        border      => 1,
        caption     => "$lang{INVOICE}: $Docs->{INVOICE_NUM} $lang{DATE}: $Docs->{DATE}",
        title_plain => [ '#', $lang{NAME}, $lang{COUNT}, $lang{PRICE}, $lang{SUM}, $lang{TAX} ],
        ID          => 'DOCS_INVOCE_ORDERS',
      }
    );

    if ( $Docs->{TOTAL} > 0 ){
      my $list = $Docs->{ORDERS};
      my $i=0;
      foreach my $line ( @{$list} ){
        $i++;
        $table->addrow(
          $i,
          _translate($line->[1]),
          $line->[2],
          sprintf( "%.2f", $line->[4]),
          sprintf( "%.2f", $line->[2] * $line->[4] ),
          sprintf( "%.2f", $line->[5])
        );
      }
    }

    print $table->show();
    return 0;
  }

  if ( ! $user || !$user->{UID} ){
    $Docs->{FORM_INVOICE_ID} = $html->tpl_show( templates( 'form_row' ), {
        ID    => 'INVOICE_NUM',
        NAME  => $lang{NUM},
        VALUE => $html->form_input( 'INVOICE_NUM', '', { OUTPUT2RETURN => 1 } ) },
      { OUTPUT2RETURN => 1 } );

    $Docs->{DATE_FIELD} = $html->date_fld2( 'DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS } );
  }
  else{
    $Docs->{DATE_FIELD} = "$DATE";
    #$users = $user;
  }

  if ( $conf{DOCS_FEES_METHOD_ORDERS} ){
    my %FEES_METHODS = %{ get_fees_types() };
    my @orders = values %FEES_METHODS;

    $Docs->{SEL_ORDER} .= $html->form_select(
      'ORDER',
      {
        SELECTED       => $FORM{ORDER} || '',
        SEL_ARRAY      => [ '', @orders ],
        NO_ID          => 1,
        MAIN_MENU      => get_function_index( 'form_fees_type' ),
        MAIN_MENU_ARGV => "chg=" . ($FORM{ORDER} || '')
      }
    );
  }
  else{
    $Docs->{SEL_ORDER} .= $html->form_select(
      'ORDER',
      {
        SELECTED  => $FORM{ORDER},
        SEL_ARRAY => ($conf{DOCS_ORDERS}) ? $conf{DOCS_ORDERS} : [ $lang{DV} ],
        NO_ID     => 1
      }
    );
  }

  #if($user && !$users) {
  #  $users = $user;
  #}
  $users->pi( { UID => $users->{UID} || $uid } );
  $Docs->{OP_SID}   = mk_unique_value( 16 );
  $Docs->{CUSTOMER} = $users->{COMPANY_NAME} || $users->{FIO} || '-';
  $Docs->{CAPTION}  = $lang{INVOICE};
  if ( !$Docs->{MONTH} ){
    my (undef, $M, undef) = split( /-/, $DATE );
    $Docs->{MONTH} = $MONTHES[ int( $M - 1 ) ];
  }

  if ( !$FORM{pdf} ){
    docs_invoice_period({ %FORM, %$attr, UID => $uid });
  }

  return 1;
}


#**********************************************************
=head2 docs_invoice_period($attr)

   Arguments:
     $attr
       REGISTRATION
       UID

   Returns:
     True or False

=cut
#**********************************************************
sub docs_invoice_period {
  my ($attr) = @_;

  my ($Y, $M, $D) = split( /-/, $DATE );

  my $uid = $attr->{UID} || 0;
  my $service_activate = $users->{ACTIVATE} || '0000-00-00';

  if ( $attr->{REGISTRATION} || $FORM{ALL_SERVICES} ){
    $Docs->{DATE} = $html->date_fld2( 'DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'receipt_add', WEEK_DAYS => \@WEEKDAYS } );

    # Get docs info
    $Docs->user_info( $uid );
    if ( $Docs->{TOTAL} ){
      if ( !defined( $FORM{NEXT_PERIOD} ) ){
        $FORM{NEXT_PERIOD} = 0;
        $FORM{NEXT_PERIOD} = 0;
        #$FORM{NEXT_PERIOD} = $Docs->{INVOICING_PERIOD} if ($Docs->{INVOICING_PERIOD});
      }
      $service_activate = $Docs->{INVOICE_DATE};
    }
    elsif($FORM{NEXT_PERIOD} && $FORM{NEXT_PERIOD} > 1) {
      $html->message('warn', "Use user docs configuration for multiperiod ". $html->button($lang{CONFIGURATION}, 'index='. get_function_index('docs_user') ."&UID=$uid"  ));
    }

    if ( !$attr->{INCLUDE_CUR_BILLING_PERIOD} ){
      $FORM{FROM_DATE} = "$Y-01-01";
    }

    my %fees_tax = ();
    my $Fees = Fees->new($db, $admin, \%conf);
    my $fees_type_list = $Fees->fees_type_list({
      COLS_NAME => 1,
      TAX       => '_SHOW',
      PAGE_ROWS => 10000
    });

    my $extra_fees_id = $FORM{EXTRA_INVOICE_ID};
    foreach my $line ( @$fees_type_list ) {
      if($line->{tax}) {
        $fees_tax{$line->{id}} = $line->{tax};
      }

      if($extra_fees_id && $FORM{'FEES_TYPE_'. $extra_fees_id} eq $line->{id}) {
        $FORM{'SUM_' . $extra_fees_id} = $line->{sum};
        $FORM{'ORDER_' . $extra_fees_id} = $line->{name};
      }
    }

    my $num = 0;
#print "1111111111 // $users->{DEPOSIT} //";
#    if ( $users->{DEPOSIT} && $users->{DEPOSIT} =~ /\d+/ && $users->{DEPOSIT} > 0 ){
#      print "aaaaaaaaaaaaaaaa";
#      return 1; #($attr->{REGISTRATION}) ? 1 : 0;
#    }
#print "222222222222222222";
    my $table = $html->table({
      width       => '100%',
      caption     => ($users->{UID}) ? $lang{ACTIVATE_NEXT_PERIOD} : "$lang{INVOICE} $lang{PERIOD}: $Y-$M",
      title_plain => [ '#', $lang{DATE}, $lang{LOGIN}, $lang{DESCRIBE}, $lang{SUM}, ($user) ? undef : $lang{TAX} ],
      pages       => $Docs->{TOTAL},
      ID          => 'DOCS_INVOCE_ORDERS',
    });

    my $total_sum         = 0;
    my $total_tax_sum     = 0;
    my $total_not_invoice = 0;
    my $amount_for_pay    = 0;

    # Get invoces
    my %current_invoice = ();
    $Docs->invoices_list(
      {
        UID         => $uid,
        #PAYMENT_ID  => 0,
        ORDERS_LIST => 1,
        COLS_NAME   => 1,
        PAGE_ROWS   => 1000
      }
    );

    foreach my $doc_id ( keys %{ $Docs->{ORDERS} } ){
      foreach my $invoice ( @{ $Docs->{ORDERS}->{$doc_id} } ){
        $current_invoice{ $invoice->{orders} } = $invoice->{invoice_id};
      }
    }
    #Test function
    if ( !$users->{UID} ){
      my $list = $Docs->invoice_new(
        {
          FROM_DATE => '0000-00-00', #$users->{REGISTRATION},  #$FORM{FROM_DATE} || $html->{FROM_DATE},
          TO_DATE   => $FORM{TO_DATE} || $html->{TO_DATE} || $DATE,
          PAGE_ROWS => 500,
          UID       => $users->{UID},
          TAX       => '_SHOW',
          COLS_NAME => 1
        }
      );

      foreach my $line ( @$list ){
        next if ($line->{fees_id});
        $num++;
        my $date = $line->{date} || q{};
        $date =~ s/ \d+:\d+:\d+//g;
        #=comments
        # Not invoiced fees
        if ( $line->{dsc} && !$current_invoice{$line->{dsc}} ){
          $table->addrow(
            $html->form_input( "ORDER_" . $line->{id}, $line->{dsc}, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
              . $html->form_input( "SUM_" . $line->{id}, $line->{sum}, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
              . $html->form_input( "FEES_ID_" . $line->{id}, $line->{id}, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
              . (($line->{dsc} && !$current_invoice{$line->{dsc}}) ? $html->form_input( "IDS", $line->{id},
              { TYPE => 'checkbox', STATE => 1, OUTPUT2RETURN => 1 } ) . $num : ''),
            $line->{date},
            $line->{login},
            ($line->{dsc} || q{} ) . " $date" . (($line->{dsc} && $current_invoice{$line->{dsc}}) ? ' ' . $html->color_mark( $lang{EXIST},
              $_COLORS[6] ) : ''),
            $line->{sum},
            ($line->{tax} && $fees_tax{$line->{tax}}) ? $fees_tax{$line->{tax}} : 0,
          );

          $total_not_invoice += $line->{sum};
        }
        #=cut
      }
    }
    else{
      #$users = $user;
      $FORM{NEXT_PERIOD} = 1 if (! $FORM{NEXT_PERIOD});
    }

    #($users->{DEPOSIT}<0) ? abs($users->{DEPOSIT}) : 0;
    my $date = $DATE;
    if ( $service_activate ne '0000-00-00' ){
      $date = $service_activate;
      $FORM{FROM_DATE} = $service_activate;
    }

    ($Y, $M, $D) = split( /-/, $date );
    my $start_period_unixtime;
    my $TO_D;
    if ( $service_activate ne '0000-00-00' ){
      $start_period_unixtime = (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ));
      $Docs->{CURENT_BILLING_PERIOD_START} = $service_activate;
      $Docs->{CURENT_BILLING_PERIOD_STOP}  = POSIX::strftime( "%Y-%m-%d",
        localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ) + 30 * 86400) ) );
    }
    else{
      $D = '01';
      $Docs->{CURENT_BILLING_PERIOD_START} = "$Y-$M-$D";
      $TO_D = days_in_month( { DATE => "$Y-$M-$D" } );
      $Docs->{CURENT_BILLING_PERIOD_STOP} = "$Y-$M-$TO_D";
    }

    #Next period payments
    if ( $FORM{NEXT_PERIOD} ){
      my $cross_modules_return = cross_modules_call( '_docs', {
        UID          => $attr->{UID} || $LIST_PARAMS{UID} || $uid,
        PAYMENT_TYPE => ($users->{UID}) ? undef : 0
      } );

      ($FORM{FROM_DATE}, $FORM{TO_DATE}) = _next_payment_period({
        PERIOD => $FORM{NEXT_PERIOD},
        DATE   => $date
      });
      my $period_from = $FORM{FROM_DATE};
      my $period_to   = $FORM{FROM_DATE};

      foreach my $module ( sort keys %{$cross_modules_return} ){
        if ( ref $cross_modules_return->{$module} eq 'ARRAY' ){
          next if ($#{ $cross_modules_return->{$module} } == -1);
          $table->{extra} = "colspan='6' ";
          $table->addrow( $module );
          delete $table->{extra};

          foreach my $line ( @{ $cross_modules_return->{$module} } ){
            my ($name, $describe, $sum, undef, undef, $fees_type, $activate) = split( /\|/, $line );

            next if ($sum < 0);
            $period_from = $FORM{FROM_DATE};
            $period_from =~ s/\d+$/01/;
            my $module_service_activate = $service_activate;

            if($activate) {
              $module_service_activate = $activate;
              $period_from = $module_service_activate;
            }

            for ( my $i = ($FORM{NEXT_PERIOD} == -1) ? -2 : 0; $i < int( $FORM{NEXT_PERIOD} ); $i++ ){
              my $result_sum = sprintf( "%.2f", $sum );
              if ( $users->{REDUCTION} && $module ne 'Abon' ){
                $result_sum = sprintf( "%.2f", $sum * (100 - $users->{REDUCTION}) / 100 );
              }

              ($period_from, $period_to)=_next_payment_period({
                DATE   => $period_from
              });

              my $order = "$name $describe($period_from-$period_to)";

              $num++ if (!$current_invoice{$order});
              my $tax_sum = 0;

              if($fees_type && $fees_tax{$fees_type}) {
                $tax_sum = $result_sum / 100 * $fees_tax{$fees_type};
              }

              $table->addrow(
                (
                  (!$current_invoice{$order}) ? $html->form_input( 'ORDER_' . $num, "$order",
                    { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
                    . $html->form_input( 'SUM_' . $num, $result_sum, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
                    . $html->form_input( 'IDS', "$num",
                    { TYPE => ($users->{UID}) ? 'hidden' : 'checkbox', STATE => 'checked', OUTPUT2RETURN => 1 } )
                    . $num
                    . $html->form_input( 'FEES_TYPE_' . $num, $fees_type, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
                    : ''
                ),
                $period_from,
                $users->{LOGIN},
                $order . (($current_invoice{$order}) ? ' ' . $html->color_mark( $lang{EXIST}, $_COLORS[6] ) : ''),
                $result_sum,
                sprintf("%.2f", $tax_sum)
              );

              $total_sum     += $result_sum if (!$current_invoice{$order});
              $total_tax_sum += $tax_sum;
            }
          }
        }
      }
    }

    if ( $users->{DEPOSIT} && $users->{DEPOSIT} =~ /\d+/ && $users->{DEPOSIT} != 0 && !$conf{DOCS_INVOICE_NO_DEPOSIT} ){
      $amount_for_pay = ($total_sum < $users->{DEPOSIT}) ? 0 : $total_sum - $users->{DEPOSIT};
    }
    else{
      $amount_for_pay = $total_sum;
    }

    my $deposit_sum = '';
    if ( $users->{UID}
      && ($users->{DEPOSIT} && $users->{DEPOSIT} =~ /\d+/ && $users->{DEPOSIT} < 0)
      && !$conf{DOCS_INVOICE_NO_DEPOSIT} ){
      $deposit_sum = $html->form_input( 'SUM_' . ($num + 1), abs( $users->{DEPOSIT} ),{ TYPE => 'hidden', OUTPUT2RETURN => 1 } )
        . $html->form_input( 'ORDER_' . ($num + 1), "$lang{DEBT}", { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
        . $html->form_input( 'IDS', ($num + 1), { TYPE => 'hidden', OUTPUT2RETURN => 1 } );
    }

    #Add extra fields in admin iface
    if(! $user) {
      $num++;
      my $extra_result_sum = $FORM{'SUM_' . $num} || 0;
      my $extra_tax_sum    = 0;
      my $order            = $FORM{'ORDER_' . $num} || q{};

      if ($FORM{'FEES_TYPE_' . $num} && $fees_tax{$FORM{'FEES_TYPE_' . $num}}) {
        $extra_tax_sum = $extra_result_sum / 100 * $fees_tax{$FORM{'FEES_TYPE_' . $num}};
        $total_tax_sum += $extra_tax_sum;
      }

      $table->addrow(
        $html->form_input('SUM_' . $num, $extra_result_sum, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('EXTRA_INVOICE_ID', $num, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('ORDER_' . $num, "$order", { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('IDS', "$num", { TYPE => ($users->{UID}) ? 'hidden' : 'checkbox', STATE => 'checked', OUTPUT2RETURN => 1 })
          #        . $html->form_input( 'FEES_TYPE_' . $num, $FORM{'FEES_TYPE_'. $num}, { TYPE => 'text', OUTPUT2RETURN => 1 } )
          . $num
        ,
        $DATE,
        $users->{LOGIN},
        docs_invoice_order_sel({ NAME => 'FEES_TYPE_' . $num }),
        sprintf("%.2f", $extra_result_sum),
        ($user) ? undef : sprintf("%.2f", $extra_tax_sum)
      );
      $total_sum += $total_not_invoice;
    }

    $table->{SKIP_FORMER} = 1;

    $table->addtd(
      $table->td("$lang{COUNT}: $num $lang{TOTAL} $lang{SUM}: ", { colspan => 4, class => 'bg-info' }),
      $table->td( sprintf( "%.2f", $total_sum ), { class => 'bg-info' } ),
      $table->td( ($user) ? undef : sprintf( "%.2f", $total_tax_sum), { class => 'bg-info' } )
    );

    $table->{extra} = " colspan='4' ";
    $table->addrow( $html->b( "$lang{DEPOSIT}:" ),
      $html->b( sprintf( "%.2f", ($users->{DEPOSIT} && $users->{DEPOSIT} =~ /\d+/) ? $users->{DEPOSIT} : 0 ) ) . $deposit_sum || 0 );
    $table->addrow( $html->b( "$lang{AMOUNT_FOR_PAY}:" ), $html->b( sprintf( "%.2f", $amount_for_pay ) ) );
    $FORM{AMOUNT_FOR_PAY} = sprintf( "%.2f", $amount_for_pay );

#    $Docs->{FROM_DATE} = $html->date_fld2( 'FROM_DATE',
#      { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS } );
#    $Docs->{TO_DATE} = $html->date_fld2( 'TO_DATE',
#      { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS } );

    $Docs->{PERIOD_DATE} = $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'invoice_add',
      VALUE     => $FORM{'FROM_DATE_TO_DATE'},
    });

    $FORM{NEXT_PERIOD} = 0 if (!$FORM{NEXT_PERIOD} || $FORM{NEXT_PERIOD} < 0);
    if ( $attr->{REGISTRATION} ){
      return 1 if (!$attr->{ACTION});
      $Docs->{BACK} = $html->form_input( 'back', $lang{BACK}, { TYPE => 'submit' } );
      $Docs->{NEXT} = $html->form_input( $attr->{ACTION}, $attr->{LNG_ACTION}, { TYPE => 'submit' } );
    }

    if ( $user && $user->{UID} ){
      return 0 if (!$num);

      my $action = $html->form_input( 'make', "$lang{CREATE} $lang{INVOICE}", { TYPE => 'submit', OUTPUT2RETURN => 1 } );
      #$table->{rowcolor} = 'bg-warning';
      $table->{extra} = ' colspan=\'6\'';
      $table->addrow( $action );

      $html->form_main(
        {
          CONTENT => $table->show( { OUTPUT2RETURN => 1 } ),
          HIDDEN  => {
            index    => $index,
            UID      => $uid,
            DATE     => $DATE,
            create   => 1,
            CUSTOMER => $Docs->{CUSTOMER},
            step     => $FORM{step},
            #ALL_SERVICES   => 1
          },
          NAME    => 'DOCS_SERVICES_INVOICE',
        }
      );
    }
    else{
      $Docs->{ORDERS} = $table->show( { OUTPUT2RETURN => 1 } );
      #$FORM{NEXT_PERIOD}=$Docs->{INVOICING_PERIOD} if (! $FORM{NEXT_PERIOD});
      if (!$FORM{pdf}) {
        $html->tpl_show(_include('docs_receipt_add', 'Docs'),
          { %FORM, %{$attr}, %{$Docs}, %{$users} }, { ID => 'docs_receipt_add' });
      }
    }
    delete $table->{SKIP_FORMER};
  }
  #
  else {
    $Docs->{ORDERS} = $html->tpl_show(
      _include( 'docs_invoice_orders', 'Docs' ),
      {
        %{$Docs},
        %{$users},
        DATE => $DATE,
        TIME => $TIME,
        %FORM
      },
      { OUTPUT2RETURN => 1 }
    );

    if ( $user && $user->{UID} ){
      $html->tpl_show( _include( 'docs_invoice_client_add', 'Docs' ), { %{$Docs}, %{$users}, %FORM } );
    }
    else{
      $html->tpl_show( _include( 'docs_invoice_add', 'Docs' ), {
        %{$attr},
        %{$Docs},
        %{$users},
        %FORM }, { ID => 'docs_invoice_add' } );
    }
  }

  return 1;
}

#**********************************************************
=head2 _next_payment_period($attr)

  Arguments:
     $attr
       DATE
       PERIOD

  Resturns:
    $from_date, $to_date

=cut
#**********************************************************
sub _next_payment_period {
  my ($attr) = @_;

  my $from_date = q{};
  my $to_date   = q{};

  my $next_period = $attr->{PERIOD} || 1;
  my $service_activate = $attr->{SERVICE_ACTIVATE} || q{};
  my $date = ($attr->{DATE} && $attr->{DATE} ne '0000-00-00') ? $attr->{DATE} : $DATE;

  my($Y, $M, $D)=split(/-/, $date);

  my $TO_D = 1;

  if ($service_activate && $service_activate ne '0000-00-00' && !$conf{FIXED_FEES_DAY} ){
    my $start_period_unixtime = (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0 ));
    ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
      0 ) + ((($start_period_unixtime > time) ? 0 : 1) + 30 * (($start_period_unixtime > time) ? 0 : 1)) * 86400) ) ) );
    $FORM{FROM_DATE} = "$Y-$M-$D";

    ($Y, $M, $D) = split( /-/, POSIX::strftime( "%Y-%m-%d", localtime( (POSIX::mktime( 0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0,
      0 ) + ((($start_period_unixtime > time) ? 1 : (1 * $next_period - 1)) + 30 * (($start_period_unixtime > time) ? 1 : $next_period)) * 86400) ) ) );
    $FORM{TO_DATE} = "$Y-$M-$D";
  }
  else{
    $M += 1;
    if ( $M > 12 ){
      $M = $M - 12;
      $Y++;
    }

    $from_date = sprintf("%d-%02d-%02d", $Y, $M, 1);
    # $M += $next_period - 0; # - 1
    # if ( $M > 12 ){
    #   $M = $M - 12;
    #   $Y++;
    # }

    if ( $service_activate eq '0000-00-00' ){
      $TO_D = days_in_month({ DATE => "$Y-$M" });
    }
    else{
      if ( $conf{FIXED_FEES_DAY} ){
        $TO_D = ($D > 1) ? ($D - 1) : days_in_month({ DATE => "$Y-$M" });
      }
      else{
        $TO_D = days_in_month({ DATE => "$Y-$M" });
      }
    }

    $to_date = sprintf("%d-%02d-%02d", $Y, $M, $TO_D);
  }

  return $from_date, $to_date;
}

#**********************************************************
=head2 docs_invoice_order_sel($attr)

  Arguments:
     NAME

  Resturns:
    $selct_obj

=cut
#**********************************************************
sub docs_invoice_order_sel {
  my($attr)=@_;

  my $name = ($attr->{NAME}) ? $attr->{NAME} : 'FEES_TYPE';

  my $select_element = $html->form_select(
    $name,
    {
      SELECTED     => ($FORM{$name}) ? $FORM{$name} : '',
      SEL_HASH     => get_fees_types(),
      #ARRAY_NUM_ID => 1,
      SORT_KEY_NUM => 1,
      NO_ID        => 1,
      SEL_OPTIONS => { 0 => '' },
    }
  );

  return $select_element;
}


#**********************************************************
=head2 docs_invoice_print($invoice_id, $attr)

  Arguments:
   $invoice_id  - Invoice ID
   $attr        - Extra args
     UID
     DOC_INFO   - Docs object

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub docs_invoice_print {
  my ($invoice_id, $attr) = @_;

  if($attr->{DOC_INFO}) {
    $Docs = $attr->{DOC_INFO};
  }
  else {
    $Docs->invoice_info( $invoice_id, {
      UID          => $attr->{UID},
      GROUP_ORDERS => $conf{DOCS_INVOICE_GROUP_ORDERS}
    } );
  }

  if ( !$FORM{QUICK} ){
    _error_show( $Docs, {  MESSAGE => "$lang{INVOICE}: $invoice_id"} );
  }

  if($Docs->{errno}) {
    if($FORM{qindex}) {
      print "Content-Type: text/html\n\n";
      print "Wrong invoice number: $invoice_id";
    }
    return 0;
  }

  my %Doc = %{ $Docs };
  my $value_list=$Conf->config_list({
    CUSTOM    => 1,
    COLS_NAME => 1
  });

  foreach my $line (@$value_list){
    $Doc{"$line->{param}"}=$line->{value};
  }

  if ( $conf{DOCS_VAT_INCLUDE} ){
    $Doc{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
      ($conf{DOCS_VAT_INCLUDE} && $conf{DOCS_VAT_INCLUDE} > 0) ? $Doc{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : 0 );

    $Doc{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $Doc{TOTAL_SUM} - $Doc{ORDER_TOTAL_SUM_VAT} );
    $Doc{VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );
  }

  $Doc{NUMBER}   = $Docs->{INVOICE_NUM};
  $Doc{A_FIO}    = $Docs->{A_FIO};
  $Doc{CUSTOMER} = $Docs->{COMPANY_NAME} || $Doc{FIO} || '-' if (!$Doc{CUSTOMER});
  $Doc{DEPOSIT}  = sprintf( "%.2f", $Doc{DEPOSIT} || 0);
  $Doc{DEBT}     = ($Doc{DEPOSIT} < 0) ? $Doc{DEPOSIT} : 0.00;
  $Doc{AVANCE}   = ($Doc{DEPOSIT} > 0) ? $Doc{DEPOSIT} : 0.00;
  my ($y, $m)    = split( /\-/, $Doc{DATE} );
  my $days_in_month = days_in_month( { DATE => $Doc{DATE} } );
  $Doc{INVOICE_PERIOD} = "$y-$m-01 $y-$m-$days_in_month";
  $Doc{MONTH_LAST_DAY} = "$y-$m-".  $days_in_month;

  if ( $FORM{CHECK_PEYMENT_ID} && $Doc{PAYMENT_ID} ){
    return 0;
  }

  if ( $Docs->{TOTAL} > 0 ){
    $Doc{FROM_DATE_LIT} = '';

    (undef, $Doc{TIME}) = split( / /, $Doc{CREATED}, 2 );
    $Doc{AMOUNT_FOR_PAY} = ($Doc{DEPOSIT} < 0) ? abs( $Doc{DEPOSIT} ) : 0 - $Doc{DEPOSIT};

    my $list = $Doc{ORDERS};
    my $i = 0;
    $Doc{ORDER}         = '';
    $Doc{TOTAL_TAX_SUM} = 0;

    foreach my $line ( @$list ){
      $i++;

      if (!$FORM{pdf}) {
        $Doc{ORDER} .= $html->tpl_show(
          _include('docs_invoice_order_row', 'Docs'),
          {
            %{$Docs},
            NUMBER => $i,
            NAME   => $line->[1],
            COUNT  => $line->[2] || 1,
            UNIT   => $units[$line->[3]] || 1,
            PRICE  => $line->[4],
            SUM    => sprintf("%.2f", ($line->[2] || 1) * $line->[4])
          },
          { OUTPUT2RETURN => 1 }
        );
      }

      my $count = $line->[2] || 1;
      my $sum = sprintf( "%.2f", $count * $line->[4] );

      $Doc{ 'LOGIN_' . $i }         = $line->[6];
      $Doc{ 'ORDER_NUM_' . $i }     = $i;
      $Doc{ 'ORDER_NAME_' . $i }    = $line->[1];
      $Doc{ 'ORDER_COUNT_' . $i }   = $count;
      $Doc{ 'ORDER_PRICE_' . $i }   = $line->[4];
      $Doc{ 'ORDER_TAX_SUM_' . $i } = $line->[5];

      $Doc{TOTAL_TAX_SUM}          += $line->[5];

      $Doc{ 'ORDER_SUM_' . $i }     = $sum;
      $Doc{ 'ORDER_VAT_' . $i }     = ($conf{DOCS_VAT_INCLUDE}) ? sprintf( "%.2f",
          $line->[4] / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) ) : 0;
      $Doc{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($Doc{ 'ORDER_VAT_' . $i }) ? $line->[4] - $Doc{ 'ORDER_VAT_' . $i } : $line->[3] );
      $Doc{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );

      # not charged service
      if ( $Doc{DEPOSIT} == 0 || $line->[5] == 0 ){
        $Doc{AMOUNT_FOR_PAY} += $Doc{ 'ORDER_COUNT_' . $i } * $Doc{ 'ORDER_PRICE_' . $i }
      }

      #alternative currancy sum
      if ( $Doc{EXCHANGE_RATE} > 0 ){
        $Doc{ 'ORDER_ALT_SUM_' . $i }   = sprintf( "%.2f", $Doc{ 'ORDER_SUM_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_PRICE_' . $i } = sprintf( "%.2f", $Doc{ 'ORDER_PRICE_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_VAT_' . $i }   = sprintf( "%.2f", $Doc{ 'ORDER_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Doc{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Doc{ 'ORDER_SUM_WITHOUT_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
      }
    }

    $Doc{TOTAL_SUM}      = sprintf( "%.2f", $Doc{TOTAL_SUM} );
    $Doc{TOTAL_TAX_SUM}  = sprintf( "%.2f", $Doc{TOTAL_TAX_SUM});
    $Doc{AMOUNT_FOR_PAY} = sprintf( "%.2f", $Doc{AMOUNT_FOR_PAY} );
    $Doc{TOTAL_ORDERS}   = $#{ $list } + 1;

    #Get payments
    my $i2p_list = $Docs->invoices2payments_list({ INVOICE_ID => $invoice_id,
      COLS_NAME  => 1
    });
    my $payments_total_sum = 0;
    $i = 1;
    foreach my $i2p ( @{ $i2p_list } ){
      my ($payment_day, undef) = split( / /, $i2p->{date} );
      $Doc{'PAYMENT_DATE_' . $i}     = $payment_day;
      $Doc{'PAYMENT_COMMENTS_' . $i} = $i2p->{dsc};
      $Doc{'PAYMENT_SUM_' . $i}      = $i2p->{invoiced_sum};
      $Doc{'PAYMENT_ID_' . $i}       = $i2p->{payment_id};
      $Doc{'PAYMENT_ALT_SUM_' . $i}  = sprintf( "%.2f", $Doc{EXCHANGE_RATE} * $i2p->{payment_sum} );
      $payments_total_sum += $payments_total_sum;
      $i++;
    }

    $Doc{PAYMENTS_TOTAL_SUM} = $payments_total_sum;
    $Doc{TOTAL_REST_SUM} = sprintf( "%.2f", $Doc{TOTAL_SUM} - $Doc{PAYMENTS_TOTAL_SUM} );

    #Get unpayments
    my $unpayment_list = $Docs->invoices_list( {
      UID       => $attr->{UID},
      UNPAIMENT => 1,
      PAGE_ROWs => 1000,
      COLS_NAME => 1
    } );

    $i = 1;
    my $unpayment_total_sum = 0;
    foreach my $unpayment ( @{$unpayment_list} ){
      $Doc{'UNPAYMENT_INVOICE_DATE_' . $i} = $unpayment->{date};
      $Doc{'UNPAYMENT_INVOICE_COMMENTS_' . $i} = $unpayment->{dsc};
      $Doc{'UNPAYMENT_INVOICE_SUM_' . $i} = sprintf( "%.2f",
        $unpayment->{total_sum} - ($unpayment->{payment_sum} || 0) );
      $Doc{'UNPAYMENT_INVOICE_NUM_' . $i} = $unpayment->{invoice_num};
      $Doc{'UNPAYMENT_INVOICE_ALT_SUM_' . $i} = sprintf( "%.2f",
        $Doc{EXCHANGE_RATE} * $Doc{'UNPAYMENT_INVOICE_SUM_' . $i} );
      $unpayment_total_sum += $Doc{'UNPAYMENT_INVOICE_SUM_' . $i};
      $i++;
    }

    $Doc{LAST_PAYMENT_SUM} = '0.00';
    $Doc{LAST_PAYMENT_DATE} = '';
    $list = $Payments->list( {
      UID       => $attr->{UID},
      SUM       => '_SHOW',
      DATETIME  => '_SHOW',
      DESC      => 'DESC',
      PAGE_ROWS => 1,
      COLS_NAME => 1
    } );

    if ( $Payments->{TOTAL} > 0 ){
      $Doc{LAST_PAYMENT_SUM} = $list->[0]->{sum};
      $Doc{LAST_PAYMENT_DATE} = $list->[0]->{datetime};
    }

    $Doc{UNPAYMENT_TOTAL_SUM} = sprintf( "%.2f", $unpayment_total_sum );

    if ( $Doc{EXCHANGE_RATE} > 0 ){
      $Doc{TOTAL_ALT_SUM}      = sprintf( "%.2f", $Doc{TOTAL_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{AMOUNT_FOR_PAY_ALT} = sprintf( "%.2f", $Doc{AMOUNT_FOR_PAY} * $Doc{EXCHANGE_RATE} );
      $Doc{DEPOSIT_ALT}        = sprintf( "%.2f", $Doc{DEPOSIT} * $Doc{EXCHANGE_RATE} );
      $Doc{CHARGED_ALT_SUM}    = sprintf( "%.2f", $Doc{CHARGED_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{UNPAYMENT_TOTAL_ALT_SUM} = sprintf( "%.2f", $Doc{UNPAYMENT_TOTAL_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{TOTAL_REST_ALT_SUM} = sprintf( "%.2f", $Doc{TOTAL_REST_SUM} * $Doc{EXCHANGE_RATE} );
    }

    $attr->{SEND_EMAIL} = 0 if (!defined( $attr->{SEND_EMAIL} ));

    if ( $attr->{GET_EMAIL_INFO} && $attr->{SEND_EMAIL} ){
      delete $FORM{pdf};
      $attr->{EMAIL_MSG_TEXT} = $html->tpl_show( _include( 'docs_invoice_email', 'Docs' ), { %{$users}, %FORM,
          %{$attr}, %{$Docs}, %Doc }, { OUTPUT2RETURN => 1 } );
      $attr->{EMAIL_ATTACH_FILENAME} = 'invoice_' . $Doc{INVOICE_NUM} if (!$attr->{EMAIL_ATTACH_FILENAME});
      $attr->{EMAIL_MSG_SUBJECT} = "ABillS - $lang{INVOICE}: $Doc{INVOICE_NUM}" if (!$attr->{EMAIL_MSG_SUBJECT});
    }

    if ( $conf{DOCS_EXTRA_DEPOSIT} && $Doc{DEPOSIT} != 0 ){
      if ( $Doc{EXCHANGE_RATE} ){
        $Doc{DEPOSIT_ALT} = sprintf( "%.2f", ($Doc{DEPOSIT} + $Doc{CHARGED_SUM}) * $Doc{EXCHANGE_RATE} );
      }
    }

    $FORM{pdf} = $conf{DOCS_PDF_PRINT};

    #Modules info
    #    my $cross_modules_return = cross_modules_call('_docs');
    #
    #    foreach my $module (sort keys %$cross_modules_return) {
    #      if (ref $cross_modules_return->{$module} eq 'ARRAY') {
    #        next if ($#{ $cross_modules_return->{$module} } == -1);
    #        foreach my $line (@{ $cross_modules_return->{$module} }) {
    #          my ($name, $describe, $sum, $tp_id, $tp_name) = split(/\|/, $line);
    #          $Doc{"DOCS_ABON_".uc($module) . (($tp_id) ? "_$tp_id" : '')} = $sum;
    #          $Doc{"DOCS_TPNAME_".uc($module) . (($tp_id) ? "_$tp_id" : '')} = $tp_name;
    #        }
    #      }
    #    }
    if ( $Doc{COMPANY_ID} ){
      my $Customer = Customers->new( $db, $admin, \%conf );
      my $Company  = $Customer->company();
      $Company->info( $Doc{COMPANY_ID} );
      delete $Company->{DEPOSIT};
      my $invoice_blank = ($FORM{alt_tpl}) ? 'invoice_company_alt' : ($FORM{termo_printer_tpl}) ? 'invoice_company_termo_printer' : 'invoice_company';

      my $sufix = ($Doc{PAYMENT_SUM} && $Doc{PAYMENT_SUM} == $Doc{TOTAL_SUM} && _include(
          'docs_' . $invoice_blank . '_paid', 'Docs', { CHECK_ONLY => 1 } )) ? '_paid' : '';

      return docs_print( "$invoice_blank$sufix", { %Doc,
        %{$Company},
        %{$attr},
        SUFIX   => ($Doc{VAT} > 0) ? 'vat' : '',
        ALT_TPL => $invoice_blank,
#        OUTPUT2RETURN => 1
      } );
    }
    else{
      my $invoice_blank = ($FORM{alt_tpl}) ? 'invoice_alt' : ($FORM{termo_printer_tpl}) ? 'invoice_termo_printer' : 'invoice';
      my $sufix = ($Doc{PAYMENT_SUM} && $Doc{TOTAL_SUM} && $Doc{PAYMENT_SUM} == $Doc{TOTAL_SUM} && _include(
          'docs_' . $invoice_blank . '_paid', 'Docs', { CHECK_ONLY => 1 } )) ? '_paid' : '';

      return docs_print( "$invoice_blank$sufix", {
        %Doc,
        %{$attr},
        ALT_TPL => $invoice_blank,
        DOCS    => $Docs,
      } );
    }
  }
  else{
    if ( !$FORM{QUICK} ){
      print "Content-Type: text/html\n\n";
      _error_show( $Docs );
    }
  }

  return 1;
}

#**********************************************************
=head2 docs_summary() - Make multiuser documents

=cut
#**********************************************************
sub docs_summary{
  my $list = $users->list(
    {
      FIO       => '_SHOW',
      CREDIT    => '_SHOW',
      DEPOSIT   => '<0',
      DISABLE   => 0,
      PAGE_ROWS => 1000000,
      COLS_NAME => 1
    }
  );
  my @MULTI_ARR = ();

  foreach my $line ( @{$list} ){
    push @MULTI_ARR,
      {
        FIO     => $line->{fio},
        DEPOSIT => $line->{deposit},
        CREDIT  => $line->{credit},
        SUM     => $line->{deposit},
        SUM_VAT => ($conf{DOCS_VAT_INCLUDE}) ? sprintf( "%.2f",
            ($line->{deposit} || 0) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) ) : 0.00
      };
  }

  $html->tpl_show( _include( "docs_multi_invoice", 'Docs', { pdf => $FORM{pdf} } ), { MULTI_PRINT => \@MULTI_ARR } );

  return 1;
}


1;