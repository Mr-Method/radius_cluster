use strict;
use warnings FATAL => 'all';
use Abills::Base qw(_bp load_pmodule);
use Dv_Sessions;

our Equipment $Equipment;

our(
  $db,
  $html,
  %conf,
  %lang,
  $admin,
);


#********************************************************
=head2 network_map($attr)

=cut
#********************************************************
sub network_map {

  my %nodes = ();
  my %edges = ();

  my $nas_list = $Equipment->_list({
    NAS_IP    => '_SHOW',
    NAS_NAME  => '_SHOW',
    NAS_ID    => '_SHOW',
    STATUS    => '_SHOW',
    PORTS     => '_SHOW',
    PAGE_ROWS => 9999,
    COLS_NAME => 1
  });
  _error_show($Equipment);

  foreach my $line (@$nas_list){
    my $linked = $nodes{$line->{nas_id}}->{'linked'};
    $nodes{$line->{nas_id}} = {
      'name'      => $line->{nas_name},
      'ip'        => $line->{nas_ip},
      'state'     => $line->{status},
      'ports'     => $line->{ports},
      'type'      => 'server',
    };
    if ($linked) {$nodes{$line->{nas_id}}->{'linked'} = 1};


    my $uplink_ports = $Equipment->port_list({
      NAS_ID    => $line->{nas_id},
      UPLINK    => '!0',
      COLS_NAME => 1
    });
    _error_show($Equipment);

    if ($uplink_ports && ref $uplink_ports eq 'ARRAY'){
      foreach (@$uplink_ports){
        $edges{$line->{nas_id}}->{$_->{uplink}} = {'length' => '3'};
        $nodes{$line->{nas_id}}->{'linked'} = 1;
        $nodes{$_->{uplink}}->{'linked'} = 1;
      }
    }
  }

  my $Sessions = Dv_Sessions->new($db, $admin, \%conf);
  my $list = $Sessions->online_count({ COLS_NAME => 1 });
  foreach my $line (@$list) {
    $nodes{$line->{nas_id}}->{'online'} = $line->{nas_total_sessions};
    $nodes{$line->{nas_id}}->{'zapped'} = $line->{nas_zaped};
  }

  foreach (keys %nodes) {
    unless ($nodes{$_}->{'linked'}) {
    delete $nodes{$_}
    }
  }

  my %rec_hash = ('nodes' => \%nodes, 'edges' => \%edges);

  load_pmodule('JSON');
  JSON->import();
  my $json_string = JSON::to_json(\%rec_hash);

  my $status_hash = JSON::to_json({
          0 => $lang{ENABLE},
          1 => $lang{DISABLE},
          2 => $lang{NOT_ACTIVE},
          3 => $lang{ERROR},
          4 => $lang{BREAKING}
  });

  $html->tpl_show( _include( 'netmap', 'Equipment'), {
                  DATA              => $json_string,
                  STATUS_LANG_HASH  => $status_hash
                  },
  );

  return 1;
}

#********************************************************
=head2 user_route($attr)

=cut
#********************************************************
sub user_route {
  my ($attr) = @_;
  $attr //= {};
  my $user_uid = $attr->{UID} || $FORM{UID} || return '';

  my %nodes = ();
  my %edges = ();

  my $user_node = $Equipment->port_list({
    UID       => $user_uid,
    NAS_ID    => '_SHOW',
    UPLINK    => '_SHOW',
    LOGIN     => '_SHOW',
    #  FIO       => '_SHOW',
    COLS_NAME => 1
  });
  _error_show($Equipment);

  unless ( $user_node && ref $user_node eq 'ARRAY' ) {
    $html->message('err', $lang{ERROR}, "user is not assigned to any port");
    return 1;
  };
  my $user_nas = $user_node->[0]->{nas_id} || 0;
  my $user_login = $user_node->[0]->{login};
  my $current_nas = $user_node->[0]->{nas_id};
  $nodes{'0'} = {
    'name' => $user_login,
    'type' => 'user',
  };
  $edges{'0'}->{$user_nas} = { 'length' => '0.5' };

  while ( 42 ) {
    my $nas_info = $Equipment->_list({
      NAS_ID    => $current_nas,
      NAS_NAME  => '_SHOW',
      NAS_IP    => '_SHOW',
      STATUS    => '_SHOW',
      COLS_NAME => 1
    });

    unless ( $nas_info && ref $nas_info eq 'ARRAY' ) {
      $html->message('err', $lang{ERROR}, "NAS_NOT_FOUND");
      return 1;
    }

    if ($nas_info->[0] && $nodes{$nas_info->[0]->{nas_id}} ) {
      last;
    }

    if($nas_info->[0]->{nas_id}) {
      $nodes{$nas_info->[0]->{nas_id}} = {
        'name'  => $nas_info->[0]->{nas_name},
        'ip'    => $nas_info->[0]->{nas_ip},
        'state' => $nas_info->[0]->{status},
        'type'  => 'server',
      };
    }

    my $uplink_port = $Equipment->port_list({
      NAS_ID    => $current_nas,
      UPLINK    => '!0',
      COLS_NAME => 1
    });

    unless ( $uplink_port && ref $uplink_port eq 'ARRAY' ) {last;}

    if($current_nas && $uplink_port->[0] && $uplink_port->[0]->{uplink}) {
      $edges{$current_nas}->{$uplink_port->[0]->{uplink}} = { 'length' => '1' };
    }

    $current_nas = $uplink_port->[0]->{uplink};
  }

  my %rec_hash = ('nodes' => \%nodes, 'edges' => \%edges);

  load_pmodule('JSON');
  JSON->import();
  my $json_string = JSON::to_json(\%rec_hash);
  my $status_hash = JSON::to_json({
    0 => $lang{ENABLE},
    1 => $lang{DISABLE},
    2 => $lang{NOT_ACTIVE},
    3 => $lang{ERROR},
    4 => $lang{BREAKING}
  });

  $html->tpl_show(_include('netmap', 'Equipment'), {
    DATA             => $json_string,
    STATUS_LANG_HASH => $status_hash
  });

  return 1;
}

1;