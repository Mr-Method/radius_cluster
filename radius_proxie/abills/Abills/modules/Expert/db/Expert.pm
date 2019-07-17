package Expert;

=head1 NAME

 Expert pm

=cut

use strict;
use parent 'main';
my $MODULE = 'Expert';

use Abills::Base qw/_bp/;

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;
  
  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 question_info($question_id)

=cut
#**********************************************************
sub question_info {
  my $self = shift;
  my ($question_id) = @_;

  $self->query2("SELECT *
    FROM expert_question
    WHERE id = ?",
    undef,
    { INFO => 1, Bind => [ $question_id ] }
  );

  return $self;
}

#**********************************************************
=head2 question_list()

=cut
#**********************************************************
sub question_list {
  my $self = shift;
  my ($question_id) = @_;

  $self->query2("SELECT *
    FROM expert_question;",
    undef,
    { COLS_NAME => 1}
  );

  return $self->{list} || [ ];
}

#**********************************************************
=head2 question_add($attr)

=cut
#**********************************************************
sub question_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('expert_question', $attr);

  return $self;
}

#**********************************************************
=head2 question_change($id, $question, $description)

=cut
#**********************************************************
sub question_change {
  my $self = shift;
  my ($id, $question, $description) = @_;

  $question //= "";
  $description //= "";
  
  $self->query2( "UPDATE expert_question
    SET question = '$question',
    description = '$description'
    WHERE id = $id",
    'do', 
    { } 
  );
  
  return $self;
}

#**********************************************************
=head2 answers_info($answer_id)

=cut
#**********************************************************
sub answers_info {
  my $self = shift;
  my ($answer_id) = @_;

  $self->query2("SELECT *
    FROM expert_answer
    WHERE id = ?",
    undef,
    { INFO => 1, Bind => [ $answer_id ] }
  );

  return $self;
}


#**********************************************************
=head2 answers_list($question_id)

=cut
#**********************************************************
sub answers_list {
  my $self = shift;
  my ($question_id) = @_;

  $self->query2("SELECT *
    FROM expert_answer
    WHERE question_id = ?",
    undef,
    { COLS_NAME => 1, Bind => [ $question_id ] }
  );

  return $self->{list};
}

#**********************************************************
=head2 answer_add($attr)

=cut
#**********************************************************
sub answer_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('expert_answer', $attr);

  return $self;
}

#**********************************************************
=head2 answer_change($id, $answer)

=cut
#**********************************************************
sub answer_change {
  my $self = shift;
  my ($id, $answer, $question_id) = @_;

  $self->query2( "UPDATE expert_answer
    SET answer = '$answer',
    question_id = '$question_id'
    WHERE id = $id",
    'do', 
    { } 
  );
  
  return $self;
}

1