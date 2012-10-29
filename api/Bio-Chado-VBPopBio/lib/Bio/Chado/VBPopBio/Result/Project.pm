package Bio::Chado::VBPopBio::Result::Project;

use Carp;
use feature 'switch';
use base 'Bio::Chado::Schema::Result::Project::Project';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({
		       nd_experiment_projects => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentProject',
		       projectprops => 'Bio::Chado::VBPopBio::Result::Projectprop',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Project

=head1 SYNOPSIS

Project object with extra convenience functions.
Specialised project classes will soon be found in the.
Bio::Chado::VBPopBio::Result::Project::* namespace.


=head1 SUBROUTINES/METHODS

=head2 experiments

Get all experiments for this project.  Alias for nd_experiments (many to many relationship)

=cut

sub experiments {
  my ($self) = @_;
  return $self->nd_experiments(); # search_related('nd_experiment_projects')->search_related('nd_experiment');
}

=head2 field_collections

Get all field_collections (based on nd_experiment.type)

=cut

sub field_collections {
  my ($self) = @_;
  return $self->experiments_by_type($self->result_source->schema->types->field_collection);
}

=head2 phenotype_assays

Get all phenotype assays (based on nd_experiment.type)

=cut

sub phenotype_assays {
  my ($self) = @_;
  return $self->experiments_by_type($self->result_source->schema->types->phenotype_assay);
}

=head2 genotype_assays

Get all genotype assays (based on nd_experiment.type)

=cut

sub genotype_assays {
  my ($self) = @_;
  return $self->experiments_by_type($self->result_source->schema->types->genotype_assay);
}

=head2 species_identification_assays

Get all species identification assays (based on nd_experiment.type)

=cut

sub species_identification_assays {
  my ($self) = @_;
  return $self->experiments_by_type($self->result_source->schema->types->species_identification_assay);
}

=head2 stocks

Get all stocks (via nd_experiments) with no duplicates

=cut

sub stocks {
  my ($self) = @_;
  return $self->experiments->search_related('nd_experiment_stocks')->search_related('stock', { } , { distinct => 1 });
}

=head2 experiments_by_type

Helper method not intended for general use.
See field_collections, phenotype_assays for usage.

=cut

sub experiments_by_type {
  my ($self, $type) = @_;
  return $self->experiments->search({ type_id => $type->cvterm_id });
}

#  =head2 assays
#  
#  This is an alias for experiments()
#  
#  =cut
#  
#  sub assays {
#    my ($self) = @_;
#    return $self->experiments();
#  }

=head2 external_id

no args, returns the project external id (study identifier from ISA-Tab)
format 2011-MacCallum-permethrin-selected

=cut

sub external_id {
  my ($self) = @_;
  my $schema = $self->result_source->schema;
  my $proj_extID_type = $schema->types->project_external_ID;

  my $props = $self->search_related('projectprops',
				    { type_id => $proj_extID_type->id } );

  croak "Project does not have exactly one external id projectprop"
    unless ($props->count == 1);

  return $props->first->value;
}

=head2 stable_id

no args

Returns a dbxref from the VBP (VB Population Project) db
by looking up dbxrefprop "project external ID"

It will create a new entry with the next available accession if there is none.

The dbxref cannot be attached directly to the project (because there's no suitable
relationship in Chado).

=cut

sub stable_id {
  my ($self) = @_;
  my $schema = $self->result_source->schema;

  my $db = $schema->dbs->find_or_create({ name => 'VBP' });

  my $proj_extID_type = $schema->types->project_external_ID;

  my $search = $db->dbxrefs->search
    ({
      'dbxrefprops.type_id' => $proj_extID_type->id,
      'dbxrefprops.value' => $self->external_id,
     },
     { join => 'dbxrefprops' }
    );

  if ($search->count == 0) {
    # need to make a new ID

    # first, find the "highest" accession in dbxref for VBP
    my $last_dbxref_search = $schema->dbxrefs->search
      ({ 'db.name' => 'VBP' },
       { join => 'db',
	 order_by => { -desc => 'accession' },
         limit => 1 });

    my $next_number = 1;
    if ($last_dbxref_search->count) {
      my $acc = $last_dbxref_search->first->accession;
      my ($prefix, $number) = $acc =~ /(\D+)(\d+)/;
      $next_number = $number+1;
    }

    # now create the dbxref
    my $new_dbxref = $schema->dbxrefs->create
      ({
	db => $db,
	accession => sprintf("VBP%07d", $next_number),
	dbxrefprops => [ {
			 type => $proj_extID_type,
			 value => $self->external_id,
			 rank => 0,
			} ]
       });

    return $new_dbxref->accession;
  } elsif ($search->count == 1) {
    return $search->first->accession;
  } else {
    croak "Too many dbxrefs for project ".$project->external_id." with dbxrefprop project external ID";
  }

}

=head2 delete

Deletes the project in a cascade which deletes all would-be orphan related objects.

It does not delete any would-be-orphaned contacts or publications.  Hopefully that will be
OK.  If not we will have to check that the contacts (or publications) don't belong to
several different object types before deletion.

=cut

sub delete {
  my $self = shift;

  my $linkers = $self->related_resultset('nd_experiment_projects');
  while (my $linker = $linkers->next) {
    # check that the experiment is only attached to one project (has to be this one)
    if ($linker->nd_experiment->projects->count == 1) {
      $linker->nd_experiment->delete;
    }
    $linker->delete;
  }

  return $self->SUPER::delete();
}


=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self) = @_;
  return {
	  $self->get_columns,

	  projectprops => [ map {
	    { $_->get_columns,
		type => { $_->type->get_columns },
	      } } $self->projectprops
			  ],
	  stocks => [ map { $_->as_data_structure } $self->stocks ],
	 };
}

=head2 as_data_for_jsonref

returns a json-like hashref of arrayrefs and hashrefs

this method is specifically for dojox.json.ref style json

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 'p'.$self->project_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
    return {
	    id => $id,
	    name => $self->name,
	    description => $self->description,
	    stocks => [ map { $_->as_data_for_jsonref($seen) } $self->stocks ],
	    props => [ map { $_->as_data_for_jsonref($seen) } $self->projectprops ],
	 };
  }
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

1; # End of Bio::Chado::VBPopBio::Result::Project
