=head1 NAME

  Result former

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array);

our(
  $html,
  %lang,
  $admin,
  %permissions,
  %DATA_HASH,
  %FORM,
  %LIST_PARAMS,
  $index,
  @MODULES,
  %conf,
  %CHARTS
);

#**********************************************************
=head2 result_row_former($attr); - forming result from array_hash

  Arguments:
    $attr
      table - table object
      ROWS  - array_array
      ROW_COLORS - ref Array color
      EXTRA_HTML_INFO - Add extra HTML information

  Examples:

=cut
#**********************************************************
sub result_row_former {
  my ($attr)=@_;

  #Array result former
  my %PRE_SORT_HASH = ();

  my $main_arr = $attr->{ROWS};
  my $ROW_COLORS = $attr->{ROW_COLORS};
  my $sort = $FORM{sort} || 1;

  for( my $i=0; $i<=$#{ $main_arr }; $i++ ) {
    $PRE_SORT_HASH{$i}=$main_arr->[$i]->[$sort-1];
  }

  my @sorted_ids = sort {
    if($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
        || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a} || 0) <=> length($PRE_SORT_HASH{$b} || 0)
        || ($PRE_SORT_HASH{$a} || q{}) cmp ($PRE_SORT_HASH{$b} || q{});
      #print "$PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b}<br>";
    }
  } keys %PRE_SORT_HASH;

  my Abills::HTML $table2 = $attr->{table};
  foreach my $line (@sorted_ids) {
    if($ROW_COLORS) {
      $table2->{rowcolor}=($ROW_COLORS->[$line]) ? $ROW_COLORS->[$line] : undef;
    }

    $table2->addrow(
      @{ $main_arr->[$line] },
    );
  }

  if ($attr->{TOTAL_SHOW}) {
    print $table2->show();

    my $table = $html->table(
      {
        width      => '100%',
        rows       => [ [ "$lang{TOTAL}:", $#{ $main_arr } + 1 ] ]
      }
    );

    print $table->show();

    if($attr->{EXTRA_HTML_INFO} && $table->{HTML}) {
      print $attr->{EXTRA_HTML_INFO};
    }

    return '';
  }

  return $table2->show();
}

#**********************************************************
=head2 result_former($attr) - Make result table from different source

  Arguments:
    $attr
      DEFAULT_FIELDS  - Default fields
      HIDDEN_FIELDS   - Requested but not showed in HTML table ('FIELD1,FIELD2')
      INPUT_DATA      - DB object
      FUNCTION        - object list function name
      LIST            - get input data from list (array_hash)
      BASE_FIELDS     - count of default field for list ( Show first %BASE_FIELDS% $search_columns fields )

      DATAHASH        - get input data from json parsed hash
      BASE_PREFIX     - Base prefix for data hash

      FUNCTION_FIELDS - function field forming
         change  - change field
         payment - payment field
         status  - status field
         del     - del field

         custon_field:
           functiom_name:name:param:ex_param

      STATUS_VALS - Value for status fields (status,disable)
      EXT_TITLES  - Translations for table header ( Necessary for column selection modal window)
        [ object_name => 'translation' ]
      SKIP_USER_TITLE - don\'t show user titles in gum menu

      MAKE_ROWS   - Show result table
      MODULE      - Module name for user link
      FILTER_COLS - Use function filter for field
        filter_function:params:params:...
      FILTER_VALUES - Implements FILTER_COLS with coderefs
      SELECT_VALUE- Select value for field
      MULTISELECT - multiselect column ( Will add checkbox for every row string 'id:line_key_for_value_name:form_id' )
        [ id => value ]

      SKIP_PAGES  - Not show table pages
      TABLE       - Table information (HASH)
        caption
        cols_align
        qs
        pages
        ID
        EXPORT
        MENU
      TOTAL         - Show table with totals
                      Multi total
                      $val_id:$name;$val_id:$name
      SHOW_MORE_THEN- Show table when rows more then SHOW_MORE_THEN

      MAP         - Make map tab
      MAP_FIELDS  - Map fields
      MAP_ICON    - Icons for map points

      CHARTS      - Make charts. Coma separated column names to make chart from
      CHARTS_XTEXT- Charts x axis text
      OUTPUT2RETURN - Output to return

  Returns:
    ($table, $list)
    $table   - Table object
    $list    - result array list

  Examples:
    http://abills.net.ua/wiki/doku.php/abills:docs:development:modules:ru#result_former

=cut
#**********************************************************
sub result_former {
  my ($attr) = @_;

  my @cols = ();

  if ($FORM{MAP}) {
    if ($attr->{MAP_FIELDS}) {
      $attr->{DEFAULT_FIELDS} = $attr->{MAP_FIELDS};
    }
    $LIST_PARAMS{'LOCATION_ID'} = '_SHOW';
    $LIST_PARAMS{'PAGE_ROWS'} = 1000001;
  }

  if ($FORM{del_cols}) {
    $admin->settings_del( $attr->{TABLE}->{ID} );
    if ($attr->{DEFAULT_FIELDS}) {
      $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }
  elsif ($FORM{show_columns}) {
    #print $FORM{del_cols};
    @cols = split(/,\s?/, $FORM{show_columns});
    if($FORM{show_cols}) {
      $admin->settings_add({
        SETTING => $FORM{show_columns},
        OBJECT  => $attr->{TABLE}->{ID}
      });
    }
  }
  else {
    if(ref $admin eq 'Admins' && $admin->can('settings_info')) {
      $admin->settings_info($attr->{TABLE}->{ID});
      if ($admin->{TOTAL} == 0 && $attr->{DEFAULT_FIELDS}) {
        $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
        @cols = split(/,/, $attr->{DEFAULT_FIELDS});
      }
      else {
        if ($admin->{SETTING}) {
          @cols = split(/, /, $admin->{SETTING});
        }
      }
    }
    elsif($attr->{DEFAULT_FIELDS}) {
      $attr->{DEFAULT_FIELDS} =~ s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }

  if($attr->{HTML}) {
    $html = $attr->{HTML};
    if(! $index) {
      $index = $html->{index};
      $attr->{FUNCTION_INDEX}=$index;
    }
  }

  my @hidden_fields = ();
  if ($attr->{HIDDEN_FIELDS}) {
    @hidden_fields = split(/,/, $attr->{HIDDEN_FIELDS});
    for(my $i=0; $i<=$#hidden_fields; $i++) {
      my $fld = $hidden_fields[$i];
      if(! in_array($fld, \@cols)) {
        push @cols, $fld;
      }
      else {
        delete $hidden_fields[$i];
      }
    }
  }

  foreach my $line (@cols) {
    if (! defined($LIST_PARAMS{$line}) || $LIST_PARAMS{$line} eq '') {
      $LIST_PARAMS{$line}='_SHOW';
    }
  }

  if ($attr->{APPEND_FIELDS}){
    my @arr = split(/,/, $attr->{APPEND_FIELDS});
    foreach my $line (@arr) {
      if (!in_array($line, \@cols)) {
        if (! defined($LIST_PARAMS{$line}) || $LIST_PARAMS{$line} eq '') {
          $LIST_PARAMS{$line}='_SHOW';
        }
      }
    }
  }

  my $data = $attr->{INPUT_DATA};
  if ($attr->{FUNCTION}) {
    my $fn   = $attr->{FUNCTION};

    if (! $data) {
      print "No input objects data\n";
      return 0;
    }

    delete($data->{COL_NAMES_ARR});
    my $list = $data->$fn({ COLS_NAME => 1, %LIST_PARAMS, SHOW_COLUMNS => $FORM{show_columns} });
    #_error_show($data);

    $data->{list} = $list;
  }
  elsif($attr->{LIST}) {
    $data->{list} = $attr->{LIST};
  }

  if ($data->{error}) {
    return;
  }

  #Make maps
  if($attr->{MAP} && ( ! $attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN} )) {
    my @header_arr = ("$lang{MAIN}:index=$index".$attr->{TABLE}->{qs},
      "$lang{MAP}:index=$index&&MAP=1".$attr->{TABLE}->{qs}
    );
    my $exec_function;
    if( $attr->{EXTRA_TABS}) {
      foreach my $name ( keys %{ $attr->{EXTRA_TABS} } ) {
        my($title, $function_name)=split(/:/, $name);
        push @header_arr, "$title:$attr->{EXTRA_TABS}->{$name}";

        my $qs = $ENV{QUERY_STRING};
        $qs =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        if($ENV{QUERY_STRING} eq $attr->{EXTRA_TABS}->{$name}) {
          $exec_function = $function_name;
        }
      }
    }

    print $html->table_header(\@header_arr, { TABS => 1 });

    if($FORM{MAP}) {
      if(in_array('Maps', \@MODULES)) {
        load_module('Maps', $html);

        my %USERS_INFO = ();
        foreach my $line (@{ $data->{list} }) {
          next unless ($line->{build_id} || $line->{location_id});
          push @{ $USERS_INFO{ $line->{build_id} || $line->{location_id} } }, $line;
        }

        maps_show_map({
          DATA                  => \%USERS_INFO,
          MAP_FILTERS           => $attr->{MAP_FILTERS},
          LOCATION_TABLE_FIELDS => $attr->{MAP_FIELDS},
          POINT_TYPE            => $attr->{MAP_ICON},
        });
        return -1, -1;
      }
    }
    elsif($exec_function) {
      if( defined( $exec_function ) ) {
        &{ \&$exec_function }();

        return -1, -1;
      }
    }
  }

  my @service_status_colors = ("#000000", "#FF0000", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status        = ($lang{ENABLE}, $lang{DISABLE}, $lang{NOT_ACTIVE}, $lang{HOLD_UP},
    "$lang{DISABLE}: $lang{NON_PAYMENT}", $lang{ERR_SMALL_DEPOSIT},
    $lang{VIRUS_ALERT} );

  if ($attr->{STATUS_VALS}) {
    @service_status = @{ $attr->{STATUS_VALS} };
  }

  my %SEARCH_TITLES = (
    #'disable'       => "$lang{STATUS}",
    'login_status'  => "$lang{LOGIN} $lang{STATUS}",
    'deposit'       => "$lang{DEPOSIT}",
    'credit'        => "$lang{CREDIT}",
    'login'         => "$lang{LOGIN}",
    'fio'           => "$lang{FIO}",
    'last_payment'  => "$lang{LAST_PAYMENT}",
    'email'         => 'E-Mail',
    'pasport_date'  => "$lang{PASPORT} $lang{DATE}",
    'pasport_num'   => "$lang{PASPORT} $lang{NUM}",
    'pasport_grant' => "$lang{PASPORT} $lang{GRANT}",
    'contract_id'   => "$lang{CONTRACT_ID}",
    'contract_date' => "$lang{CONTRACT} $lang{DATE}",
    'registration'  => "$lang{REGISTRATION}",
    'phone'         => "$lang{PHONE}",
    'comments'      => "$lang{COMMENTS}",
    'company_id'    => "$lang{COMPANY} ID",
    'bill_id'       => "$lang{BILLS}",
    'activate'      => "$lang{ACTIVATE}",
    'expire'        => "$lang{EXPIRE}",
    'credit_date'   => "$lang{CREDIT} $lang{DATE}",
    'reduction'     => "$lang{REDUCTION}",
    'domain_id'     => 'DOMAIN ID',

    'district_name' => "$lang{DISTRICTS}",
    'address_full'  => "$lang{FULL} $lang{ADDRESS}",
    'address_street'=> "$lang{ADDRESS_STREET}",
    'address_build' => "$lang{ADDRESS_BUILD}",
    'address_flat'  => "$lang{ADDRESS_FLAT}",
    'address_street2'=> $lang{SECOND_NAME},
    'city'          => "$lang{CITY}",
    'zip'           => "$lang{ZIP}",

    'deleted'       => "$lang{DELETED}",
    'gid'           => "$lang{GROUP}",
    'group_name'    => "$lang{GROUP} $lang{NAME}",
    #    'build_id'      => 'Location ID',
    'uid'           => 'UID',
  );

  if(in_array('Tags', \@MODULES)) {
    $SEARCH_TITLES{tags}=$lang{TAGS};
  }

  if ($conf{ACCEPT_RULES}) {
    $SEARCH_TITLES{accept_rules}=$lang{ACCEPT_RULES};
  }
  #  if (in_array('Dv', \@MODULES)) {
  #    $SEARCH_TITLES{'dv_status'}="Internet $lang{STATUS}";
  #  }

  if ($conf{EXT_BILL_ACCOUNT}) {
    $SEARCH_TITLES{'ext_deposit'}="$lang{EXTRA} $lang{DEPOSIT}";
  }

  if ($conf{CONTACTS_NEW} && !$attr->{SKIP_USERS_FIELDS}) {
    $SEARCH_TITLES{cell_phone}= $lang{CELL_PHONE};
  }

  my %ACTIVE_TITLES = ();

  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if (ref $line eq 'ARRAY' && $line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my (undef, undef, $name, undef) = split(/:/, $line->[1]);
        if ($name =~ /\$/) {
          $SEARCH_TITLES{ $field_id } = _translate($name);
        }
        else {
          $SEARCH_TITLES{ $field_id } = $name;
        }
      }
      elsif($line->{id}) {
        my $field_id = $line->{sql_field};
        my $name     = $line->{name};
        if ($name =~ /\$/) {
          $SEARCH_TITLES{ $field_id } = _translate($name);
        }
        else {
          $SEARCH_TITLES{ $field_id } = $name;
        }
      }
    }
  }

  if ($attr->{SKIP_USER_TITLE}) {
    %SEARCH_TITLES = %{ $attr->{EXT_TITLES} } if ($attr->{EXT_TITLES});
  }
  elsif($attr->{EXT_TITLES}) {
    %SEARCH_TITLES = ( %SEARCH_TITLES, %{ $attr->{EXT_TITLES}} );
  }

  my $base_fields  = $attr->{BASE_FIELDS} || 0;
  my @EX_TITLE_ARR = ();
  if ($data->{COL_NAMES_ARR} && ref $data->{COL_NAMES_ARR} eq 'ARRAY'){
    @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  }

  if($FORM{json}) {
    push @EX_TITLE_ARR, @hidden_fields;
    $data->{SEARCH_FIELDS_COUNT} += $#hidden_fields+1;
  }

  my @title        = ();
  my $search_fields_count = $data->{SEARCH_FIELDS_COUNT} || 0;

  for (my $i = 0 ; $i < $base_fields+$search_fields_count ; $i++) {
    if($EX_TITLE_ARR[$i] && ! $FORM{json} && in_array(uc($EX_TITLE_ARR[$i]), \@hidden_fields)) {
      next;
    }

    push @title, ($EX_TITLE_ARR[$i] && $SEARCH_TITLES{ $EX_TITLE_ARR[$i] }) || ($cols[$i] && $SEARCH_TITLES{$cols[$i]}) || $EX_TITLE_ARR[$i] || $cols[$i] || "$lang{SEARCH}";
    $ACTIVE_TITLES{($EX_TITLE_ARR[$i] || '')} = ($EX_TITLE_ARR[$i] && $FORM{uc($EX_TITLE_ARR[$i])}) || '_SHOW';
  }

  #data hash result former
  if(ref $attr->{DATAHASH} eq 'ARRAY') {
    @title = sort keys %{ $attr->{DATAHASH}->[0] };

    if($#hidden_fields) {
      my @title_ = grep {
        my $t = $_;
        ! grep { $_ eq $t } @hidden_fields;
      } @title;
      @title = @title_;
    }

    $data->{COL_NAMES_ARR} = \@title;
    @EX_TITLE_ARR = @title;
  }
  elsif (! $data->{COL_NAMES_ARR}) { # || $#cols > $#title){
    if ($attr->{BASE_PREFIX}) {
      @cols = (split(/,/, $attr->{BASE_PREFIX}), @cols);
    }

    my $i = 0;
    for ($i = 0 ; $i <= $#cols+$base_fields; $i++) {
      if($cols[$i] && !$FORM{json} && in_array(uc($cols[$i]), \@hidden_fields)) {
        next;
      }
      if ($cols[$i]){
        $title[$i] = $SEARCH_TITLES{lc( $cols[$i] )} || $attr->{TABLE}->{SHOW_COLS}->{$cols[$i]} || $cols[$i] || '44';
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
      #      else {
      #        $title[$i] = q{33};
      #        $ACTIVE_TITLES{q{}} = q{};
      #      }
    }

    if ($#cols> -1) {
      if ($cols[$i]){
        $title[$i]     = $cols[$i] || q{22};
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
    }

    if (! $data->{COL_NAMES_ARR}) {
      $data->{COL_NAMES_ARR}=\@cols; #\@title
    }
  }
  #  else {
  #    print "// $data->{COL_NAMES_ARR}  $#cols > $#title //";
  #  }

  my @function_fields = split(/,\s?/, $attr->{FUNCTION_FIELDS} || '' );

  if($#function_fields > -1) {
    $title[$#title+1]='';
  }

  if ($attr->{TABLE} ) {
    my $title_type = 'title';
    if ( $attr->{TABLE}->{title_plain} ) {
      $title_type = 'title_plain';
    }

    if ($attr->{TABLE}{DATA_TABLE} && !defined($attr->{TABLE}{SKIP_PAGES})){
      $attr->{SKIP_PAGES} = 1;
    }

    my($multisel_id, $multisel_value, $multisel_form, $obj_info);
    my @multiselect_arr = ();
    if ( $attr->{MULTISELECT} ){
      ($multisel_id, $multisel_value, $multisel_form, $obj_info) = split(/:/, $attr->{MULTISELECT});
      if ( $FORM{$multisel_id} ) {
        @multiselect_arr = split(/,\s?|;\s?/, $FORM{$multisel_id});
      }
      # First and last values are simply ignored
      $attr->{TABLE}{SELECT_ALL} //= ($multisel_form || q{}) .":". ($multisel_id || q{}) .":". ($obj_info || q{});
      $attr->{TABLE}{SHOW_MULTISELECT_ACTIONS} = scalar(@multiselect_arr);
    }

    unless ( $Abills::HTML::VERSION ) {
      require Abills::HTML;
      Abills::HTML->import();
    }

    my Abills::HTML $table = $html->table(
      {
        SHOW_COLS           => ($attr->{TABLE}{SHOW_COLS}) ? $attr->{TABLE}{SHOW_COLS} : \%SEARCH_TITLES,
        %{ $attr->{TABLE} },
        $title_type         => \@title,
        border              => 1,
        pages               => (! $attr->{SKIP_PAGES}) ? $data->{TOTAL} : undef,
        FIELDS_IDS          => $data->{COL_NAMES_ARR},
        HAS_FUNCTION_FIELDS => (defined $attr->{FUNCTION_FIELDS} && $attr->{FUNCTION_FIELDS}) ? 1 : 0,
        ACTIVE_COLS         => \%ACTIVE_TITLES,
      }
    );

    $table->{COL_NAMES_ARR} = $data->{COL_NAMES_ARR};
    $table->{HIDDEN_FIELD_COUNT}=$#hidden_fields+1;

    if ($attr->{MAKE_ROWS} && $data->{list}) {
      my $brake = $html->br();
      my $chart_num   = 0;

      if($data->{errno}) {
        _error_show($data, { MESSAGE => 'RESULT_FORMER: '. ($attr->{TABLE}->{caption} || q{}) });
        return 0;
      }
      elsif ( ref $data->{list} ne 'ARRAY' ){
        print "<br></hr> ERROR: " . q{ ref $data->{list} ne 'ARRAY' };
        return 0;
      }

      my $search_color_mark = q{};
      if ($FORM{_MULTI_HIT}) {
        $FORM{_MULTI_HIT} =~ s/\*//g;
        $search_color_mark=$html->color_mark($FORM{_MULTI_HIT}, 'text-danger');
      }

      if($FORM{json} && $table->{HIDDEN_FIELD_COUNT}) {
        $search_fields_count += $table->{HIDDEN_FIELD_COUNT};
      }

      foreach my $line (@{ $data->{list} }) {
        my @fields_array = ();

        for (my $i = 0 ; $i < $base_fields + $search_fields_count; $i++) {
          my $val       = '';
          my $col_name = $data->{COL_NAMES_ARR}->[$i] || '';

          if(! $FORM{json} && in_array(uc($col_name), \@hidden_fields)) {
            next;
          }
          if ($col_name eq 'login' && $line->{uid} && defined(&user_ext_menu)) {
            if (! $FORM{EXPORT_CONTENT}) {
              my $dv_status_color = undef;
              if (defined($line->{dv_status}) && $attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{dv_status}) {
                (undef, $dv_status_color) = split(/:/, $attr->{SELECT_VALUE}->{dv_status}->{ $line->{dv_status} } || '');
              }
              $val = user_ext_menu($line->{uid}, $line->{login}, { EXT_PARAMS => ($attr->{MODULE} ? "MODULE=$attr->{MODULE}": undef), dv_status_color => $dv_status_color });
            }
            else {
              $val = $line->{login};
            }
          }
          #use filter to cols
          elsif ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$col_name}) {
            # $filter_fn
            my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$col_name});

            my %p_values = ();
            if ($arr[1] && $arr[1] =~ /,/) {
              foreach my $k ( split(/,/, $arr[1]) ) {
                if ($k =~ /(\S+)=(.*)/) {
                  $p_values{$1}=$2;
                }
                elsif (defined($line->{lc($k)})) {
                  $p_values{$k}=$line->{lc($k)};
                }
              }
            }

            $val = &{ \&$filter_fn }($line->{$col_name}, { PARAMS => \@arr,
                VALUES    => \%p_values,
                LINK_NAME => ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$col_name}) ?
                  $attr->{SELECT_VALUE}->{$col_name}->{$line->{$col_name}} : undef
              });
          }
          # Implements FILTER_COLS with coderefs
          elsif ($attr->{FILTER_VALUES} && $attr->{FILTER_VALUES}->{$col_name}){
            if (ref $attr->{FILTER_VALUES}->{$col_name} eq 'CODE'){
              $val = $attr->{FILTER_VALUES}->{$col_name}->($line->{$col_name}, $line);
            }
            else {
              warn "FILTER_VALUES expects coderef";
            }
          }
          elsif($col_name =~ /status$/ && (! $attr->{SELECT_VALUE} || ! $attr->{SELECT_VALUE}->{$col_name})) {
            $val = ($line->{$col_name} && $line->{$col_name} > 0) ? $html->color_mark($service_status[ $line->{$col_name} ], $service_status_colors[ $line->{$col_name} ]) :
              ( defined $line->{$col_name} ? $service_status[$line->{$col_name}] : '');
          }
          elsif($col_name =~ /deposit/) {
            if (!$permissions{0}{12}) {
              $val = '--';
            }
            else {
              my $deposit = $line->{deposit} || 0;
              if ($conf{DEPOSIT_FORMAT}) {
                $deposit = sprintf("$conf{DEPOSIT_FORMAT}", $deposit);
              }
              $val =  ($deposit + ($line->{credit} || 0) < 0) ? $html->color_mark( $deposit, 'text-danger' ) : $deposit,
            }
          }
          elsif($col_name eq 'deleted') {
            $val = ($line->{deleted}) ? $html->color_mark($lang{DELETED}, 'text-danger') : '';
          }
          elsif($col_name eq 'online') {
            $val = ($line->{online}) ? $html->color_mark('Online', '#00FF00') : '';
          }
          elsif($col_name eq 'color'){
            $val = ($line->{$col_name}) ? $html->color_mark($line->{$col_name}, $line->{$col_name}) : '';
          }
          elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$col_name} && defined($line->{$col_name})) {
            my($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$col_name}->{$line->{$col_name}} || '');

            if($value && $color) {
              $value = $html->color_mark($value, $color);
            }

            $val = $value || $line->{$col_name};
          }
          else {
            $val = $line->{ $col_name  } || '';
            $val =~ s/\n/$brake/g;
          }

          if ($i==0 && $attr->{MULTISELECT}) {
            unshift (@fields_array, $html->form_input($multisel_id, $line->{$multisel_value}, {
                  TYPE    => 'checkbox',
                  FORM_ID => $multisel_form // '',
                  STATE   => in_array($line->{$multisel_value}, \@multiselect_arr)
                })
            );
          }

          if($search_color_mark) {
            $val =~ s/(.*)$FORM{_MULTI_HIT}(.*)/$1$search_color_mark$2/g;
          }

          push @fields_array, $val;
        }

        if($#function_fields > -1) {
          push @fields_array, join(' ', @{ table_function_fields(\@function_fields, $line, $attr) });

          if ($FORM{chg} && $line->{id} && $FORM{chg} == $line->{id}) {
            $table->{rowcolor}='row-active';
            $fields_array[0] = $html->element('span', '&nbsp;', { class => 'text-success fa fa-ellipsis-v', OUTPUT2RETURN => 1 }). $fields_array[0];
          }
          else {
            $table->{rowcolor}=undef;
          }
        }

        #make charts
        if ( $attr->{CHARTS} ) {
          my @charts = split(/,\s?/, $attr->{CHARTS});
          if($line->{date} && $line->{date} =~ /\d{4}-\d{2}-(\d{2})/) {
            #$CHARTS{PERIOD}=1 if (!$CHARTS{PERIOD});
            #$num = ($CHARTS{PERIOD}) ? $dd : $dd + 1;
            $chart_num = $1 || 0;
          }
          else {
            $chart_num++;
            if ( $attr->{CHARTS_XTEXT} && defined $line->{$attr->{CHARTS_XTEXT}} ) {

              if ( $attr->{CHARTS_XTEXT} eq 'auto' ) {
                $attr->{CHARTS_XTEXT} = $data->{COL_NAMES_ARR}->[0];
              }

              my $col_name = $attr->{CHARTS_XTEXT};
              $CHARTS{X_TEXT}->[$chart_num - 1] =
                  (
                    $attr->{SELECT_VALUE}
                      && $attr->{SELECT_VALUE}->{$col_name}
                      && $attr->{SELECT_VALUE}->{$col_name}->{ $line->{$col_name} }
                  )
                ? $attr->{SELECT_VALUE}->{$col_name}->{ $line->{$col_name} }
                : $line->{$col_name};
            }
          }

          foreach my $c_val ( @charts ) {
            $DATA_HASH{$c_val}->[$chart_num] = $line->{$c_val} || 0;
            my $num = int($chart_num);
            next if (!$num);
            $CHARTS{X_TEXT}->[$num - 1] ||= $chart_num;
          }
        }

        $table->addrow(@fields_array);
      }
    }
    #Datahash
    elsif($attr->{DATAHASH} && ref $attr->{DATAHASH} eq 'ARRAY') {
      $data->{TOTAL}=0;
      $table->{sub_ref}=1;

      $attr->{EX_TITLE_ARR}=\@EX_TITLE_ARR;
      $attr->{FUNCTION_FIELDS}=\@function_fields;

      my $rows  = _datahash2table($attr);
      foreach my $row (@$rows ) {
        $table->addrow(@$row);
        $data->{TOTAL}++;
      }
    }

    if ($attr->{TOTAL} && ( ! $attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN} )) {
      my $result = $table->show();
      if (! $admin->{MAX_ROWS} && ! $attr->{SKIP_TOTAL_FORM}) {
        my @rows = ();

        if ($attr->{TOTAL} =~ /;/) {
          my @total_vals = split(/;/, $attr->{TOTAL});
          foreach my $line (@total_vals) {
            my ($val_id, $name)=split(/:/, $line);
            push @rows, [ $name ? ( $lang{$name} || $name ) : $val_id, $html->b(($val_id) ? $data->{$val_id} : q{}) ];
          }
        }
        else {
          @rows = [ "$lang{TOTAL}:", $html->b($data->{TOTAL}) ]
        }

        $table = $html->table({
          ID    => ($attr->{TABLE}->{ID}) ? "$attr->{TABLE}->{ID}_TOTAL" : q{},
          width => '100%',
          rows  => \@rows
        });

        $result .= $table->show();
      }

      if ($attr->{OUTPUT2RETURN}) {
        return $result, $data->{list};
      }
      else {
        if (! $attr->{SEARCH_FORMER} || (defined($data->{TOTAL}) && $data->{TOTAL} > -1)) {
          print $result || q{};
        }
      }
    }

    return ($table, $data->{list});
  }
  else {
    return \@title;
  }
}


#**********************************************************
=head2 _datahash2table($attr) - Datahash to table

  Arguments:
    $attr
      EX_TITLE_ARR
      FUNCTION_FIELDS
      DATAHASH
      SELECT_VALUE
      FILTER_COLS

  Results:
    \@rows

=cut
#**********************************************************
sub _datahash2table {
  my ($attr)=@_;

  my @rows = ();
  my $EX_TITLE_ARR = $attr->{EX_TITLE_ARR};
  my $function_fields = $attr->{FUNCTION_FIELDS};
  my %PRE_SORT_HASH = ();
  my $sort = $FORM{sort} || 1;
  for( my $i=0; $i<=$#{ $attr->{DATAHASH} }; $i++ ) {
    $PRE_SORT_HASH{$i}=$attr->{DATAHASH}->[$i]->{ $EX_TITLE_ARR->[$sort - 1] || q{} } //= q{};
  }

  my @sorted_ids = sort {
    if($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
        || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a}) <=> length($PRE_SORT_HASH{$b})
        || $PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b};
    }
  } keys %PRE_SORT_HASH;

  foreach my $row_num (@sorted_ids) {
    my @row = ();
    my $line = $attr->{DATAHASH}->[$row_num];

    for(my $i=0; $i<=$#{ $EX_TITLE_ARR }; $i++) {
      #use filter to cols
      my $field_name = $EX_TITLE_ARR->[$i];
      my $col_data   = $line->{$field_name};

      if ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$field_name}) {
        my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$field_name});
        Encode::_utf8_off($col_data);
        push @row, &{ \&$filter_fn }($col_data, { PARAMS => \@arr });
      }
      elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$field_name}) {
        if($col_data && $attr->{SELECT_VALUE}->{$field_name}->{$col_data}) {
          my($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$field_name}->{$col_data});
          push @row, ($color) ? $html->color_mark($value, $color) : $value;
        }
        else {
          Encode::_utf8_off($col_data);
          push @row, $col_data;
        }
      }
      else {
        push @row, _hash2html($col_data, $attr);
      }
    }

    if($#{ $function_fields } > -1) {
      push @row, @{ table_function_fields($function_fields, $line, $attr) };
    }

    push @rows, \@row;
  }

  return \@rows;
}

#**********************************************************
=head2 search_link($val, $attr); - forming search link

  Arguments:
    $val  - Function name
    $attr -
      PARAMS
      VALUES
      LINK_NAME

  Returns:
    Link

=cut
#**********************************************************
sub search_link {
  my ($val, $attr) = @_;

  my $params = $attr->{PARAMS};
  my $ext_link = '';
  if ($attr->{VALUES}) {
    foreach my $k ( keys %{ $attr->{VALUES} } ) {
      $ext_link .= "&$k=$attr->{VALUES}->{$k}";
    }
  }
  else {
    $ext_link .=  '&'. "$params->[1]=". $val;
  }

  my $result = $html->button($attr->{LINK_NAME} || $val , "index=". get_function_index($params->[0]) . "&search_form=1&search=1".$ext_link );

  return $result;
}

#**********************************************************
=head2 _hash2html($col_data) - JSON TO HTML formater;

  Arguments:
    $col_data - Hash variable content
    $attr
      SKIPP_UTF_OFF

  Results:
    $html_value

=cut
#**********************************************************
sub _hash2html {
  my ($col_data, $attr) = @_;

  my $result = '';

  if( ref $col_data eq 'ARRAY' ) {
    foreach my $key (@$col_data) {
      $result .= _hash2html($key, $attr) . $html->br();
    }
  }
  elsif (ref $col_data eq 'HASH') {
    my $val = '';
    foreach my $key (sort keys %{ $col_data }) {
      $val .= $html->b($key) .' : '. _hash2html($col_data->{$key}, $attr) . $html->br();
    }

    $result = $val;
  }
  else {
    if(! $attr->{SKIPP_UTF_OFF}) {
      Encode::_utf8_off($col_data);
    }
    $result = $col_data //= q{};
  }

  return $result;
}

#**********************************************************
=head2 table_function_fields($function_fields, $line, $attr) - Make function fields

  Attributes:
    $function_fields - Function fields name (array_ref)
      form_payments
      stats
      change
      cpmpany_id
      ex_info
      del
    $line            - array_ref of list result
    $attr            - Extra attributes
      TABLE          - Table object hash_ref
      MODULE         - Module name
      FUNCTION_INDEX -

  Result:
    Arrya_ref of cols

=cut
#**********************************************************
sub table_function_fields {
  my ($function_fields, $line, $attr) = @_;

  my @fields_array = ();
  my $query_string = ($attr->{TABLE} && $attr->{TABLE}{qs}) ? $attr->{TABLE}{qs} : q{};

  if($line->{uid} && $query_string !~ /UID=/) {
    $query_string .= "&UID=$line->{uid}";
    $index = $attr->{FUNCTION_INDEX} || 15;
  }

  for (my $i = 0 ; $i <= $#{ $function_fields } ; $i++) {
    if ($function_fields->[$i] eq 'form_payments') {
      #  TODO check why it returned []
      #  return [] if (!$line->{uid});
      next if (!$line->{uid});
      push @fields_array, ($permissions{1}) ? $html->button($function_fields->[$i], "UID=$line->{uid}&index=2", { class => 'payments' }) : '-';
    }
    elsif ($function_fields->[$i] =~ /stats/) {
      push @fields_array, $html->button($function_fields->[$i],
          "&index=" . get_function_index($function_fields->[$i]). $query_string, { class => 'stats' });
    }
    elsif ($function_fields->[$i] eq 'change') {
      push @fields_array, $html->button($lang{CHANGE}, "index=$index&chg=". ($line->{id} || q{})
            . (($attr->{MODULE}) ? "&MODULE=$attr->{MODULE}" : '')
            . $query_string, { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'info') {
      push @fields_array, $html->button($lang{INFO}, "index=$index&info=". ($line->{id} || q{})
            . (($attr->{MODULE}) ? "&MODULE=$attr->{MODULE}" : '')
            . $query_string, { class => 'info' });
    }
    elsif ($function_fields->[$i] eq 'company_id') {
      push @fields_array,
        $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
            . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
            . $query_string, { class => 'change' });
    }
    elsif (in_array('Info', \@MODULES) && $function_fields->[$i] eq 'ex_info') {
      $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . $query_string, { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'del') {
      push @fields_array,
        $html->button($lang{DEL},  "&index=$index&del="
          . (($line->{id}) ? $line->{id} : '')
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . $query_string,  { class => 'del', MESSAGE => "$lang{DEL} ". ($line->{name} || $line->{id} || q{-}) ."?" }
        );
    }
    else {
      my $qs            = '';
      my $functiom_name = $function_fields->[$i];
      my $button_name   = $function_fields->[$i];
      my $param         = '';
      my $ex_param      = '';

      my %button_params = ();

      # FIXME: 0-0 in first capture group
      if ($function_fields->[$i] =~ /([a-z0-0\_\-]{0,25}):([a-zA-Z\_0-9\{\}\$]+):([a-z0-9\-\_\;]+):?(\S{0,100})/) {
        $functiom_name = $1;
        my $name       = $2;
        $param         = $3;
        $ex_param      = $4;

        if($name eq 'del') {
          $button_params{class}   = 'del';
          $button_params{TITLE} = "$lang{DEL}";
          $button_params{MESSAGE} = "$lang{DEL} ". ($line->{name} || $line->{id} || q{-}) ."?";
        }
        elsif($name eq 'change') {
          $button_params{class}='change';
        }
        elsif($name eq 'show') {
          $button_params{class}='show';
          $button_params{TITLE} = "$lang{SHOW}";
          $button_name   = '';
        }
        elsif($name eq 'add') {
          $button_params{class}='add';
        }
        else {
          $button_params{BUTTON}=1;
          $button_name   = _translate($name);
        }

        $qs .= 'index=' . (($functiom_name) ? get_function_index($functiom_name) : $index);
        $qs .= $ex_param;
      }
      else {
        $qs = "index=" . get_function_index($functiom_name);
      }

      if ($param) {
        foreach my $l (split(/;/, $param)) {
          if ( $line->{$l} ) {
            #Fixme Uncoment for omega
            my $is_utf = Encode::is_utf8($line->{$l});
            if(! $is_utf) {
              Encode::_utf8_off($line->{$l});
            }

            $qs .= '&' . uc($l) . "=$line->{$l}";
          }
        }
      }
      elsif ($line->{uid}) {
        $qs .= "&UID=$line->{uid}";
      }

      push @fields_array, $html->button($button_name, $qs, \%button_params);
    }
  }

  return \@fields_array;
}


1;