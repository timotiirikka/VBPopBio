package Bio::Chado::VBPopBio::ResultSet::Stock;

use strict;
use base 'DBIx::Class::ResultSet';
use Carp;
use aliased 'Bio::Chado::VBPopBio::Util::Multiprop';


=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Stock

=head1 SYNOPSIS

Stock resultset with extra convenience functions


=head1 SUBROUTINES/METHODS

=head2 find_or_create_from_isatab

 Usage: $stocks->find_or_create_from_isatab($isatab_sample_name, $isatab_sample_data, $project, $ontologies, $study);

 Desc: This method creates a stock object from the isatab sample hashref.
 Ret : a new Stock row
 Args: sample_name string
       hashref (example contents below)
         { description   => '...',
           material_type => 'whole_organism',
           characteristics => { Sex => { value => 'female', term_accession_number => 123, term_source_ref => 'ABC' } },
         }
       Project object
       hashref $isa->{ontology_lookup} from Bio::Parser::ISATab
       hashref current ISA study (maybe needed for protocols one day?)

=cut

sub find_or_create_from_isatab {
  my ($self, $sample_name, $sample_data, $project, $ontologies, $study) = @_;

  # my $stocknum = $self->count + 1;

  my $schema = $self->result_source->schema;

  # create a stock type cvterm (maybe this could be optionally overwritten)
  my $cvterms = $schema->cvterms;
  my $dbxrefs = $schema->dbxrefs;

  # use Material Type here????

  my $material_type = $cvterms->find_by_accession($sample_data->{material_type});

  croak "Sample material type not found (REF=$sample_data->{material_type}{term_source_ref},ACC=$sample_data->{material_type}{term_accession_number})\n" unless (defined $material_type);

  # create a Chado organism object
  my $organisms = $schema->organisms;
  my $stock_organism = undef;

  my $organism_data = $sample_data->{characteristics}{'Organism'};

  # see if organism has been provided from NCBI taxonomy or
  if ((defined $organism_data->{term_source_ref} &&
       ($organism_data->{term_source_ref} eq 'NCBITaxon' ||
	$organism_data->{term_source_ref} eq 'MIRO')) && # MIRO organisms not loaded yet!
      defined $organism_data->{term_accession_number} &&
      length($organism_data->{term_accession_number})) {

    my $dbname = $organism_data->{term_source_ref};
    my $acc = $organism_data->{term_accession_number};
    my $search = $organisms->search( { 'dbxref.accession' => $acc,
				       'db.name' => $dbname,
				     },
				     { join => { 'organism_dbxrefs' => { 'dbxref' => 'db' } } });

    my $count = $search->count;
    if ($count == 0) {
      $schema->defer_exception("Can't find organism $dbname:$acc for sample $sample_name\n");
      $stock_organism = $organisms->first;
    } elsif ($count > 1) {
      croak "Found multiple organisms with $dbname:$acc for sample $sample_name - something's wrong!";
      $stock_organism = $organisms->first;
    } else {
      $stock_organism = $search->first;
    }
  } else {
    # fallback to user provided text
    my ($genus, $species) = split " ", $organism_data->{value}, 2;
    $species = '' unless (defined $species);

    #
    # Do a few common MIRO to NCBITaxon conversions
    #
    ($genus, $species) = ('gambiae', 'species complex') if ($organism_data->{value} eq 'Anopheles gambiae sensu lato');
    ($genus, $species) = ('Culex', '') if ($organism_data->{value} eq 'genus Culex');

    if ($genus) {
      $stock_organism = $organisms->find({ genus => $genus,
					   species => $species,
					 }) or $schema->defer_exception("Warning: Sample 'Characteristics [Organism]' genus-species <$genus>-<$species> not in db for sample '$sample_name'.");
    }
    # else permitted empty 'Characteristics [Organism]' column -> silently adds null organism to stock.
  }

 # croak "find or create stock and handle existing stable ID in ISA-Tab Sample Name column";

  my $stock;

  # first check to see if we have a sample stable ID that's already in the db
  if ($sample_name =~ /^VBS\d+/) {
    my $vbs_db = $schema->dbs->find_or_create({ name => 'VBS' });
    my $vbs_dbxref_search = $vbs_db->dbxrefs->search( { accession => $sample_name } );
    if ($vbs_dbxref_search->count == 1) {

      my $vbs_dbxref = $vbs_dbxref_search->first;
      if ($vbs_dbxref->stocks->count == 1) {
	my $existing_stock = $vbs_dbxref->stocks->first;

	# now check some vital things are the same:
	if ($existing_stock->type_id == $material_type->cvterm_id &&
	    (
	     # it's OK to leave organism blank when reusing a stock
	     !defined $stock_organism ||
	     # or if the existing stock has no organism and we don't provide one
	     (!defined $existing_stock->organism && !defined $stock_organism) ||
	     # or if the existing and provided organisms are the same
	     $stock_organism->organism_id == $existing_stock->organism->organism_id
	    )) {
	  $stock = $existing_stock;
	} else {
	  $schema->defer_exception("sample type and organism in ISA-Tab (".$material_type->name.", ".($stock_organism ? $stock_organism->name : 'null').") do not agree with pre-existing sample $sample_name (".$existing_stock->type->name().", ".($existing_stock->organism ? $existing_stock->organism->name : 'null').')');
	}
      } elsif ($vbs_dbxref->stocks->count == 0) {
	$schema->defer_exception("dbxref for $sample_name has no stock attached to it currently");
	# carry on for now by making a new stock
      } else {
	# croaking because this is more of an API error (something badly wrong)
	croak "dbxref for $sample_name has multiple stocks attached - something's wrong!";
      }
    } elsif ($vbs_dbxref_search->count == 0) {
      $schema->defer_exception("can't find a dbxref for $sample_name");
      # carry on for now with new stock
    } else {
      # croaking because this is more of an API error (something badly wrong)
      croak "sample name $sample_name found multiple VBS dbxrefs - something's wrong!";
    }


    if (keys %{$sample_data->{characteristics}}) {
      $schema->defer_exception_once("Sample characteristics have been provided for pre-existing samples.  This is not allowed (as validating them would be onerous).");
    }
  }

  if (!defined $stock) {
    $stock = $self->create({
			    name => $sample_name,
			    uniquename => $study->{study_identifier}.":".$sample_name,
			    description => $sample_data->{description},
			    type => $material_type,
			    defined $stock_organism ? (organism => $stock_organism) : (),
			   });


    # Create the "stable id" (created in the database)
    my $stable_id = $stock->stable_id($project);

    #
    # Deal with arbitrary "Characteristics [ONTO:term name]" columns
    # by adding multiprops for them
    #
    foreach my $cname (keys %{$sample_data->{characteristics}}) {
      next if ($cname eq 'Organism');

      my $characteristic_data = $sample_data->{characteristics}{$cname};

      # first look up the name to see if it is a CV term
      if ($cname =~ /(\w+):(.+)/) {
	my $cterm = $cvterms->find_by_name({ term_source_ref => $1, term_name => $2 });
	if (defined $cterm) {
	  # we'll add a multiprop
	  my @mterms;		#cvterms
	  my $value;
	  push @mterms, $cterm;
	  my $vterm = $cvterms->find_by_accession($characteristic_data);
	  if (defined $vterm) {
	    push @mterms, $vterm;
	  } else {
	    $value = $characteristic_data->{value};
	    # in this case, the multiprop is identical to a standard prop
	  }
	  my $mprop = $stock->add_multiprop(Multiprop->new(cvterms => \@mterms, value => $value));
	  # warn "just added multiprop: ".$mprop->as_text."\n";
	} else {
	  $schema->defer_exception_once("Can't find unique ontology term '$cname' for ISA-Tab sample column heading 'Characteristics ($cname)'");
	}
      } else {
	$schema->defer_exception_once("Sample column 'Characteristics (>>>$cname<<<)' must use an ontology term, e.g. 'EFO:organism'\n");
      }

    }

    if ($sample_data->{factor_values}) {
      warn "Warning: Not currently loading factor values for samples\n" unless ($self->{FV_WARNED_ALREADY}++);
    }

#
# NOT LOADING FACTOR VALUE COLUMNS AT PRESENT (see email discussion with Emmanuel/Pantelis)
#
#
#    # load any factor values
#    if ($sample_data->{factor_values}) {
#      while (my ($factor_name, $factor_data) = each %{$sample_data->{factor_values}}) {
#
#	# slice of a hashref @{$hashref}{'key1', 'key2'}
#	my ($factor_type, $factor_acc, $factor_source) =
#	  @{$study->{study_factor_lookup}{$factor_name}}{qw/study_factor_type
#							    study_factor_type_term_accession_number
#							    study_factor_type_term_source_ref/};
#
#	# in cases like where EFO terms have OBI:012345 accessions
#	# (our dbxrefs are OBI:012345)
#	#
#	###NOT ANY MORE### let's handle issues like this at submission stage, not here
#	# if ($factor_acc =~ /^(.+?):(.+)$/) {
#	#	($factor_source, $factor_acc) = ($1, $2);
#	# }
#
#	my $factor_dbxref = $dbxrefs->find({ accession => $factor_acc,
#					     version => '',
#					     'db.name' => $factor_source },
#					   { join => 'db',
#					     # doesn't seem possible to specify constraint key due to join
#					   }
#					  );
#
#	if (defined $factor_dbxref and my $factor_term = $factor_dbxref->cvterm) {
#	  $stock->find_or_create_related( 'stockprops',
#					  { type => $factor_term,
#					    value => $factor_data->{value},
#					  }
#					);
#
#
#	  # get the primary key ID of the cvterm we just created in VBcv (for path spec below)
#	  # my $type_id = $cvterms->find( { name => $factor_type, 'cv.name' => 'VBcv' }, { join => 'cv' })->cvterm_id;
#
#	  # add a property to the project pointing to this experimental factor
#	  # somehow this has to be decodable so we can retrieve factor values for a project?
#	  ### this was never used - it will better be handled by a vis-like JSON property
#	  ### e.g. projectprop.type = "VBcv:experimental factor", value = q/{ cvterm: { name: "organism", cvterm_id: 12345,
#	  # my $type_id = $factor_term->cvterm_id;
#	  #$project->find_or_create_related( 'projectprops',
#	  #				  { type => $factor_term,
#	  #				    value => "stockprops:type_id==$type_id->value",
#	  #				  }
#	  #				);
#
#	} else {
#	  croak "could not find a cvterm for stock '$sample_name' via db:acc '$factor_source:$factor_acc'\n";
#	}
#
#
#      }
#    }
  }

  return $stock;
}

=head2 projects

convenience search distinct for all related projects

=cut

sub projects {
  my ($self) = @_;
  return $self->search_related('nd_experiment_stocks')->search_related('nd_experiment')->search_related('nd_experiment_projects')->search_related('project', {}, { distinct=>1 });
}

=head2 search_by_project

usage:
  $resultset = $stocks->search_by_project({ 'project.name' => { in => [ 'name1', 'name2' ] }});

Filters stocks based on a query of the projects attached via nd_experiment.
Does not join to projectprops.

=cut

sub search_by_project {
  my ($self, $query) = @_;

  croak "search_by_project argument must be a hash ref\n" unless (ref($query) eq 'HASH');

  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     { nd_experiment_projects => 'project' }}}});
}

=head2 search_by_nd_experimentprop

Usage:
  $resultset = $stocks->search_by_nd_experimentprop( { 'type.name' => 'start date',
                                                       'value' => { like => '2005%' } } );

=cut

sub search_by_nd_experimentprop {
  my ($self, $query) = @_;
  croak "search_by_nd_experimentprop argument must be a hash ref\n" unless (ref($query) eq 'HASH');
  return $self->search_by_nd_experimentprops(1,$query);
}

=head2 search_by_nd_experimentprops

Usage:
  $resultset = $stocks->search_by_nd_experimentprops(2,
                 { 'type.name' => 'start date',
                   'nd_experimentprops.value' => { like => '2005%' },
                   'type_2.name' => 'end date',
                   'nd_experimentprops_2.value' => { like => '2005%' },
                 });

Use this where you want an experiment that was performed straddling a particular date,
or perhaps on a date AND at a time.

First argument is the number of times we want to join to the props table
Second argument is the query - check the example above for the _2 _3 syntax - this
is because the underlying query is a multiple join to the same table(s).

=cut

sub search_by_nd_experimentprops {
  my ($self, $num, $query) = @_;
  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     [ ({nd_experimentprops => { type => { dbxref => 'db' }}}) x $num ] }}});
}

=head2 search_by_nd_geolocationprop

Usage:
  $resultset = $stocks->search_by_nd_geolocationprop( { 'type.name' => 'collection site country',
                                                        'value' => 'Mali' } );

=cut

sub search_by_nd_geolocationprop {
  my ($self, $query) = @_;

  croak "search_by_nd_geolocationprop argument must be a hash ref\n" unless (ref($query) eq 'HASH');

  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     { nd_geolocation =>
				       { nd_geolocationprops =>
					 { type => { dbxref => 'db' }}}}}}});
}


=head2 search_by_nd_protocolprop

Usage:
  $resultset = $stocks->search_by_nd_protocolprop( { 'type.name' => 'direct bioassay' } );

=cut

sub search_by_nd_protocolprop {
  my ($self, $query) = @_;

  croak "search_by_nd_protocolprop argument must be a hash ref\n" unless (ref($query) eq 'HASH');

  return $self->search_by_nd_protocolprops(1, $query);
# 		       { join => { nd_experiment_stocks =>
# 				   { nd_experiment =>
# 				     { nd_experiment_protocols =>
# 				       { nd_protocol =>
# 					 { nd_protocolprops =>
# 					   { type => { dbxref => 'db' }}}}}}}});
}

=head2 search_by_nd_protocolprops

Usage:
  $resultset = $stocks->search_by_nd_protocolprop(2,  { 'type.name' => 'direct bioassay', 'type_2.name' => 'concentration' } );

=cut

sub search_by_nd_protocolprops {
  my ($self, $num, $query) = @_;
  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     { nd_experiment_protocols =>
				       { nd_protocol =>
					 [ ({nd_protocolprops => { type => { dbxref => 'db' }}}) x $num ] }}}}});
}



=head2 search_by_phenotype

Usage:
  $resultset = $stocks->search_by_phenotype( { 'observable.name' => '% mortality' } );

=cut

sub search_by_phenotype {
  my ($self, $query) = @_;

  croak "search_by_phenotype argument must be a hash ref\n" unless (ref($query) eq 'HASH');

  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     { nd_experiment_phenotypes =>
				       { phenotype => [ qw/observable attr cvalue/ ] }}}}});
}


=head2 search_by_species_identification_assay_result

Usage:
  $resultset = $stocks->search_by_species_identification_assay_result( { 'type.name' => { like => 'Anopheles %' }} );

This won't work in combination with other nd_experimentprop searches.
It does work as $project->stocks->search_by_species_identification_assay_result().
It will need to be changed when we move to genotype + genotypeprop storage of these results.

=cut

sub search_by_species_identification_assay_result {
  my ($self, $query) = @_;
  croak "search_by_species_identification_assay_result argument must be a hash ref\n" unless (ref($query) eq 'HASH');
  return $self->search($query,
		       { join => { nd_experiment_stocks =>
				   { nd_experiment =>
				     [
				      { nd_experimentprops => 'type' },
							'type'
				     ] }}})->search({ 'type_2.name' => 'species identification assay' });
}


=head1 TO DO

Definitely need some more date-aware search functions.

May need to use SQL literal queries to call server-side SQL date conversion functions
so that we can use less/greater than range queries.


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
