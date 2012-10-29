package Bio::Chado::VBPopBio::ResultSet::Experiment;

use base 'DBIx::Class::ResultSet';
use Carp;
use strict;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Experiment

=head1 SYNOPSIS

Experiment resultset with extra convenience functions


=head1 SUBROUTINES/METHODS

=head2 create

 Usage: $field_collections->create({ nd_geolocation => $geoloc });
        $genotype_assays->create();

 Desc: Convenience method to avoid having to set the type.
       If nd_geolocation is missing a default 'laboratory' object will be added

       find_or_create and other methods may not be needed because
       this table doesn't have a unique key constraints!

=cut

sub create {
  my ($self, $fields) = @_;

  $fields = {} unless defined $fields;
  $fields->{type} = $self->_type unless (defined $fields->{type});
  $fields->{nd_geolocation} = $self->result_source->schema->geolocations->find_or_create( { description => 'laboratory' } ) unless (defined $fields->{nd_geolocation});

  return $self->SUPER::create($fields);
}

=head2 _type

Private method to return type cvterm for this subclass

Must be implemented in subclasses

=cut

sub _type {
  my ($self) = @_;
  croak("_type not implemented");
}


=head2 search_on_properties

    my $expts1 = $experiments->search_on_properties({ name => 'CDC light trap' });
    my $expts2 = $experiments->search_on_properties({ value => 'green' });
    # probably more useful to search on cvterm and value:
    my $expts3 = $experiments->search_on_properties(
                 { name => 'end time of day', value => '05:00' });
    # LIKE
    my $expts4 = $experiments->search_on_properties({ name => { like => 'Anoph%' } });

The interesting DBIx::Class thing here is that even though two joins are
specified in our code, only the joins which are needed are actually applied!
( test this by setting $schema->storage->debug(1) )

=cut

sub search_on_properties {
  my ($self, $conds) = @_;
  return $self->search($conds, { join => { nd_experimentprops => 'type' } });
}

=head2 search_on_properties_cv_acc

Needs a better name

    my $expts = $experiments->search_on_properties_cv_acc('MIRO:30000035');

assumes NAME:number format or will die


=cut

sub search_on_properties_cv_acc {
  my ($self, $cv_acc) = @_;
  my ($cv_name, $cv_number) = $cv_acc =~ /^([A-Za-z]+):(\d+)$/;
  $self->throw_exception("badly formatted CV/ontology accession - should be NAME:00012345 (any number of digits)")
    unless (defined $cv_name && defined $cv_number);

  return $self->search({ 'db.name' => $cv_name, accession => $cv_number },
		       { join => { 'nd_experimentprops' => { 'type' => { 'dbxref' => 'db'} } } });
}


=head2 find_by_stable_id

returns a single result with the stable id

TO DO: describe failure modes

=cut

sub find_by_stable_id {
  my ($self, $stable_id) = @_;

  my $schema = $self->result_source->schema;
  my $db = $schema->dbs->find_or_create({ name => 'VBA' });

  my $search = $db->dbxrefs->search({ accession => $stable_id });

  if ($search->count == 1 && $search->first->nd_experiment_dbxrefs->count == 1) {
    return $search->first->nd_experiment_dbxrefs->first->nd_experiment;
  }
  return undef;
}

=head1 AUTHOR

VectorBase, C<< <info at vectorbase.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 VectorBase.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;
