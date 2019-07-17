package Abills::Nas::Mikrotik::SSH;
use strict;
use warnings FATAL => 'all';
#
#BEGIN{
#  unshift ( @INC, "../../../../" );
#}

use Abills::Base qw(cmd _bp);

use constant {
  parseable_postfix => 'detail',
  generated_comment => 'ABillS generated'
};

use constant {
  LIST_REFS => {
    'dhcp_leases'           => "/ip dhcp-server lease print " . parseable_postfix,
    'dhcp_leases_generated' =>
    "/ip dhcp-server lease print " . parseable_postfix . " where comment=\"" . generated_comment . "\"",

    'dhcp_servers'          => "/ip dhcp-server print " . parseable_postfix,
    'ip_a'                  => "/ip address print " . parseable_postfix,
    'dhcp_networks'         => "/ip dhcp-server networks " . parseable_postfix,
    'interfaces'            => "/interface print " . parseable_postfix,
    'adverts'               => '/ip hotspot user profile print where name="default"',
    'radius'                => '/radius print ' . parseable_postfix
  }
};

my $DEBUG_ARGS = { TO_CONSOLE => 1 };

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $host - NAS Info
    $attr - hash_ref
      ADMIN_NAME    - login for admin with write access (abills_admin)
      IDENTITY_FILE - path to SSH private key (/usr/abills/Certs/id_dsa.$attr->{ADMIN_NAME})
      SSH_PORT      - port for SSH (22)
      SSH_EXECUTIVE - ssh program path (`which ssh`)

  Returns:
    object

=cut
#**********************************************************
sub new($;$) {
  my $class = shift;
  my ($host, $CONF, $attr) = @_;

  my $self = { };
  bless( $self, $class );

  $host->{nas_mng_ip_port} = $host->{nas_mng_ip_port} ? $host->{nas_mng_ip_port}
                                                      : ($host->{NAS_MNG_IP_PORT}) ? $host->{NAS_MNG_IP_PORT}
                                                                                   : 0;

  return 0 unless ($host->{nas_mng_ip_port});

  my ($nas_ip, $coa_port, $ssh_port) = split( ":", $host->{nas_mng_ip_port} );
  $self->{host} = $nas_ip || return 0;
  $self->{ssh_port} = $ssh_port || $coa_port || 22;

  $self->{admin} = $host->{NAS_MNG_USER} || 'abills_admin';

  our $base_dir;
  $base_dir //= '/usr/abills';
  my $certs_dir = "$base_dir/Certs";
  $self->{ssh_key} = $attr->{IDENTITY_FILE} || $certs_dir . '/id_dsa.' . $self->{admin};
  $self->{ssh} = $attr->{SSH} || $CONF->{SSH_FILE} || `which ssh`;
  chomp( $self->{ssh} );

  $self->{FROM_WEB} = $attr->{FROM_WEB};

  if (! -e '/var/www/.ssh' ){
    cmd("touch /var/www/.ssh");
  }
  
  if ( $attr->{DEBUG} ) {
    $self->{debug} = $attr->{DEBUG};
    if ( $attr->{FROM_WEB} ) {
      $DEBUG_ARGS = { TO_WEB_CONSOLE => 1 };
#      delete $DEBUG_ARGS->{TO_CONSOLE};
    }
  }
  else {
    $self->{debug} = 0;
  }

  return $self;
}

#**********************************************************
=head2 execute($command) - Execute command in remote console

  Arguments:
    $command - string  or array of strings
    $attr - hash_ref
      SAVE_TO         - filename to save output
      SKIP_ERROR      - do not finish execution if error on one of commands

      GET_SSH_COMMAND - returns command that will be executed in console

  Returns:
    1

=cut
#**********************************************************
sub execute {
  my $self = shift;

  my ($commands_input, $attr) = @_;
  my $identity_file_option = '';

  $identity_file_option = "-i $self->{ssh_key} ";

  my $login = $self->{admin};

  my $port_option = '';
  if ( $self->{ssh_port} ne '22' ) {
    $port_option = " -p $self->{ssh_port}";
  }

  $attr->{SSH_COMMAND_BASE} = "$self->{ssh} $identity_file_option"
    . ' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no'
    . " $port_option $login\@$self->{host} ";

  if ( $attr->{GET_SSH_COMMAND} ) {
    return $attr->{SSH_COMMAND_BASE};
  }

  if ( ref $commands_input eq 'ARRAY' ) {
    foreach my $command ( @{$commands_input} ) {

      my $result = $self->_ssh_single( $command, $attr );
      # Handle result
      if ( !$result ) {
        print " \n Error executing $command \n" if ($self->{debug} > 1);
        if ( $attr->{SKIP_ERROR} ) {
          next
        }
        else {
          return 0;
        };
      }
    }
    return 1;
  }
  else {
    return $self->_ssh_single( $commands_input, $attr );
  }
  return 0;
}

#**********************************************************
=head2 ssh_single($command, $attr) - executes single command via SSH

  Arguments:
    $command - command to execute
    $attr
      SAVE_TO          - file to save result
      SSH_COMMAND_BASE - ssh connection command

  Returns:
   1 if success or 0

=cut
#**********************************************************
sub _ssh_single {
  my $self = shift;
  my ($command, $attr) = @_;

  my $result = '';

  my $export_file_postfix = '';
  if ( $attr->{SAVE_TO} ) {
    $export_file_postfix = " > $attr->{SAVE_TO}";
  }
  else {
    # Redirecting STDERR to see output inside program
#    $export_file_postfix = " 2>&1 ";
  }

  # Form command
  my $com_base = $attr->{SSH_COMMAND_BASE} || $self->execute( "", { %{$attr}, GET_SSH_COMMAND => 1 } );

  my $res_comand = '';

  if ( ref $command eq 'ARRAY' ) {
    my ($chapter, $arguments, $query) = @{ $command };
    
#    $chapter =~ s/ //g;
    $chapter =~ s/\// /g;
    $chapter =~ s/^ /\//g;

    $res_comand = $chapter . ' ';

    my $ssh_arguments = '';
    if ( $arguments ) {

      if (ref $arguments ne 'HASH'){
        _bp('Wrong command', $arguments);
      }

      foreach my $arg_key ( keys %{$arguments} ) {
        my $value = $arguments->{$arg_key};
        if ( $value =~ /[ ;=]/ ) {
          $value = qq{"$value"};
        }
        if (!$value){
          $value = ($value eq '0') ? "'0'" : '""';
        }
        $ssh_arguments .= "$arg_key=$value ";
      }
    }

    my $query_string = '';
    if ( $query ) {
      if (scalar keys %{$query} == 1 && exists $query->{name}){
        $res_comand .= $query->{name} . ' ';
      }
      else {
        $query_string .= ' where ';
        foreach my $query_key ( keys %{$query} ) {
          $query_string .= qq{$query_key="$query->{$query_key}" };
        }
      }
    }

    $res_comand .= $ssh_arguments;
    $res_comand .= $query_string;

  }
  else {
    $res_comand = $command;
  }
  # Form command;

  _bp( "DEBUG", ( "Was called from " . join( ", ", caller ) . "\n" ), $DEBUG_ARGS ) if ($self->{debug});
  _bp( "DEBUG", "My command called was $res_comand \n", $DEBUG_ARGS ) if ($self->{debug});
  my $com = $com_base . "'$res_comand' $export_file_postfix";

  _bp( "Command", "\n Executing :  $res_comand <hr/>", $DEBUG_ARGS ) if ($self->{debug} > 1);

  # Execute
  $com =~ s/[\r\n]+/ /g;

  _bp( "Full command", $com, $DEBUG_ARGS ) if ($self->{debug} > 1);
  $result = cmd( $com, { timeout => 30, %{$attr} } );
  _bp( "RESULT", $result, $DEBUG_ARGS ) if ($self->{debug} > 1);
  
  # Handle result;
  if ( $result ne '' ) {
    if ( $result =~ /error|failure|missing|ambiguos|not match|expected|invalid value|bad command|no such item|syntax error/i ) {
      print "\n Error : $result" if ($self->{debug});
      return 0;
    }
    elsif ( $attr->{SHOW_RESULT} ) {
      return $result;
    }
    else {
      print "\n Result : $result \n" if ($self->{debug} > 1);
    }
  }

  return 1;
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

  my $cmd_result = $self->_ssh_single( LIST_REFS->{$list_name}, { SHOW_RESULT => 1 } );

  return 0 if ($cmd_result eq '0');

  $cmd_result =~ s/^Flags.*//; # Omitting flags row
  $cmd_result =~ s/\n//;       # Removing first new line
  $cmd_result =~ s/ {3}/ A /g; # Omitting empty status
  $cmd_result =~ s/^ //gm;     # Remove trailing spaces
  $cmd_result =~ s/ +/ /gm;    # Max one space in row
  $cmd_result =~ s/;;;.*\n//g; # Remove comments

  # _bp( "Result string that will be splitted", $cmd_result, $DEBUG_ARGS ) if ($self->{debug} == 2);
  my @result_rows = split( /\n\s+\n/, $cmd_result );
  # _bp( "Result rows before parse", \@result_rows, $DEBUG_ARGS ) if ($self->{debug} == 2);

  my @result_list = ();
  foreach my $line ( @result_rows ) {
    my %hash = ();

    $line =~ s/\n|\s+/ /g;
    $line =~ s/ +$//g;

    next if (defined $line && $line eq '');
    my @vars = split( " ", $line );
    $hash{id} = shift @vars;
    # Removing status
    $hash{flag} = shift @vars;
    foreach my $arg_val ( @vars ) {
      next if ( $arg_val eq 'A');
      my ($arg, $val) = split( "=", $arg_val );

      $val ||= '';

      $val =~ s/"//g;
      $hash{$arg} = $val;
    }

    push @result_list, \%hash;
  }

  # _bp( "Result list", \@result_list, $DEBUG_ARGS ) if ($self->{debug} == 2);

  return \@result_list;
}

#**********************************************************
=head2 check_access() - checks if mikrotik is accessible

  Returns:
    boolean

=cut
#**********************************************************
sub check_access {
  my $self = shift;

  my $port_option = '';
  if ( $self->{ssh_port} ne '22' ) {
    $port_option = " -p $self->{ssh_port}";
  }

  if (! -f $self->{ssh_key}){
    return -5; # File not exists
  }
  
  my $cmd = "$self->{ssh} -i $self->{ssh_key} $port_option -o BatchMode=yes"
    . ' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o CheckHostIP=no'
    .  " $self->{admin}\@$self->{host} '/quit'";
  _bp( "ssh check result command", "Executing : $cmd \n", $DEBUG_ARGS) if ($self->{debug});

  my $cmd_result = cmd( $cmd, { timeout => 5, SHOW_RESULT => 1, RETURN => 1 } );
  _bp( "ssh check result", $cmd_result, $DEBUG_ARGS ) if ($self->{debug} > 2);

  my $ok = $cmd_result !~ /Permission denied|Failed|denied|Warning/i;
  my $not_network_accessible = $cmd_result =~ /timed out|no route to host/i;

  if ( $self->{FROM_WEB} && $cmd_result !~ /interrupted/ ) {
    print $cmd_result . "<br/>";
  }

  if ( $not_network_accessible ) {
    print "Error : $cmd_result";
    return 0;
  }

  return $ok;
}


1;