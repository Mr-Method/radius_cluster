package Portal;

=head1 NAME 

  Portal - internet providers Portal site

=head1 SYNOPSIS

  use Portal;

  my $Portal = Portal->new($db, $admin, \%conf);

=cut

use strict;
our $VERSION = 2.00;
use parent 'main';

my ($admin, $CONF);
#my ($SORT, $DESC, $PG, $PAGE_ROWS);

#**********************************************************
=head2 function new() - add TP\'s information to datebase

  Returns:
    $self object

  Examples:
    my $Portal = Portal->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new{
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = { };

  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 function portal_menu_add() - add menu section

  Arguments:
    $attr
      id     - menu identifier in table;
      name   - section name;
      url    - url for redirect from menu;
      date   - date section add;
      status - 1: show; 0:hide;

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_add({%FORM});

=cut
#**********************************************************
sub portal_menu_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'portal_menu', { %{$attr}, DATE => 'now()' } );

  return 0;
}

#**********************************************************
=head2 function portal_menu_list() - get menu section list

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Portal->portal_menu_list({COLS_NAME=>1});

=cut
#**********************************************************
sub portal_menu_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ( defined( $attr->{ID} ) ){
    push @WHERE_RULES, "id='$attr->{ID}'";
  }

  if ( $attr->{NOT_URL} ){
    push @WHERE_RULES, "url=''";
  }

  if ( $attr->{MENU_SHOW} ){
    push @WHERE_RULES, "status=1";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query2(
    "SELECT id,
                name,
                url,
                DATE(date) AS date,
                status
                FROM portal_menu
                $WHERE
                ORDER BY $SORT $DESC;",
    undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 function portal_menu_del() - delete menu section

  Arguments:
    $attr

  Returns:

  Examples:
    $Portal->portal_menu_del({ ID => 1 });

=cut
#**********************************************************
sub portal_menu_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'portal_menu', $attr );

  return $self->{result};
}

#**********************************************************
=head2 function portal_menu_info() - get information aboutn menu section

  Arguments:
    $attr
      id  - section identifier

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_info({ ID => 1 });

=cut
#**********************************************************
sub portal_menu_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM portal_menu WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function portal_menu_change() - change section information in datebase

  Arguments:
    $attr
      id     - menu identifier in table;
      name   - section name;
      url    - url for redirect from menu;
      date   - date section add;
      status - 1: show; 0:hide;

  Returns:
    $self object

  Examples:
    $Portal->portal_menu_change({%FORM});

=cut
#**********************************************************
sub portal_menu_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'portal_menu',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 function portal_article_add() - add article

  Arguments:
    $attr
      id                - article's identifier
      title             - article's title
      short_description - article's short description
      content           - article's content
      status            - 0:hide article; 1:show article;
      on_main_page      - 1:on main page; 0:on subpage;
      date              - date for post this article
      portal_menu_id    - number of menu section to show

  Returns:
    $self object

  Examples:
    $Portal->portal_article_add({%FORM});

=cut
#**********************************************************
sub portal_article_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'portal_articles', $attr );

  return 0;
}

#**********************************************************
=head2 function portal_articles_list() - get articles list

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my $list = $Portal->portal_articles_list({COLS_NAME=>1});

=cut
#**********************************************************
sub portal_articles_list{
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'date';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : 'desc';

  if ( defined( $attr->{ID} ) ){
    push @WHERE_RULES, "pa.id='$attr->{ID}'";
  }
  if ( defined( $attr->{ARTICLE_ID} ) ){
    push @WHERE_RULES, "pa.portal_menu_id='$attr->{ARTICLE_ID}' and pa.status = 1";
  }
  if ( defined( $attr->{MAIN_PAGE} ) ){
    push @WHERE_RULES, "pa.on_main_page = 1 and pa.status = 1";
  }
  if ( defined( $attr->{ARCHIVE} ) ){
    push @WHERE_RULES, "pa.archive = 1";
  }

#   if(defined ( $attr->{DOMAIN} ) && $attr->{DOMAIN} > 0){
# push @WHERE_RULES, "pa.domain = $attr->{DOMAIN}";
#   }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  $self->query2(
    "SELECT   pa.id,
                pa.title,
                pa.short_description,
                pa.content,
                pa.status,
                pa.on_main_page,
                pa.archive,
                pa.importance,
                pa.gid,
                pa.domain_id,
                pa.tags,
                pa.street_id,
                DATE(pa.end_date) as end_date,
                UNIX_TIMESTAMP(pa.end_date) as etimestamp,
                UNIX_TIMESTAMP(pa.date) as utimestamp,
                pa.portal_menu_id,
                pm.name,
                ds.name as dis_name,
                st.name as st_name,
                gp.name as gp_name,
                tg.name as tag_name,
                DATE(pa.date) as date
                FROM portal_articles AS pa
                LEFT JOIN portal_menu pm ON (pm.id=pa.portal_menu_id)
                LEFT JOIN districts ds ON (ds.id=pa.district_id)
                LEFT JOIN streets st ON (st.id=pa.street_id)
                LEFT JOIN groups gp ON (gp.gid=pa.gid)
                LEFT JOIN tags tg ON (tg.id=pa.tags)
                $WHERE
                ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 function portal_article_del() - delete article

  Arguments:
    $attr

  Returns:

  Examples:
    $Portal->portal_article_del({ ID => 1 });

=cut
#**********************************************************
sub portal_article_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'portal_articles', $attr );

  return $self->{result};
}

#**********************************************************
=head2 function portal_article_info() - get information aboutn article

  Arguments:
    $attr
      id  - section identifier

  Returns:
    $self object

  Examples:
    $Portal->portal_article_info({ ID => 1 });

=cut
#**********************************************************
sub portal_article_info{
  my $self = shift;
  my ($attr) = @_;

  $self->query2(
    "SELECT * FROM portal_articles AS pa
      WHERE pa.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function portal_article_change() - change section information in datebase

  Arguments:
    $attr
      id                - article's identifier
      title             - article's title
      short_description - article's short description
      content           - article's content
      status            - 0:hide article; 1:show article;
      on_main_page      - 1:on main page; 0:on subpage;
      date              - date for post this article
      portal_menu_id    - number of menu section to show

  Returns:
    $self object

  Examples:
    $Portal->portal_article_change({%FORM});

=cut
#**********************************************************
sub portal_article_change{
  my $self = shift;
  my ($attr) = @_;

  if ( !$attr->{ON_MAIN_PAGE} ){
    $attr->{ON_MAIN_PAGE} = 0;
  }

  if ( !$attr->{GID} ){
    $attr->{GID} = 0;
  }

  if ( !$attr->{TAGS} ){
    $attr->{TAGS} = 0;
  }

  if ( !$attr->{DISTRICT_ID} ){
    $attr->{DISTRICT_ID} = 0;
  }

  if ( !$attr->{STREET_ID} ){
    $attr->{STREET_ID} = 0;
  }

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'portal_articles',
      DATA         => $attr,
    }
  );

  return $self;
}

1