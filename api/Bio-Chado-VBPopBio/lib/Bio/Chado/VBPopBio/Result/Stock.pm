package Bio::Chado::VBPopBio::Result::Stock;

use base 'Bio::Chado::Schema::Result::Stock::Stock';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->resultset_class('Bio::Chado::VBPopBio::ResultSet::Stock'); # required because BCS has a custom resultset
__PACKAGE__->subclass({
		       nd_experiment_stocks => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentStock',
		       stockprops => 'Bio::Chado::VBPopBio::Result::Stockprop',
		       organism => 'Bio::Chado::VBPopBio::Result::Organism',
		       type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });
__PACKAGE__->resultset_attributes({ order_by => stock_id });

use aliased 'Bio::Chado::VBPopBio::Util::Multiprops';
use Carp;

=head1 NAME

Bio::Chado::VBPopBio::Result::Stock

=head1 SYNOPSIS

Stock object with extra convenience functions

    $stock = $schema->stocks->find({uniquename => 'Anopheles subpictus Sri Lanka 2003-1'});
    $experiments = $stock->experiments();

=head1 SUBROUTINES/METHODS

=head2 experiments

Returns all experiments related to this stock.


=cut

sub experiments {
  my ($self) = @_;
  return $self->nd_experiments();
  # or $self->search_related('nd_experiment_stocks')->search_related('nd_experiment');
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

Get all species ID assays (based on nd_experiment.type)

=cut

sub species_identification_assays {
  my ($self) = @_;
  return $self->experiments_by_type($self->result_source->schema->types->species_identification_assay);
}


=head2 experiments_by_type

Helper method not intended for general use.
See field_collections, phenotype_assays for usage.

=cut

sub experiments_by_type {
  my ($self, $type) = @_;
  return $self->experiments->search({ 'nd_experiment.type_id' => $type->cvterm_id });
}

=head2 projects

convenience search distinct for all related projects

=cut

sub projects {
  my ($self) = @_;
  return $self->experiments->search_related('nd_experiment_projects')->search_related('project', {}, { distinct=>1 });
}

=head2 external_id

alias for stock.name, because that's where we store it.

=cut

sub external_id {
  my $self = shift;
  return $self->name;
}

=head2 stable_id

usage 1: $stock->stable_id($project); # when attempting to find an existing id or make a new one
usage 2: $stock->stable_id(); # all other times

If a $stock->dbxref is present then the dbxref->accession is returned.
If not, and if a $project argument has been provided then a new dbxref will be determined
by looking for an existing dbxref with props 'project external ID' => $project->external_id
and 'sample external ID' => $stock->external_id (which should remain after a sample
has been deleted) or failing that, creating a new VBS0123456 style ID.

=cut

sub stable_id {
  my ($self, $project) = @_;

  if (defined $self->dbxref_id and my $dbxref = $self->dbxref) {
    if ($dbxref->db->name ne 'VBS') {
      croak "fatal error: stock.dbxref is not from db.name='VBS'\n";
    }
    return $dbxref->accession;
  }
  unless ($project) {
    croak "fatal error: stock->stable_id called on dbxref-less stock without project arg\n";
  }

  my $schema = $self->result_source->schema;

  my $db = $schema->dbs->find_or_create({ name => 'VBS' });
  my $proj_extID_type = $schema->types->project_external_ID;
  my $samp_extID_type = $schema->types->sample_external_ID;

  my $search = $db->dbxrefs->search
    ({
      'dbxrefprops.type_id' => $proj_extID_type->id,
      'dbxrefprops.value' => $project->external_id,
      'dbxrefprops_2.type_id' => $samp_extID_type->id,
      'dbxrefprops_2.value' => $self->external_id,
     },
     { join => [ 'dbxrefprops', 'dbxrefprops' ] }
    );

  if ($search->count == 0) {
    # need to make a new ID

    # first, find the "highest" accession in dbxref for VBP
    my $last_dbxref_search = $schema->dbxrefs->search
      ({ 'db.name' => 'VBS' },
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
	accession => sprintf("VBS%07d", $next_number),
	dbxrefprops => [ {
			 type => $proj_extID_type,
			 value => $project->external_id,
			 rank => 0,
			},
		        {
			 type => $samp_extID_type,
			 value => $self->external_id,
			 rank => 0,
			},
		       ]
       });
    # set the stock.dbxref to the new dbxref
    $self->dbxref($new_dbxref);
    $self->update; # make it permanent
    return $new_dbxref->accession; # $self->stable_id would be nice but slower
  } elsif ($search->count == 1) {
    # set the stock.dbxref to the stored stable id dbxref
    my $old_dbxref = $search->first;
    $self->dbxref($old_dbxref);
    $self->update; # make it permanent
    return $old_dbxref->accession;
  } else {
    croak "Too many VBS dbxrefs for project ".$project->external_id." + sample ".$self->external_id."\n";
  }

}



=head2 add_multiprop

Adds normal props to the object but in a way that they can be
retrieved in related semantic chunks or chains.  E.g.  'insecticide'
=> 'permethrin' => 'concentration' => 'mg/ml' => 150 where everything
in single quotes is an ontology term.  A multiprop is a chain of
cvterms optionally ending in a free text value.

This is more flexible than adding a cvalue column to all prop tables.

Usage: $stock->add_multiprop($multiprop);

See also: Util::Multiprop (object) and Util::Multiprops (utility methods)

=cut

sub add_multiprop {
  my ($self, $multiprop) = @_;

  return Multiprops->add_multiprop
    ( multiprop => $multiprop,
      row => $self,
      prop_relation_name => 'stockprops',
    );
}

=head2 multiprops

get a arrayref of multiprops

=cut

sub multiprops {
  my ($self) = @_;

  return Multiprops->get_multiprops
    ( row => $self,
      prop_relation_name => 'stockprops',
    );
}


=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self) = @_;
  return {
	  $self->get_columns,
	  'dbxref.accession' => defined $self->dbxref_id ? $self->dbxref->db->name.':'.$self->dbxref->accession : 'N/A',
	  organism => $self->organism ? { $self->organism->get_columns } : 'NULL',

	  props => [ map { $_->as_data_structure } $self->multiprops ],

	  nd_experiments => [ map { $_->as_data_structure } $self->experiments ],
	 };
}


=head2 as_data_for_jsonref

returns a json-like hashref of arrayrefs and hashrefs

this method is specifically for dojox.json.ref style json

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 's'.$self->stock_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
    return {
	    id => $id,
	    name => $self->name,
	    uniquename => $self->uniquename,
	    type => $self->type->cv->name.':'.$self->type->name,
	    organism => $self->organism ? $self->organism->as_data_for_jsonref($seen) : undef,
	    props => [ map { $_->as_data_for_jsonref($seen) } $self->stockprops ],
	    experiments => [ map { $_->as_data_for_jsonref($seen) } $self->nd_experiments ],
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

1; # End of Bio::Chado::VBPopBio::Result::Stock
