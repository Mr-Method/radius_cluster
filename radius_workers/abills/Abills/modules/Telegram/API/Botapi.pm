#!/usr/bin/perl

package Botapi;
use strict;
use warnings FATAL => 'all';

# use JSON;

my $debug = 1;

#**********************************************************
=head2 new($token)

=cut
#**********************************************************
sub new {
  my ($class, $token, $chat_id) = @_;

  $chat_id //= "";

  my $self = {
    api_url => "https://api.telegram.org/bot$token/sendMessage",
    chat_id => $chat_id,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 send_message()
  
=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  $attr->{chat_id} ||= $self->{chat_id};

  # my $params = qq/-F "chat_id=$attr->{chat_id}"/;
  # $params .= qq/ -F "text=$attr->{text}"/;
  my $json_str = $self->perl2json($attr);
  my $params   = qq(-d '$json_str' -H "Content-Type: application/json");
  my $url      = $self->{api_url};
  my $result   = `curl $params -s -X POST "$url"`;

  if ($debug > 0) {
    `echo 'COMMAND: curl $params -s -X POST "$url"' >> /tmp/telegram.log`;
    `echo 'RESULT: $result' >> /tmp/telegram.log`;
  }
  
  return 1;
}

#**********************************************************
=head2 perl2json()

=cut
#**********************************************************
sub perl2json {
  my $self = shift;
  my ($data) = @_;
  my @json_arr = ();

  if (ref $data eq 'ARRAY') {
    foreach my $key (@{$data}) {
      push @json_arr, $self->perl2json($key);
    }
    return '[' . join(',', @json_arr) . "]";
  }
  elsif (ref $data eq 'HASH') {
    foreach my $key (sort keys %$data) {
      my $val = $self->perl2json($data->{$key});
      push @json_arr, qq{\"$key\":$val};
    }
    return '{' . join(',', @json_arr) . "}";
  }
  else {
    $data //='';
    return qq{\"$data\"};
  }
}


1;

