package Export_redmine;

=head1 NAME

  Export to redmine

=head1 VERSION

  VERSION: 1.16

  API:
    http://www.redmine.org/projects/redmine/wiki/Rest_api

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(load_pmodule2);
use Abills::Fetcher;

our $VERSION = 1.16;

my $MODULE = 'Export_redmine';
my ($json);
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };
  bless($self, $class);

  load_pmodule2('JSON');

  $json = JSON->new->allow_nonref;

  $self->{api_url}       = ($CONF->{MSGS_REDMINE_APIURL}) ? $CONF->{MSGS_REDMINE_APIURL} : ''; 
  $self->{api_login}     = ($CONF->{MSGS_REDMINE_LOGIN}) ? $CONF->{MSGS_REDMINE_LOGIN} : '';
  $self->{api_passwd}    = ($CONF->{MSGS_REDMINE_PASSWORD}) ? $CONF->{MSGS_REDMINE_PASSWORD} : '';
  $self->{api_key}       = ($CONF->{MSGS_REDMINE_APIKEY}) ? $CONF->{MSGS_REDMINE_APIKEY} : '';
  $self->{debug}         = $CONF->{MSGS_REDMINE_DEBUG};
  $self->{SERVICE_NAME}  = 'Redmine';
  $self->{VERSION}       = $VERSION;
  return $self;
}

#**********************************************************
=head2 task_list() list of tasks

=cut
#**********************************************************
sub task_list {
  my $self = shift;
  #my ($attr) = @_;

  $self->send_request({
                        ACTION => "issues.json",
                      });

  return $self;
}

#**********************************************************
=head2 export_task($attr) list of tasks
  Attributes:
    $attr
      ID
      SUBJECT
      MESSAGE
      PRIORITY

=cut
#**********************************************************
sub export_task {
  my $self = shift;
  my ($attr) = @_;

  my $priority = $attr->{PRIORITY} || 2;

  my $data = qq/{
  "issue": {
    "project_id": 1,
    "subject": "# $attr->{ID} $attr->{SUBJECT}",
    "priority_id": $priority,
    "notes": "ABillS",
    "description": "$attr->{MESSAGE}"
  }
  }/;

  $self->send_request({
                        ACTION  => "issues.json",
                        BIN_DATA=> $data,
                        COMMAND => 'POST',
                      });

  return $self;
}

#**********************************************************
=head2 send_request()

=cut
#**********************************************************
sub send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{api_url};

  delete($self->{errno});
  delete($self->{error});
  delete($self->{errstr});

  if ($attr->{ACTION}){
    $request_url .= "$attr->{ACTION}";
  }

  my @headers = ('Content-Type: application/json');

  if ($self->{api_key}) {
    push @headers, "X-Redmine-API-Key: $self->{api_key}";
  }

  my $result = web_request($request_url, {
    BIN_DATA      =>  $attr->{BIN_DATA},
    DEBUG         =>  3, # (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug},
    CURL          =>  1,
    HEADERS       =>  \@headers,
    REQUEST_COUNT =>  $self->{request_count},
    CURL_OPTIONS  =>  ($attr->{COMMAND}) ? "-X $attr->{COMMAND}" : undef,
    TPL_DIR       =>  $CONF->{TPL_DIR}
  });

  $result = $attr->{_RESULT} if ($attr->{_RESULT}); 

  if ($result =~ /API not enabled/) {
    $self->{errno}=3;
    $self->{error}=3;
    $self->{errstr}="API Not enabled";
    return $result;
  }
  elsif($result eq 'Timeout') {
    $self->{errno}=50;
    $self->{error}=50;
    $self->{errstr}="Timeout";
    return $result;
  }
  elsif ($result =~ /Not Found/) {
    $self->{errno}=4;
    $self->{error}=4;
    $self->{errstr}="Not Found";
    return $result;
  }

  return if (! $result);

  my $perl_scalar = $json->decode( $result );

  if($perl_scalar->{status} && $perl_scalar->{status} eq 'ERROR') {
    $self->{errno}=1;
    $self->{error}=1;
    $self->{errstr}="$perl_scalar->{error}";
  }

  $self->{RESULT}=$perl_scalar;
 
  return $result;
}

1
