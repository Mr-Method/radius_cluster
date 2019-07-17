=head1 NAME

  User manage

=cut

use warnings FATAL => 'all';
use strict;
use Abills::Base qw(in_array);
use Abills::Defs;
use Customers;

our ($db,
  $html,
  %lang,
  $admin,
  %permissions,
);

#**********************************************************
=head2 add_company() - Add company

=cut
#**********************************************************
sub add_company {

  my $Company;
  $Company->{ACTION}         = 'add';
  $Company->{LNG_ACTION}     = $lang{ADD};
  $Company->{BILL_ID}        = $html->form_input( 'CREATE_BILL', 1, { TYPE => 'checkbox', STATE => 1 } ) . ' ' . $lang{CREATE};
  $Company->{ADDRESS_SELECT} = _form_company_address();

  $Company->{INFO_FIELDS} = form_info_field_tpl({ COMPANY => 1 });

  if (in_array('Docs', \@MODULES)) {
    $Company->{PRINT_CONTRACT} = $html->button( $lang{PRINT},
      "qindex=15&UID=". ($Company->{UID} || '') ."&PRINT_CONTRACT=". ($Company->{UID} || '')  . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
      { ex_params => ' target=new', class => 'print' } );

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});
      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = '|'.($Company->{CONTRACT_SUFIX} || '');
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $Company->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), { ID => "",
          NAME                                                                => $lang{TYPE},
          VALUE                                                                => $html->form_select(
            'CONTRACT_TYPE',
            {
              SELECTED => $FORM{CONTRACT_SUFIX},
              SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
              NO_ID    => 1
            })
        }, { OUTPUT2RETURN => 1 });
    }
  }

  $html->tpl_show(templates('form_company'), $Company);

  return 1;
}


#**********************************************************
=head2 form_companies()

=cut
#**********************************************************
sub form_companies {

  my $Customer = Customers->new($db, $admin, \%conf);
  my $Company  = $Customer->company();

  if ($FORM{add_form}) {
    add_company();
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }

    if($FORM{LOCATION_ID}){
      require Control::Address_mng;
      $FORM{ADDRESS} = full_address_name($FORM{LOCATION_ID}). ($FORM{ADDRESS_FLAT} ? ', '. $FORM{ADDRESS_FLAT} : '');
    }

    $Company->add({%FORM});

    if (!$Company->{errno}) {
      $html->message( 'info', $lang{ADDED},
        "$lang{ADDED} " . $html->button( "$FORM{NAME}", 'index=13&COMPANY_ID=' . $Company->{COMPANY_ID}, { BUTTON => 1 } ) );
    }
  }
  elsif ($FORM{import}) {
    if (!$permissions{0}{1}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }

    #Create service cards from file
    my $imported      = 0;
    my $impoted_named = '';
    if (defined($FORM{FILE_DATA})) {
      my @rows = split(/[\r]{0,1}\n/, $FORM{"FILE_DATA"}{'Contents'});

      foreach my $line (@rows) {
        my @params = split(/\t/, $line);
        my %USER_HASH = (
          CREATE_BILL  => 1,
          COMPANY_NAME => $params[0]
        );

        next if ($USER_HASH{COMPANY_NAME} eq '');

        for (my $i = 0 ; $i <= $#params ; $i++) {
          my ($k, $v) = split(/=/, $params[$i], 2);
          $v =~ s/\"//g;
          $USER_HASH{$k} = $v;
        }
        $impoted_named .= "$USER_HASH{COMPANY_NAME}\n";
        $imported++;
        $USER_HASH{COMPANY_NAME} =~ s/'/\\'/g;

        $Company->add({%USER_HASH});
        if ($Company->{errno}) {
          _error_show($Company, { MESSAGE =>  "Line:$impoted_named\n $lang{COMPANY}: '$USER_HASH{COMPANY_NAME}'" });
          return 0;
        }
      }

      my $message = "$lang{FILE} $lang{NAME}:  $FORM{FILE_DATA}{filename}\n" . "$lang{TOTAL}:  $imported\n" . "$lang{SIZE}: $FORM{FILE_DATA}{Size}\n" . "$impoted_named\n";

      $html->message( 'info', $lang{INFO}, "$message" );
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }

    if($FORM{LOCATION_ID}){
      #require Address;
      #Address->import();
      require Control::Address_mng;
      $FORM{ADDRESS} = full_address_name($FORM{LOCATION_ID}). ($FORM{ADDRESS_FLAT} ? ', '. $FORM{ADDRESS_FLAT} : '');
    }

    if(! $FORM{ID} && $FORM{COMPANY_ID}) {
      $FORM{ID} = $FORM{COMPANY_ID};
    }

    $Company->change({%FORM});

    if (!$Company->{errno}) {
      $html->message( 'info', $lang{INFO}, $lang{CHANGED} . " # $Company->{NAME}" );
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS} && $permissions{0}{5} && ! $FORM{subf}) {
    $Company->del($FORM{del});
    $html->message( 'info', $lang{INFO}, "$lang{DELETED} # $FORM{del}" );
  }

  if ($FORM{COMPANY_ID}) {
    $Company->info($FORM{COMPANY_ID} || $FORM{ID});
    if(_error_show($Company)) {
      return 1;
    }

    $Company->{COMPANY_NAME}   = $Company->{NAME};

    if ($FORM{PRINT_CONTRACT}) {
      load_module('Docs', $html);
      docs_contract({
          COMPANY_CONTRACT => 1,
            %$Company,
            SEND_EMAIL       => $FORM{SEND_EMAIL} });
      return 0;
    }

    $LIST_PARAMS{COMPANY_ID} = $Company->{ID};
    $FORM{COMPANY_ID}        = $Company->{ID};
    $LIST_PARAMS{BILL_ID}    = $Company->{BILL_ID};
    $pages_qs .= "&COMPANY_ID=$LIST_PARAMS{COMPANY_ID}" if ($LIST_PARAMS{COMPANY_ID});
    $pages_qs .= "&subf=$FORM{subf}" if ($FORM{subf});

    if (in_array('Docs', \@MODULES)) {
      $Company->{PRINT_CONTRACT} = $html->button( "$lang{PRINT}",
        "qindex=$index$pages_qs&PRINT_CONTRACT=$Company->{ID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '')
        , { ex_params => ' target=new', class => 'print' } );
    }

    my @menu_functions = (
      $lang{INFO}     ."::COMPANY_ID=$Company->{ID}",
      $lang{USERS}    .":11:COMPANY_ID=$Company->{ID}",
      $lang{PAYMENTS} .":2:COMPANY_ID=$Company->{ID}",
      $lang{FEES}     .":3:COMPANY_ID=$Company->{ID}",
      $lang{ADD_USER} .":24:COMPANY_ID=$Company->{ID}",
      $lang{BILL}     .":19:COMPANY_ID=$Company->{ID}"
    );

    if (in_array('Docs', \@MODULES)) {
      load_module('Docs', $html);
      push @menu_functions, "$lang{DOCS}:" . get_function_index( 'docs_acts' ) . ":COMPANY_ID=$Company->{ID}";
    }

    my $company_sel = $html->form_main(
      {
        CONTENT => $html->form_select(
          'COMPANY_ID',
          {
            SELECTED  => $FORM{COMPANY_ID},
            SEL_LIST  => $Company->list({ COLS_NAME => 1, PAGE_ROWS => 100000 }),
            SEL_KEY   => 'id',
            SEL_VALUE => 'name',
          }
        ),
        HIDDEN => {
          index => $index,
        },
        SUBMIT => { show => $lang{SHOW} },
        class   => 'navbar-form navbar-right',
      }
    );

    func_menu(
      {
        $lang{NAME} => $company_sel
      },
      \@menu_functions,
      { f_args     => { COMPANY => $Company },
        MAIN_INDEX => get_function_index('form_companies'),
        SILENT     => $FORM{print}
      }
    );

    #Sub functions
    if (!$FORM{subf}) {
      if ($permissions{0}{4}) {
        $Company->{ACTION}     = 'change';
        $Company->{LNG_ACTION} = $lang{CHANGE};
      }
      $Company->{DISABLE} = ($Company->{DISABLE} > 0) ? 'checked' : '';

      if ($conf{EXT_BILL_ACCOUNT} && $Company->{EXT_BILL_ID}) {
        $Company->{EXDATA} = $html->tpl_show(templates('form_ext_bill'), $Company, { OUTPUT2RETURN => 1 });
      }

      $Company->{INFO_FIELDS} = form_info_field_tpl({ COMPANY => 1, VALUES  => $Company });
      $Company->{ADDRESS_SELECT}= _form_company_address($Company);

      if (in_array('Docs', \@MODULES)) {
        if ($conf{DOCS_CONTRACT_TYPES}) {
          $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
          my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

          my %CONTRACTS_LIST_HASH = ();
          $FORM{CONTRACT_SUFIX} = "|$Company->{CONTRACT_SUFIX}";
          foreach my $line (@contract_types_list) {
            my ($prefix, $sufix, $name) = split(/:/, $line);
            $prefix =~ s/ //g;
            $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
          }

          $Company->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), {
              ID    => 'CONTRACT_TYPE',
              NAME  => $lang{TYPE},
              VALUE => $html->form_select('CONTRACT_TYPE',
                {
                  SELECTED => $FORM{CONTRACT_SUFIX},
                  SEL_HASH => { '' => '--', %CONTRACTS_LIST_HASH },
                  NO_ID    => 1
                })
            }, { OUTPUT2RETURN => 1 });
        }
      }

      $html->tpl_show(templates('form_company'), $Company);
    }
  }
  else {
    if ($FORM{letter}) {
      $LIST_PARAMS{COMPANY_NAME} = "$FORM{letter}*";
      $pages_qs .= "&letter=$FORM{letter}";
    }

    result_former({
      INPUT_DATA      => $Company,
      FUNCTION        => 'list',
      DEFAULT_FIELDS  => 'NAME,DEPOSIT,CREDIT,USERS_COUNT,DISABLE',
      BASE_FIELDS     => 1,
      FUNCTION_FIELDS => 'company_id,del',
      EXT_TITLES      => {
        'name'        => $lang{NAME},
        'users_count' => $lang{USERS},
        'status'      => $lang{STATUS},
      },
      FILTER_COLS   => {
        users_count      => ($FORM{json}) ? '' : "_company_user_link::FUNCTION=form_users,ID",
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{COMPANIES},
        qs      => $pages_qs,
        ID      => 'COMPANY_ID',
        EXPORT  => 1,
        MENU    => "$lang{ADD}:index=$index&add_form=1".':add'.
          ";$lang{SEARCH}:index=".get_function_index( 'form_search' )."&type=13:search"
      },
      MAKE_ROWS       => 1,
      TOTAL           => 1
    });

    if (!$FORM{search}) {
      print $html->form_main(
        {
          CONTENT => "$lang{FILE}: ".$html->form_input( 'FILE_DATA', '', { TYPE => 'file' } ),
          ENCTYPE => 'multipart/form-data',
          HIDDEN  => { index => $index, },
          SUBMIT  => { import => "$lang{IMPORT}" },
          TARGET  => 'new'
        }
      );
    }
  }

  _error_show($Company);

  return 1;
}


#**********************************************************
=head2 _company_user_link()

=cut
#**********************************************************
sub _company_user_link{
  my ($params, $attr) = @_;

  return $html->button($params, "index=11&COMPANY_ID=$attr->{VALUES}->{ID}" );

  return $params;
}

#**********************************************************
=head2 form_companie_admins($attr)

=cut
#**********************************************************
sub form_companie_admins {
  my ($attr) = @_;

  my $Customer = Customers->new($db, $admin, \%conf);
  my $Company = $Customer->company();

  if ($FORM{change}) {
    #ADD_ADMIN:
    $Company->admins_change({%FORM});
    if (!$Company->{errno}) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
    if ($attr->{REGISTRATION}) {
      return 0;
    }
  }

  _error_show($Company);

  my $table = $html->table(
    {
      width      => '100%',
      caption    => $lang{ADMINS},
      title      => [ $lang{ALLOW}, $lang{LOGIN}, $lang{FIO}, 'E-mail' ],
      qs         => $pages_qs,
      ID         => 'COMPANY_ADMINS'
    }
  );

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 2;
  }

  my $list = $Company->admins_list(
    {
      COMPANY_ID => $FORM{COMPANY_ID},
      PAGE_ROWS  => 10000
    }
  );

  if ($attr->{REGISTRATION}) {
    if ($FORM{add} && $Company->{TOTAL} == 1 && !$list->[0]->[0]) {
      $FORM{IDS} = $FORM{UID};
      #      goto ADD_ADMIN;
    }
    return 0;
  }

  foreach my $line (@$list) {
    $table->addrow(
      $html->form_input(
        'IDS',
        $line->[4],
        {
          TYPE          => 'checkbox',
          OUTPUT2RETURN => 1,
          STATE         => ($line->[0]) ? 1 : undef
        }
      ),
      user_ext_menu($line->[4], $line->[1]),
      $line->[2],
      $line->[3]
    );
  }

  print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          index      => $index,
          COMPANY_ID => $FORM{COMPANY_ID}
        },
        SUBMIT  => { change => "$lang{CHANGE}" }
      }
    );

  return 1;
}

#**********************************************************
=head2 _form_company_address($attr) get address form for companys

=cut
#**********************************************************
sub _form_company_address {
  my ($attr) = @_;

  require Address;

  my %info = ();
  Address->import();
  my $Address = Address->new($db, $admin, \%conf);

  if($attr->{LOCATION_ID}){
    $Address->address_info($attr->{LOCATION_ID});
  }
  elsif($attr->{ADDRESS}){
    my $address_input    = $html->form_input('ADDRESS', $attr->{ADDRESS});
    $info{ADDRESS_FORM} .= $html->element('label', $lang{ADDRESS}, { for => 'ADDRESS', class => 'control-label col-md-3'});
    $info{ADDRESS_FORM} .= $html->element('div',  $address_input, { class => 'col-md-9'});
    $info{ADDRESS_FORM}  = $html->element('div', $info{ADDRESS_FORM}, {class => 'form-group'});
  }

  $info{ADDRESS_FORM} .= $html->tpl_show(templates('form_address_sel'),
    {%$Address, %$attr},
    {
      OUTPUT2RETURN => 1,
      ID            => 'form_address_sel'
    }
  );

  return $info{ADDRESS_FORM};
}

1;