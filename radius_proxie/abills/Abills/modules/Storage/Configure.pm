#package Storage::Configure;
use strict;
use warnings FATAL => 'all';

our ($db,
  %conf,
  $admin,
  $html,
  %lang,
  %permissions);

use Storage;
use Abills::Base qw/_bp/;

my $Storage = Storage->new($db, $admin, \%conf);

$Storage->storage_measure_list(
  {
    NAME      => '_SHOW',
    LIST2HASH => 'id,name'
  }
);

our %measures_name = %{  _storage_translate_measure( \%{$Storage->{list_hash}}) };

#***********************************************************
=head2 storage_articles() - Storage articles

=cut
#***********************************************************
sub storage_articles{

  if ( $FORM{message} ) {
    $html->message( 'info', $lang{INFO}, "$FORM{message}" );
  }

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{ADD_DATE} = '0000-00-00';

  if ( $FORM{add} ) {
    if ( $FORM{NAME} && $FORM{ARTICLE_TYPE} && defined( $FORM{MEASURE} ) ) {
      $Storage->storage_articles_add( { %FORM } );
      if ( !$Storage->{errno} ) {
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{ADDED}",
          }
        );
      }
    }
    else {
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARTICLETYPE_MEASURE_ARE_REQUIRED}" );
      $html->tpl_show( _include( 'storage_articles', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{del} ) {
    my $list = $Storage->storage_incoming_articles_list( { ARTICLE_ID => $FORM{del}, COLS_NAME => 1 } );
    if($Storage->{TOTAL} > 0){
      $html->message( 'warning', $lang{INFO}, "$lang{CANT_DELETE_ERROR1} " );
    }
    else {
      $Storage->storage_articles_del( { ID => $FORM{del} } );
      if ( !$Storage->{errno} ) {
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
      }
    }
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{NAME} && $FORM{ARTICLE_TYPE} && defined( $FORM{MEASURE} ) ) {
      $Storage->storage_articles_change( { %FORM } );
      if ( !$Storage->{errno} ) {
        $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
      }
    }
    else {
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARTICLETYPE_MEASURE_ARE_REQUIRED}" );
      $html->tpl_show( _include( 'storage_articles', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{chg} ) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};

    $Storage->storage_articles_info( { ID => $FORM{chg}, } );

    if ( !$Storage->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
  }

  $Storage->{ARTICLE_TYPES} = $html->form_select(
    'ARTICLE_TYPE',
    {
      SELECTED    => $Storage->{ARTICLE_TYPE} || 0,
      SEL_LIST    => $Storage->storage_types_list( { COLS_NAME => 1 } ),
      NO_ID       => 1,
      SEL_OPTIONS => { '' => '--' },
    }
  );

  $Storage->{MEASURE_SEL} = $html->form_select(
    'MEASURE',
    {
      SELECTED      => $Storage->{MEASURE} || $FORM{MEASURE} || 0,
      SEL_HASH      => _storage_translate_measure(\%measures_name),
      NO_ID         => 1,
      OUTPUT2RETURN => 1,
    }
  );

  if ( !$FORM{add} && !$FORM{change} ) {
    $html->tpl_show( _include( 'storage_articles', 'Storage' ), $Storage );
  }

  result_former( {
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_articles_list',
    BASE_FIELDS     => 6,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    SELECT_VALUE    => { measure => \%measures_name },
    EXT_TITLES      => {
      id        => '#',
      name      => $lang{NAME},
      type_name => $lang{TYPE},
      measure   => $lang{MEASURE},
      add_date  => $lang{DATE},
      comments  => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{ARTICLES}",
      qs      => $pages_qs,
      ID      => 'ARTICLES_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  } );

  return 1;
}


#**********************************************************
=head2 storage_measures()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_measure {
  my %STORAGE_MEASURE_TEMPLATE = (
    BTN_NAME  => "add",
    BTN_VALUE => $lang{ADD}
  );

  if ($FORM{add}) {
    $Storage->storage_measure_add({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_measure_change({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{del}) {
    $Storage->storage_articles_list({MEASURE => $FORM{del}, COLS_NAME => 1});
    if($Storage->{TOTAL} > 0){
      $html->message('warn', "$lang{ERROR}", $lang{CANT_DELETE_ERROR5});
    }
    else{
      $Storage->storage_measure_delete({ ID => $FORM{del} });
      _error_show($Storage);
    }
  }

  if ($FORM{chg}) {
    $STORAGE_MEASURE_TEMPLATE{BTN_NAME} = "change";
    $STORAGE_MEASURE_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $action_info = $Storage->storage_measure_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      COMMENTS   => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    _error_show($Storage);

    if ($action_info) {
      @STORAGE_MEASURE_TEMPLATE{keys %$action_info} = values %$action_info;
    }

  }

  $html->tpl_show(
    _include('storage_measure', 'Storage'),
    {
      %STORAGE_MEASURE_TEMPLATE
    }
  );

  result_former(
    {
      INPUT_DATA      => $Storage,
      FUNCTION        => 'storage_measure_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, COMMENTS",
      FUNCTION_FIELDS => 'change,del',
      FILTER_COLS     => {name => "_storage_translate_measure::NAME,"},
      EXT_TITLES      => {
        'id'     => "ID",
        'name'   => $lang{NAME},
        'comments' => $lang{COMMENTS},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{MEASURE},
        qs      => $pages_qs,
        ID      => 'STORAGE_MEASURE',
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Storage',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );
}

#**********************************************************
=head2 storage_translate_measure()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _storage_translate_measure {
  my ($attr) = @_;

  if($attr && ref $attr eq "HASH"){
    foreach my $key (%$attr){
      $attr->{$key} = _translate($attr->{$key});
    }
  }
  else{
    $attr = _translate($attr);
  }

  return $attr;
}

#***********************************************************
=head2 storage_articles_types() - Storage articles types

=cut
#***********************************************************
sub storage_articles_types{

  if ( $FORM{message} ) {
    $html->message( 'info', $lang{INFO}, "$FORM{message}" );
  }

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};

  if ( $FORM{add} ) {
    if ( $FORM{NAME} ) {
      $Storage->storage_types_add( { %FORM } );
      if ( !$Storage->{errno} ) {
        #$html->message('info', $lang{INFO}, "$lang{ADDED}");
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{ADDED}",
          }
        );
      }
    }
    else {
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_TYPE_ARE_REQUIRED}" );
      $html->tpl_show( _include( 'storage_articles_types', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    my $list_in_use = $Storage->storage_articles_list({ARTICLE_TYPE => $FORM{del}});
    if($Storage->{TOTAL} > 0){
      $html->message('warn', "$lang{ERROR}", "$lang{CANT_DELETE_ERROR2}");
    }
    else{
      $Storage->storage_types_del( { ID => $FORM{del} } );

      if ( !$Storage->{errno} ) {
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
      }
    }
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{NAME} ) {
      $Storage->storage_types_change( { %FORM } );
      if ( !$Storage->{errno} ) {
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{CHANGED}",
          }
        );
      }
    }
    else {
      $Storage->{ACTION} = 'change';
      $Storage->{ACTION_LNG} = $lang{CHANGE};
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_TYPE_ARE_REQUIRED}" );
    }
  }
  elsif ( $FORM{chg} ) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_articles_types_info( { ID => $FORM{chg}, } );
  }

  _error_show( $Storage );

  $html->tpl_show( _include( 'storage_articles_types', 'Storage' ), { %{$Storage}, %FORM } );

  result_former({
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storage_types_list',
    BASE_FIELDS     => 3,
    DEFAULT_FIELDS  => 'ID,NAME,COMMENTS',
    FUNCTION_FIELDS => 'change' . ((defined( $permissions{4}->{3} )) ? ',del' : ''),
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      'name'     => $lang{NAME},
      'comments' => $lang{COMMENTS},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{TYPE},
      qs      => $pages_qs,
      ID      => 'STORAGE_TYPES',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#***********************************************************
=head2 suppliers_main() - Suppliers

=cut
#***********************************************************
sub suppliers_main{

  if ( $FORM{message} ) {
    $html->message( 'info', $lang{INFO}, "$FORM{message}" );
  }
  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{DATE} = '0000-00-00';


  $Storage->{OKPO_PATTERN} = $conf{STORAGE_OKPO_PATTERN} || '\d{8,10}';
  $Storage->{INN_PATTERN} = $conf{STORAGE_INN_PATTERN}   || '\d{12,12}';
  $Storage->{MFO_PATTERN} = $conf{STORAGE_MFO_PATTERN}   || '\d{6,6}';


  if ( $FORM{del} ) {
    my $list = $Storage->storage_incoming_articles_list( { SUPPLIER_ID => $FORM{del}, COLS_NAME => 1 } );
    _error_show( $Storage );

    if ( defined( $list->[0]->{id} ) ) {
      $html->message( 'warn', $lang{INFO}, "$lang{CANT_DELETE_ERROR3}" );
    }
    else {
      $Storage->suppliers_del( { ID => $FORM{del} } );
      if ( !$Storage->{errno} ) {
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
      }
    }
  }
  elsif ( $FORM{change} ) {
    if ( $FORM{NAME} ) {
      $Storage->suppliers_change( { %FORM } );
      if ( !$Storage->{errno} ) {

        #$html->message('info', $lang{INFO}, "$lang{CHANGED}");
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{CHANGED}",
          }
        );
      }
    }
    else {
      $Storage->{ACTION} = 'change';
      $Storage->{ACTION_LNG} = $lang{CHANGE};
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARE_REQUIRED}" );
      $html->tpl_show( _include( 'storage_suppliers_form', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{add} ) {
    if ( $FORM{NAME} ) {
      $Storage->suppliers_add( { %FORM } );
      if ( !$Storage->{errno} ) {
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{ADDED}",
          }
        );
      }
    }
    else {
      $html->message( 'info', $lang{INFO}, "$lang{FIELDS_FOR_NAME_ARE_REQUIRED}" );
      $html->tpl_show( _include( 'storage_suppliers_form', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{chg} ) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->suppliers_info( { ID => $FORM{chg} } );
    if ( !$Storage->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
  }
  if ( !$FORM{add} and !$FORM{change} ) {
    $html->tpl_show( _include( 'storage_suppliers_form', 'Storage' ), $Storage );
  }
  my $table = $html->table(
    {
      width   => '100%',
      caption => $lang{SUPPLIERS},
      title   => [ $lang{NAME}, $lang{PHONE}, 'email', 'icq', $lang{SITE}, $lang{DIRECTOR}, $lang{BILL}, '-' ],
      pages   => $Storage->{TOTAL},
      ID      => 'STORAGE_ID'
    }
  );

  my $list = $Storage->suppliers_list( { COLS_NAME => 1 } );
  _error_show( $Storage );

  foreach my $line ( @{$list} ) {
    $table->addrow(
      $line->{name},
      $line->{phone},
      $line->{email},
      $line->{icq},
      $line->{site},
      $line->{director},
      $line->{mfo},
      $html->button( $lang{INFO}, "index=$index&chg=$line->{id}", { class => 'change' } )
        . ' ' . ((defined( $permissions{0}->{5} ))                                     ? $html->button( $lang{DEL},
          "index=$index&del=$line->{id}",
          { MESSAGE => "$lang{DEL} $lang{SUPPLIER} $line->{name}?", class => 'del' } ) : '')
    );
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 storage_storages($attr) - Shows result former for list of storages

=cut
#**********************************************************
sub storage_storages{
  #my ($attr) = @_;

  if ( $FORM{message} ) {
    $html->message( 'info', $lang{INFO}, "$FORM{message}" );
  }

  $Storage->{ACTION} = 'add';
  $Storage->{ACTION_LNG} = $lang{ADD};
  $Storage->{ADD_DATE} = '0000-00-00';

  if ( $FORM{add} ) {
    if ( $FORM{NAME} && $FORM{NAME} ne '' ) {

      $Storage->storage_add( { %FORM } );
      if ( !$Storage->{errno} ) {
        $html->tpl_show(
          _include( 'storage_redirect', 'Storage' ),
          {
            SECTION => '',
            MESSAGE => "$lang{ADDED}",
          }
        );
      }
    }
    else {
      $html->message( 'info', $lang{INFO}, "$lang{ERR_WRONG_DATA}" );
      $html->tpl_show( _include( 'storage_storages', 'Storage' ), { %{$Storage}, %FORM } );
    }
  }
  elsif ( $FORM{del} && $FORM{COMMENTS} ) {
    $Storage->storage_incoming_articles_list( { STORAGE_ID => $FORM{del}, COLS_NAME => 1 } );
    if ( $Storage->{TOTAL} ) {
      $html->message( 'warn', $lang{INFO}, "$lang{CANT_DELETE_ERROR1} " );
    }
    else {
      $Storage->storage_del( { ID => $FORM{del} } );
      if ( !$Storage->{errno} ) {
        $html->message( 'info', $lang{INFO}, "$lang{DELETED}" );
      }
    }
  }
  elsif ( $FORM{change} ) {
    $Storage->storage_change( { %FORM } );
    if ( !$Storage->{errno} ) {
      $html->tpl_show(
        _include( 'storage_redirect', 'Storage' ),
        {
          SECTION => '',
          MESSAGE => "$lang{CHANGED}",
        }
      );
    }
  }
  elsif ( $FORM{chg} ) {
    $Storage->{ACTION} = 'change';
    $Storage->{ACTION_LNG} = $lang{CHANGE};
    $Storage->storage_info( { ID => $FORM{chg} } );
    if ( !$Storage->{errno} ) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGING}" );
    }
  }

  if ( !$FORM{add} and !$FORM{change} ) {
    $html->tpl_show( _include( 'storage_storages', 'Storage' ), $Storage );
  }

  result_former( {
    INPUT_DATA      => $Storage,
    FUNCTION        => 'storages_list',
    BASE_FIELDS     => 3,
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id       => '#',
      name     => $lang{NAME},
      comments => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{STORAGE}",
      qs      => $pages_qs,
      ID      => 'STORAGES_LIST',
      EXPORT  => 1,
      #MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 storage_measures()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub storage_properties {
  my %STORAGE_PROPERTY_TEMPLATE = (
    BTN_NAME  => "add",
    BTN_VALUE => $lang{ADD}
  );

  if ($FORM{add}) {
    $Storage->storage_property_add({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{change}) {
    $Storage->storage_property_change({ %FORM });
    _error_show($Storage);
  }
  elsif ($FORM{del}) {
    $Storage->storage_property_value_list({PROPERTY_ID => $FORM{del}});

    if($Storage->{TOTAL} > 0){
      $html->message( 'warning', $lang{INFO}, "$lang{CANT_DELETE_ERROR6} " );
    }
    else{
      $Storage->storage_property_delete({ ID => $FORM{del} });
      _error_show($Storage);
    }
  }

  if ($FORM{chg}) {
    $STORAGE_PROPERTY_TEMPLATE{BTN_NAME} = "change";
    $STORAGE_PROPERTY_TEMPLATE{BTN_VALUE} = $lang{CHANGE};

    my $property_info = $Storage->storage_property_info({
      ID         => $FORM{chg},
      NAME       => '_SHOW',
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });
    _error_show($Storage);

    if ($property_info) {
      @STORAGE_PROPERTY_TEMPLATE{keys %$property_info} = values %$property_info;
    }

  }

  $html->tpl_show(
    _include('storage_property', 'Storage'),
    {
      %STORAGE_PROPERTY_TEMPLATE
    }
  );

  result_former(
    {
      INPUT_DATA      => $Storage,
      FUNCTION        => 'storage_property_list',
      BASE_FIELDS     => 0,
      DEFAULT_FIELDS  => "ID, NAME, COMMENTS",
      FUNCTION_FIELDS => 'change,del',
      EXT_TITLES      => {
        'id'     => "ID",
        'name'   => $lang{NAME},
        'comments' => $lang{COMMENTS},
      },
      TABLE           => {
        width   => '100%',
        caption => $lang{PROPERTY},
        qs      => $pages_qs,
        ID      => 'STORAGE_PROPERTY',
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
      MODULE          => 'Storage',
      TOTAL           => "TOTAL:$lang{TOTAL}",
    }
  );
}

#**********************************************************
=head2 _property_list_html()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _property_list_html {
  my ($incoming_articles_id) = @_;

  my $properties_list = $Storage->storage_property_list({
    NAME          => '_SHOW',
    COMMENTS      => '_SHOW',
    SHOW_ALL_COLS => 1,
    COLS_NAME     => 1,
    COLS_UPPER    => 1,
    DESC          => 'desc',
  });

  my $properties_values = $Storage->storage_property_value_list({
    STORAGE_INCOMING_ARTICLES_ID => $incoming_articles_id || 0,
    VALUE         => '_SHOW',
    PROPERTY_ID   => '_SHOW',
    COLS_NAME     => 1,
    COLS_UPPER    => 1,
    DESC          => 'desc',
  });

  my %PROPERTIES_VALUES = ();
  foreach my $property_value (@$properties_values){
    $PROPERTIES_VALUES{$property_value->{property_id}} = $property_value->{value};
  }

  my $properties_html = '';
  foreach my $property (@$properties_list){
    $properties_html .= "<div class='form-group'>";
    $properties_html .= "<label class='col-md-3 control-label'>";
    $properties_html .= $property->{name};
    $properties_html .= "</label>";
    $properties_html .= "<div class='col-md-9'>";
    $properties_html .= "<input type='text' name='PROPERTY_$property->{id}' class='form-control' value='" . ($PROPERTIES_VALUES{$property->{id}} || '') . "'>";
    $properties_html .= "</div>";
    $properties_html .= "</div>";
  }

  return $properties_html;
}

1;