#! /usr/bin/perl -w
=head1 NAME

  Abills::Nas::Mikrotik::API

=SYNOPSYS

  Forked from https://raw.githubusercontent.com/efaden/MikroTikPerl/

  This module is not a part of ABillS

=head2 VERSION

  VERSION 0.1

=head2 AUTHOR

  Eric Faden (efaden@gmail.com)

=head2 LICENSE

  Released Under Creative Commons License

=head2 ORIGINAL HEADER

  # MikroTik::API.pm
  # Version 0.1
  # By Eric Faden (efaden@gmail.com)

  # Fork of MikroTik-Perl-API
  # From https://github.com/ellocofray/mikrotik-perl-api

  # Released Under Creative Commons License

=cut
package Abills::Nas::Mikrotik::API;
use strict;
use warnings 'FATAL' => 'all';

our ( $VERSION );

$VERSION = '0.01';

my $debug = 0;
my $DEBUG_ARGS = { TO_CONSOLE => 1 };
our $errstr = '';

use Abills::Base qw /_bp cmd/;
use IO::Socket;
use Digest::MD5;

my ($sock);

use constant {
  LIST_REFS => {
    'system'                 => [ "/system/resource/print" ],
    'dhcp_leases'            => [ "/ip/dhcp-server/lease/print" ],
    'dhcp_leases_generated'  => [ "/ip/dhcp-server/lease/print", { }, { comment => 'ABillS generated' } ],
    'dhcp_servers'           => [ "/ip/dhcp-server/print" ],
    'addresses'              => [ "/ip/address/print" ],
    'dhcp_networks'          => [ "/ip/dhcp-server/networks/print" ],
    'interfaces'             => [ "/interface/print" ],
    'users'                  => [ "/user/print" ],
    'adverts'                => [ '/ip/hotspot/user/profile/print', { }, { name => "default" } ],
    'ppp_accounts'           => [ '/ppp/secret/print' ],
    'firewall_nat'           => [ '/ip/firewall/nat/print' ],
    'queue_tree'             => [ '/queue/tree/print' ],
    'queue_type'             => [ '/queue/type/print' ],
    'queue_simple'           => [ '/queue/simple/print' ],
    'firewall_address__list' => [ '/ip/firewall/address-list/print' ],
    'firewall_filter_list'   => [ '/ip/firewall/filter/print' ],
    'log_print'              => [ '/log/print' ],
    
  }
};


#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($host, $CONF, $attr) = @_;
  
  my $self = { };
  bless( $self, $class );
  
  $host->{nas_mng_ip_port} = $host->{nas_mng_ip_port} || $host->{NAS_MNG_IP_PORT} || 0;
  $self->{admin} = $host->{nas_mng_user} || $host->{NAS_MNG_USER} || 'abills_admin';
  $self->{password} = $host->{nas_mng_password} || $host->{NAS_MNG_PASSWORD} || '';
  
  return 0 unless ($host->{nas_mng_ip_port} && $self->{admin} && $self->{password});
  
  my ($nas__mng_ip, $coa_port, $nas_port) = split( ":", $host->{nas_mng_ip_port} );
  
  $self->{host} = $nas__mng_ip || return 0;

  #  $self->{port} = $nas_port || $coa_port || '8728';
  $self->{port} = '8728';
  
  
  # Debug output params
  $self->{FROM_WEB} = $attr->{FROM_WEB};
  if ( $attr->{DEBUG} ) {
    $self->{debug} = $attr->{DEBUG};
    if ( $attr->{FROM_WEB} ) {
      $DEBUG_ARGS = { TO_WEB_CONSOLE => 1 };
    }
  }
  else {
    $self->{debug} = 0;
  }
  
  # Allowing to use custom message functions
  if ( $attr->{MESSAGE_CALLBACK} && ref $attr->{MESSAGE_CALLBACK} eq 'CODE' ) {
    $self->{message_cb} = $attr->{MESSAGE_CALLBACK};
  }
  else {
    $self->{message_cb} = sub { print shift };
  }
  # Allowing to use custom error message functions
  if ( $attr->{ERROR_CALLBACK} && ref $attr->{ERROR_CALLBACK} eq 'CODE' ) {
    $self->{error_cb} = $attr->{ERROR_CALLBACK};
  }
  else {
    $self->{error_cb} = sub { print shift };
  }
  return $self;
}


#**********************************************************
=head2 execute($cmd, $attr) - Execute command in remote console

  Arguments:
    $cmd - string  or array of strings
    $attr - hash_ref
      SAVE_TO         - filename to save output
      SKIP_ERROR      - do not finish execution if error on one of commands


  Returns:
    1

=cut
#**********************************************************
sub execute {
  my $self = shift;
  my ($cmd, $attr) = @_;
  
  if ( !$self->{logined} && !$self->check_access() && !$cmd ) {
    return 0;
  }
  
  die "Bad command format at " . join(', ', caller) unless (ref($cmd) eq 'ARRAY');
  
  # Single API command is array [ $command, %attributes, %search_query ]
  # So multiple commands are array of arrays
  
  # If pack of commands
  if ( $cmd->[0] && ref $cmd->[0] eq 'ARRAY' ) {
    foreach my $cmd_arr ( @{ $cmd } ) {
      
      my ($res, @results) = $self->mtik_query(@{$cmd_arr});
      
      # Handle result
      if ( $res == 1 ) {
        #        _bp('',[ $cmd_arr, \@results ], {TO_CONSOLE => 1} );
        $self->{success_cb}( @results ) if (defined $self->{success_cb});
      }
      else {
        print " \n Error executing '$cmd_arr->[0]' : $errstr \n" if ($self->{debug} > 1);
        
        if ( $attr->{SKIP_ERROR} ) {
          next
        }
        else {
          $self->{error_cb}( $cmd_arr->[0], $errstr );
          return 0;
        };
        
      }
    }
    return 1;
  }
  else {
    my ($res, @results) = $self->mtik_query(@{$cmd});
    
    if ( $res == 1 ) {
      return \@results;
    }
  }
  
  return 0;
}


#**********************************************************
=head2 has_list_command($list_name) - checks if object has predefined command for list

  Arguments:
    $list_name -
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_list_command {
  return unless $_[1];
  return exists LIST_REFS->{$_[1]} && defined LIST_REFS->{$_[1]};
}

#**********************************************************
=head2 get_list($command, $attr)

  Arguments:
    $command
    $attr - hash_ref

  Returns:
    arr_ref

=cut
#**********************************************************
sub get_list {
  my $self = shift;
  my ($list_name, $attr) = @_;
  
  my $cmd = LIST_REFS->{$list_name};
  return -1 unless ($cmd);
  
  if ( $attr ) {
    # Modifying attributes cmd part
    $cmd->[1] = $attr;
  }
  
  return $self->execute( $cmd, $attr );
}

#**********************************************************
=head2 check_access() - checks if mikrotik is accessible

  Returns:
    boolean

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  
  return 1 if $self->{logined};
  
  my %self = %{$self};
  
  eval {
    $self->{logined} = $self->login(@self{'host', 'admin', 'password', 'port'});
  };
  if ($@){
    $errstr = $@;
  }
  
  return $self->{logined};
}

#**********************************************************
=head2 upload_key($attr) - Uploads key without password

  Arguments:
    $attr - hash_ref
      ADMIN_NAME    - admin to upload key for
      SYSTEM_ADMIN  - current active admin
      SYSTEM_PASSWD - current password

  Returns:
    1 - if success

=cut
#**********************************************************
sub upload_key {
  my $self = shift;
  my ( $attr ) = @_;
  
  my $admin_name = $attr->{ADMIN} || 'abills_admin';
  my $system_adm = $attr->{SYSTEM_ADMIN} || 'admin';
  my $system_pas = $attr->{SYSTEM_PASSWD} || '';
  
  $self->logout();
  $self->login($self->{host}, $system_adm, $system_pas, 8728);
  
  my $key_type = 'rsa';
  
  my $version_res = $self->execute(['/system/package/print', undef, { name => 'security'}]);
  if ($version_res && ref $version_res eq 'ARRAY' && $version_res->[0]){
    my $version = $version_res->[0]{version};
    my ($main_1, $main_2, $minor) = split('\.', $version);
    
    if ($main_2 && $main_2=~/^(\d+)/){
      $main_2 = $1 || 33;
    }
    else {
      $main_2 = 33;
    }
    
    if ($main_1 <= 6 && $main_2 < 32 ){
      $key_type = 'dsa';
    }
  }
  
  our $base_dir;
  $base_dir //= '/usr/abills';
  my $cert_dir = $base_dir . '/Certs/';
  my $cert_filename = 'id_' . $key_type . '.' . $admin_name . '.pub';
  my $cert_file = $cert_dir . $cert_filename;
  
  # Check key file exists
  if ( ! -f $cert_file ) {
    
    my $cmd = qq { $base_dir/misc/certs_create.sh ssh $admin_name SSH_KEY_TYPE=$key_type SKIP_CERT_UPLOAD -silent };
    eval {
      cmd( $cmd, { SHOW_RESULT => 1 } );
    };
    if ($!){
      $self->{error_cb}->( 'SSH Key upload', "Can't generate SSH certificate. $!");
      return 0;
    }
  }
  
  # Read key
  open (my $cert_file_fh, '<', $cert_file) or do {
    $self->{error_cb}( 'SSH Key upload', "Cannot open $cert_file : $! \n" );
    return 0;
  };
  
  my $content = '';
  while (my $string = <$cert_file_fh>){
    chomp($string);
    $content .= $string;
  }
  
  # Check user exists
  my @add_user_commands = ();
  my $users = $self->get_list( 'users' );
  if ( $users && scalar @{$users} > 0 ) {
    my $has_user = 0;
    foreach my $user ( @{$users} ) {
      if ( $user->{name} eq $admin_name ) {
        $has_user = 1;
        last;
      }
    }
    if ( !$has_user ) {
      my $password = join('', map{('a' .. 'z', 'A' .. 'Z', 0 .. 9)[rand 62]} 0 .. 16);
      @add_user_commands = (
        [ '/user add', { name => $admin_name, group => 'write', password => $password } ]
      );
    }
  }
  
  $self->execute(
    [
      [ '/file print', { file => "$cert_filename\.txt" } ],
      [ '/file set', { 'contents' => $content, '.id' => "$cert_filename\.txt" }, { } ],
      @add_user_commands,
      [ '/user ssh-keys import', { 'public-key-file' => "$cert_filename\.txt", user => $admin_name } ]
    ],
    {
      SKIP_ERROR => 1
    }
  );
  
  # Must wait before Mikrotik saves file
  sleep 1;
  
  $self->execute(
    [
      [ '/user ssh-keys import', { 'public-key-file' => "$cert_filename\.txt", user => $admin_name } ]
    ],
    {
      SKIP_ERROR => 1
    }
  );
  
  return 1;
}


#**********************************************************
=head2 talk()

=cut
#**********************************************************
sub talk {
  
  #my(@sentence) = shift;
  my ($sentence_ref) = shift;
  my (@sentence) = @{$sentence_ref};
  &_write_sentence(\@sentence);
  my (@reply);
  my (@attrs);
  my ($i) = 0;
  my ($retval) = 0;
  while (($retval, @reply) = &_read_sentence()) {
    
    foreach my $line ( @reply ) {
      if ( $line =~ /^=(\S+)=(.*)/s ) {
        $attrs[$i]->{$1} = $2;
      }
      
    }
    if ( $retval > 0 ) {
      last;
    }
    $i++;
  }
  return ($retval, @attrs);
}

#**********************************************************
=head2 raw_talk()

=cut
#**********************************************************
sub raw_talk {
  my (@sentence) = @{ (shift) };
  &_write_sentence(\@sentence);
  my (@reply);
  my (@response);
  
  my ($retval) = 0;
  while (($retval, @reply) = &_read_sentence()) {
    foreach my $line ( @reply ) {
      push(@response, $line);
    }
    if ( $retval > 0 ) {
      last;
    }
  }
  return ($retval, @response);
}

#**********************************************************
=head2 login($host, $username, $passwd, $port)

=cut
#**********************************************************
sub login {
  my $self = shift;
  my ($host, $username, $passwd, $port) = @_;
  
  if ( !($sock = $self->_mtik_connect($host, $port)) ) {
    return 0;
  }
  $passwd ||= '';
  my (@command);
  push(@command, '/login');
  my ($retval, @results) = &talk(\@command);
  my ($chal) = pack("H*", $results[0]->{'ret'});
  my ($md) = Digest::MD5->new();
  $md->add( chr(0) );
  $md->add( $passwd );
  $md->add( $chal );
  my ($hexdigest) = $md->hexdigest;
  undef(@command);
  push(@command, '/login');
  push(@command, '=name=' . $username);
  push(@command, '=response=00' . $hexdigest);
  ($retval, @results) = &talk(\@command);
  
  if ( $retval > 1 ) {
    $self->{errstr} = $results[0]->{'message'};
    return 0;
  }
  if ( $debug > 0 ) {
    print "Logged in to $host as $username\n";
  }
  return 1;
}

#**********************************************************
=head2 logout()

=cut
#**********************************************************
sub logout {
  my $self = shift;
  if ( $self && ref $self eq __PACKAGE__ ) {
    $self->{logined} = 0;
  }
  close $sock if $sock;
}

#**********************************************************
=head2 get_by_key()

=cut
#**********************************************************
sub get_by_key {
  my ($cmd) = shift;
  my ($id) = shift || '.id';
  $errstr = '';
  my (@command);
  push(@command, $cmd);
  my (%ids);
  my ($retval, @results) = talk(\@command);
  if ( $retval > 1 ) {
    $errstr = $results[0]->{'message'};
    return %ids;
  }
  foreach my $attrs ( @results ) {
    my $key = '';
    foreach my $attr ( keys(%{$attrs}) ) {
      my $val = $attrs->{$attr};
      if ( $attr eq $id ) {
        $key = $val;
        
        #delete(${$attrs}{$attr});
      }
    }
    if ( $key ) {
      $ids{$key} = $attrs;
    }
  }
  return %ids;
}

#**********************************************************
=head2 mtik_cmd()

=cut
#**********************************************************
sub mtik_cmd {
  my ($cmd) = shift;
  my (%attrs) = %{ (shift) };
  
  $errstr = '';
  my (@command);
  
  push(@command, $cmd);
  foreach my $attr ( keys(%attrs) ) {
    push(@command, '=' . $attr . '=' . $attrs{$attr});
  }
  
  my ($retval, @results) = talk(\@command);
  
  if ( $retval > 1 ) {
    $errstr = $results[0]->{'message'};
  }
  
  return ($retval, @results);
}

#**********************************************************
=head2 mtik_query($cmd, \%attrs, \%queries)

=cut
#**********************************************************
sub mtik_query {
  my $self = shift;
  my ($cmd, $attributes_attr, $queries_attr) = @_;
  
  my (%attrs) = %{ $attributes_attr } if ($attributes_attr);
  my (%queries) = %{ $queries_attr } if ($queries_attr);
  
  # Clear global errstr
  $errstr = '';
  my (@command);
  
  $cmd =~ s/^ ?| ?$//g;
  $cmd =~ s/\ +/\//g;
  
  
  if ($cmd && $cmd =~ /(\/numbers=\*?([0-9A-Fa-f]+))$/){
    $attrs{'.id'} = '*'. $2;
    my $remove = quotemeta $1;
    $cmd =~ s/$remove//gm;
  }
  
  push(@command, $cmd);
  
  # If modyfing using name,
  # we first need to get .id of element
  if ( $queries_attr && $attributes_attr && exists $queries{name} && $cmd =~ /\/set$/ ) {
    my $search_cmd = $cmd;
    $search_cmd =~ s/\/set$/\/print/;
    my ($search_ret, @search_res) = $self->mtik_query($search_cmd, { '.proplist' => '.id' },
      { name => $queries{name} });
    if ( $search_ret > 1 ) {
      return ($search_ret, @search_res);
    }
    else {
      $queries{'.id'} = $search_res[0]->{'.id'};
      delete $queries{name};
    }
  }
  
  foreach my $attr ( keys(%attrs) ) {
    push(@command, '=' . $attr . '=' . $attrs{$attr}) if (defined $attrs{$attr});
  }
  
  foreach my $query ( keys(%queries) ) {
    push(@command, '?' . $query . '=' . $queries{$query});
  }
  
  
#  _bp('', \@command, $DEBUG_ARGS);
  
  my ($retval, @results) = talk(\@command);
  if ( $retval > 1 ) {
    $errstr = $results[0]->{'message'};
    _bp('mtik errornous query', { command => \@command, error => $errstr }, $DEBUG_ARGS) if ($self->{debug});
  }
  _bp('results', \@results, $DEBUG_ARGS) if ($self->{debug} > 2);
  _bp('mtik_query1', { command => \@command, error => $errstr }, $DEBUG_ARGS) if ($self->{debug} > 2);
  return ($retval, @results);
}

#**********************************************************
=head2 _mtik_connect()

=cut
#**********************************************************
sub _mtik_connect {
  my $self = shift;
  my ($host, $port) = @_;
  
  $port ||= 8728;
  
  if ( !($host) ) {
    $self->{errstr} = $errstr = "no host!\n";;
    return 0;
  }
  if ( $port eq 8729 ) {
    use IO::Socket::SSL;
    $sock = IO::Socket::SSL->new(
      PeerAddr => $host,
      PeerPort => 8729,
      Proto    => 'tcp'
    ) or die "failed connect or ssl handshake: $!,", &IO::Socket::SSL::errstr, "\n";
  }
  else {
    $sock = IO::Socket::INET->new(
      PeerAddr => $host,
      PeerPort => $port,
      Proto    => 'tcp'
    );
  }
  if ( !($sock) ) {
    $self->{errstr} = $errstr = "no socket :$!\n";
    return 0;
  }
  return $sock;
}

#**********************************************************
=head2 _write_word()

=cut
#**********************************************************
sub _write_word {
  my ($word) = shift;
  &_write_len(length($word));
  print $sock $word;
}

#**********************************************************
=head2 _write_sentence()

=cut
#**********************************************************
sub _write_sentence {
  my ($sentence_ref) = shift;
  my (@sentence) = @{$sentence_ref};
  foreach my $word ( @sentence ) {
    _write_word($word);
    if ( $debug > 2 ) {
      print ">>> $word\n";
    }
  }
  _write_word('');
}

#**********************************************************
=head2 _write_len()

=cut
#**********************************************************
sub _write_len {
  my ($len) = shift;
  if ( $len < 0x80 ) {
    print $sock chr($len);
  }
  elsif ( $len < 0x4000 ) {
    $len |= 0x8000;
    print $sock chr(($len >> 8) & 0xFF);
    print $sock chr($len & 0xFF);
  }
  elsif ( $len < 0x200000 ) {
    $len |= 0xC00000;
    print $sock chr(($len >> 16) & 0xFF);
    print $sock chr(($len >> 8) & 0xFF);
    print $sock chr($len & 0xFF);
  }
  elsif ( $len < 0x10000000 ) {
    $len |= 0xE0000000;
    print $sock chr(($len >> 24) & 0xFF);
    print $sock chr(($len >> 16) & 0xFF);
    print $sock chr(($len >> 8) & 0xFF);
    print $sock chr($len & 0xFF);
  }
  else {
    print $sock chr(0xF0);
    print $sock chr(($len >> 24) & 0xFF);
    print $sock chr(($len >> 16) & 0xFF);
    print $sock chr(($len >> 8) & 0xFF);
    print $sock chr($len & 0xFF);
  }
}

#**********************************************************
=head2 _read_byte()

=cut
#**********************************************************
sub _read_byte {
  my $line;
  $sock->read( $line, 1 );
  return ord($line);
}

#**********************************************************
=head2 _read_len()

=cut
#**********************************************************
sub _read_len {
  if ( $debug > 4 ) {
    print "start read_len\n";
  }
  
  my $len = _read_byte();
  
  if ( ($len & 0x80) == 0x00 ) {
    return $len;
  }
  elsif ( ($len & 0xC0) == 0x80 ) {
    $len &= ~0x80;
    $len <<= 8;
    $len += _read_byte();
  }
  elsif ( ($len & 0xE0) == 0xC0 ) {
    $len &= ~0xC0;
    $len <<= 8;
    $len += _read_byte();
    $len <<= 8;
    $len += _read_byte();
  }
  elsif ( ($len & 0xF0) == 0xE0 ) {
    $len &= ~0xE0;
    $len <<= 8;
    $len += _read_byte();
    $len <<= 8;
    $len += _read_byte();
    $len <<= 8;
    $len += _read_byte();
  }
  elsif ( ($len & 0xF8) == 0xF0 ) {
    $len = _read_byte();
    $len <<= 8;
    $len += _read_byte();
    $len <<= 8;
    $len += _read_byte();
    $len <<= 8;
    $len += _read_byte();
  }
  if ( $debug > 4 ) {
    print "read_len got $len\n";
  }
  return $len;
}

#**********************************************************
=head2 _read_word()

=cut
#**********************************************************
sub _read_word {
  my ($ret_line) = '';
  my ($len) = &_read_len();
  if ( $len > 0 ) {
    if ( $debug > 3 ) {
      print "recv $len\n";
    }
    while (1) {
      my ($line) = '';
      $sock->read( $line, $len );
      
      # append to $ret_line, in case we didn't get the whole word and are going round again
      $ret_line .= $line;
      my $got_len = length($line);
      
      if ( $got_len < $len ) {
        
        # we didn't get the whole word, so adjust length and try again
        $len -= $got_len;
      }
      else {
        # woot woot!  we got the required length
        last;
      }
    }
  }
  return $ret_line;
}

#**********************************************************
=head2 _read_sentence()

=cut
#**********************************************************
sub _read_sentence {
  my ($word);
  my ($i) = 0;
  my (@reply);
  my ($retval) = 0;
  
  while ($word = &_read_word()) {
    if ( $word =~ /!done/ ) {
      $retval = 1;
    }
    elsif ( $word =~ /!trap/ ) {
      $retval = 2;
    }
    elsif ( $word =~ /!fatal/ ) {
      $retval = 3;
    }
    $reply[ $i++ ] = $word;
    if ( $debug > 2 ) {
      print "<<< $word\n";
    }
  }
  return ($retval, @reply);
}

DESTROY {
  logout();
}

=head2 LICENSE

  Attribution-NonCommercial-ShareAlike 4.0 International

  https://github.com/horodchukanton/MikroTikPerl/blob/master/LICENSE

=cut
1;