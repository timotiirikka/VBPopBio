package Bio::Chado::VBPopBio::Util::Multiprops;

use strict;
use warnings;
use Carp;

use aliased 'Bio::Chado::VBPopBio::Util::Multiprop';

my $MAGIC_VALUE = ',';

=head1 NAME

Bio::Chado::VBPopBio::Util::Multiprops

=head1 SYNOPSIS

Utility class for adding/retrieving multiprops
(similar to Bio::Chado::Schema::Util)

Currently implemented as "add only", for simplicity, although will not
add the same multiprop twice (which implies that you can't specify the
rank of a multiprop before you add it, although this could change in
the future).

=head2 add_multiprop

Returns the multiprop that was passed (but this should now have its rank attribute set).

If the multiprop was already attached then it won't add a duplicate.

hash args: row => DBIx::Class Row or Result object
           prop_relation_name => DBIx props table relation name, e.g. 'stockprops'
           multiprop => Multiprop object

=cut

sub add_multiprop {
  my ($class, %args) = @_;

  # check for required args
  $args{$_} or confess "must provide $_ arg"
    for qw/row prop_relation_name multiprop/;

  my $row = delete $args{row};
  my $multiprop = delete $args{multiprop};
  my $prop_relation_name = delete $args{prop_relation_name};

  %args and confess "invalid option(s): ".join(', ', sort keys %args);

  # perform the (expensive!) check for existing multiprops
  my $input_json = $multiprop->as_json;
  foreach my $existing_multiprop ($row->multiprops) {
    return $existing_multiprop if ($existing_multiprop->as_json eq $input_json);
  }

  # find the highest rank of existing props
  my $max_rank = $row->$prop_relation_name->get_column('rank')->max;

  # ignore negative ranks and default to zero
  $max_rank = 0 unless (defined $max_rank && $max_rank > 0);

  # assign next available rank for the first cvterm of the new multiprop
  my $rank = $max_rank + 1;

  defined $multiprop->rank and confess "predefined rank not yet handled in add_multiprop";

  # set the rank on the passed object in case the caller wants to
  $multiprop->rank($rank);

  my $last_prop; # keep track so we can add the value if needed
  foreach my $cvterm ($multiprop->cvterms) {
    $last_prop = $row->find_or_create_related($prop_relation_name,
					      { type => $cvterm,
						rank => $rank++,
						value => $MAGIC_VALUE # subject to change below
					      });
  }

  # if value is undef, then we will terminate the chain with NULL in database
  # if it's a comma then that means the chain continues (comma == MAGIC VALUE)
  # if it's a non-comma value that also terminates the chain
  my $value = $multiprop->value;
  confess "magic value '$MAGIC_VALUE' is not allowed as a multiprop value"
    if (defined $value && $value eq $MAGIC_VALUE);
  $last_prop->value($value);
  $last_prop->update();

  return $multiprop;
}

=head2 get_multiprops

Retrieve props and process them into multiprops

hash args: row => DBIx::Class Row or Result object
           prop_relation_name => DBIx props table relation name, e.g. 'stockprops'

           # the following OPTIONAL arg is for internal use (see multiprop methods in Result classes)
           filter => Cvterm object - returns the first multiprop with this term first in chain.

Returns a perl list of multiprops

Does NOT return props with ranks <= 0.

=cut

sub get_multiprops {
  my ($class, %args) = @_;

  # check for required args
  $args{$_} or confess "must provide $_ arg"
    for qw/row prop_relation_name/;

  my $row = delete $args{row};
  my $prop_relation_name = delete $args{prop_relation_name};
  my $filter = delete $args{filter};

  confess "filter option requires a Cvterm object" unless (!defined $filter || $filter->isa("Bio::Chado::VBPopBio::Result::Cvterm"));

  %args and confess "invalid option(s): ".join(', ', sort keys %args);


  # get the positive-ranked props and order them by rank
  my $props = $row->$prop_relation_name->search({}, { where => { rank => { '>' => 0 } },
						     order_by => 'rank' });

  # step through the props pushing them into different baskets
  # splitting on an undefined value or non-comma value.
  my @prop_groups;
  my $index = 0;
  while (my $prop = $props->next) {
    push @{$prop_groups[$index]}, $prop;
    $index++ unless (defined $prop->value && $prop->value eq $MAGIC_VALUE);
  }

  # convert prop groups into multiprops
  my @multiprops;
  foreach my $prop_group (@prop_groups) {
    my @cvterms = map { $_->type } @{$prop_group};
    my $rank = $prop_group->[0]->rank;
    my $value = pop(@{$prop_group})->value;
    confess "value should not be magic value '$MAGIC_VALUE'"
      if (defined $value && $value eq $MAGIC_VALUE);
    my $multiprop =  Multiprop->new(cvterms => \@cvterms,
				     value => $value,
				     rank => $rank,);

    if ($filter && $filter->cvterm_id == $cvterms[0]->cvterm_id) {
      return $multiprop;
    } else {
      push @multiprops, $multiprop;
    }
  }
  # if we're filtering (and didn't find the multiprop we wanted) then return nothing!
  return $filter ? undef : @multiprops;
}

1;
