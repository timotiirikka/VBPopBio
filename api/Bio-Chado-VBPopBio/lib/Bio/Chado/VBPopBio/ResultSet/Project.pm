package Bio::Chado::VBPopBio::ResultSet::Project;

use strict;
use base 'DBIx::Class::ResultSet';
use Carp;
use Bio::Parser::ISATab;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Project

=head1 SYNOPSIS

Project resultset with extra convenience functions


=head1 SUBROUTINES/METHODS

=head2 experiments

alias for nd_experiments

=cut

sub experiments {
  my $self = shift;
  return $self->nd_experiments;
}



=head2 create_from_isatab

 Usage: $projects->create_from_isatab({ directory   => 'isatab/directory' });

 Desc: This method loads the ISA-Tab data and creates a project corresponding to ONE study in the ISA-Tab file.
 Ret : a new Project row
 Args: hashref of:
         { directory   => 'my_isatab_directory',
         }

When we eventually support multi-study ISA-Tab, we will have to
link them to the "investigation" with the project_relationship table.

=cut

sub create_from_isatab {
  my ($self, $opts) = @_;

  croak "No valid ISA-Tab directory supplied" unless ($opts->{directory} && -d $opts->{directory});

  my $parser = Bio::Parser::ISATab->new(directory=>$opts->{directory});
  my $isa = $parser->parse();
  my @studies = @{$isa->{studies}};
  croak "No studies in ISA-Tab" unless (@studies);
  croak "Multiple studies not yet supported" if (@studies > 1);

  my $ontologies = $isa->{ontology_lookup};
  carp "Warning, no ontologies in ISA-Tab" unless (keys %$ontologies);

  my $schema = $self->result_source->schema;
  my $cvterms = $schema->cvterms;

  my $study = shift @studies;
  # do some sanity checks
  my $study_title = $study->{study_title};
  croak "Study has no title" unless ($study_title);
  my $study_description = $study->{study_description};
  croak "Study has no description" unless ($study_description);
  my $study_external_id = $study->{study_identifier};
  croak "Study has no external ID" unless ($study_external_id);

  my $proj_extID_type = $schema->types->project_external_ID;

  #
  # check for project with project external ID already
  # (has been tested, but is not in a test suite)
  #
  croak "A project is already loaded with external ID '$study_external_id' - aborting."
    if ($self->find_by_external_id($study_external_id));

  #
  # now create the project object
  # it will fail with runtime exception if 'name' exists
  #
  my $project = $self->create( {
				name => $study_title,
				description => $study_description,
			       } );
  $project->external_id($study_external_id);

  warn "TO DO: project study factors\n";


  # getting the stable ID creates one
  # should there be an alias/wrapper for stable_id such as reserve_stable_id
  my $stable_id = $project->stable_id;
  croak "cannot create/retrieve a stable ID" unless ($stable_id);

  foreach my $study_contact (@{$study->{study_contacts}}) {
    warn "TO DO: add project contact $study_contact->{study_person_last_name}\n";
  }

  # create stand-alone stocks
  # these are pulled out of the $study hash tree in the order
  # they were first seen in the ISA-Tab files

  my $stocks = $schema->stocks;
  my %stocks;
  while (my ($source_id, $source_data) = each %{$study->{sources}}) {

    # we are currently ignoring all source annotations
    $schema->defer_exception("ISA-Tab Source characteristics/protocols were encountered but no code exists to load them")
      if (keys %{$source_data->{characteristics}} || keys %{$source_data->{protocols}});

    while (my ($sample_id, $sample_data) = each %{$source_data->{samples}}) {
      my $stock = $stocks->find_or_create_from_isatab($sample_id, $sample_data, $project, $ontologies, $study);
      $stocks{$sample_id} = $stock;
      $project->add_to_stocks($stock);
    }
  }

  # add nd_experiments for stocks (and link these to project)

  my $assays = $study->{study_assay_lookup};
  # this lookup is new to Bio::Parser::ISATab on 13 April 2011 on github
  croak "missing study_assay_lookup - need to update ISATab parser?" unless (defined $assays);

  #
  # add various nd_experiments for each stock
  #

  my $fc_data = $assays->{"field collection"}; my %field_collections;
  my $si_data = $assays->{"species identification assay"};   my %species_identification_assays;
  my $ga_data = $assays->{"genotype assay"};   my %genotype_assays;
  my $pa_data = $assays->{"phenotype assay"};  my %phenotype_assays;

  my $assay_creates_stock = $cvterms->create_with({ name => 'assay creates stock', # discuss this more
						    cv => 'VBcv',
						  });
  my $assay_uses_stock = $cvterms->create_with({ name => 'assay uses stock', # discuss this more
						    cv => 'VBcv',
						  });


  # for each stock that we already added
  while (my ($sample_id, $stock) = each %stocks) {

    # FIELD COLLECTION
    if (defined $fc_data) {
      if (defined(my $sample_data = $fc_data->{samples}{$sample_id})) {
	while (my ($assay_name, $assay_data) = each %{$sample_data->{assays}}) {
	  $field_collections{$assay_name} ||= $schema->field_collections->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study);
	  # link each field collection (newly created or already existing) to the stock
	  $field_collections{$assay_name}->add_to_stocks($stock, { type => $assay_creates_stock }) ;
	  # you could have added linker props with the following inside the second argument
	  # nd_experiment_stockprops => [ { type => $some_cvterm, value => 77 } ]
	}
      } else {
	# need a warning for missing assay data?
      }
    }

    # SPECIES IDENTIFICATION ASSAY
    if (defined $si_data) {
      if (defined(my $sample_data = $si_data->{samples}{$sample_id})) {
	while (my ($assay_name, $assay_data) = each %{$sample_data->{assays}}) {
	  $species_identification_assays{$assay_name} ||= $schema->species_identification_assays->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study);
	  $species_identification_assays{$assay_name}->add_to_stocks($stock, { type => $assay_uses_stock });
	  # this assay also 'produces' a stock (which contains the organism information)
	  # but that is linked within ResultSet::SpeciesIdentificationAssay
	}
      } else {
	# need a warning for missing assay data?
      }
    }


    # GENOTYPE ASSAY
    if (defined $ga_data) {
      if (defined(my $sample_data = $ga_data->{samples}{$sample_id})) {
	while (my ($assay_name, $assay_data) = each %{$sample_data->{assays}}) {
	  $genotype_assays{$assay_name} ||= $schema->genotype_assays->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study, $parser);
	  $genotype_assays{$assay_name}->add_to_stocks($stock, { type => $assay_uses_stock });
	}
      } else {
	# need a warning for missing assay data?
      }
    }

    # PHENOTYPE ASSAY
    if (defined $pa_data) {
      if (defined(my $sample_data = $pa_data->{samples}{$sample_id})) {
	while (my ($assay_name, $assay_data) = each %{$sample_data->{assays}}) {
	  $phenotype_assays{$assay_name} ||= $schema->phenotype_assays->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study, $parser);
	  $phenotype_assays{$assay_name}->add_to_stocks($stock, { type => $assay_uses_stock });
	}
      } else {
	# need a warning for missing assay data?
      }
    }

  }




#  use Data::Dumper;
#  $Data::Dumper::Indent = 1;
#  carp Dumper($isa);

  return $project;
}


=head2 find_by_stable_id 

Returns a project result by stable id.

Because there's no direct link between the dbxref and the project, the
route is a bit tortuous.  Looks for VBP dbxref with the accession then
finds the external_id - then looks for the project with the
external_id as a projectprop.

=cut

sub find_by_stable_id {
  my ($self, $stable_id) = @_;
  my $schema = $self->result_source->schema;
  my $proj_extID_type = $schema->types->project_external_ID;
  my $db = $schema->dbs->find_or_create({ name => 'VBP' });

  my $search = $db->dbxrefs->search({ accession => $stable_id });
  if ($search->count == 1) {
    # now get the external id from the dbxrefprops
    my $dbxref = $search->first;
    my $propsearch = $dbxref->dbxrefprops->search({ type_id => $proj_extID_type->id });
    if ($propsearch->count == 1) {
      my $external_id = $propsearch->first->value;
      return $self->find_by_external_id($external_id);
    }
  }
  return undef;
}

=head2 find_by_external_id

look up the project via projectprops external id

=cut


sub find_by_external_id {
  my ($self, $external_id) = @_;
  my $schema = $self->result_source->schema;
  my $proj_extID_type = $schema->types->project_external_ID;
  my $search = $self->search_related
    ("projectprops",
     {
      type_id => $proj_extID_type->id,
      value => $external_id,
     }
    );
  if ($search->count == 1) {
    return $search->first->project;
  }

  return undef;
}

=head2 stocks

returns the stocks linked to the project via add_to_stocks()

=cut

sub stocks {
  my ($self, $stock) = @_;
  my $link_type = $self->result_source->schema->types->project_stock_link;
  return $self->search_related('project_stocks',
			       {
				# no search terms
			       },
			       {
				bind => [ $link_type->id ],
			       }
			      )->search_related('stock', { }, { distinct => 1  });
}

=head2 looks_like_stable_id

check to see if VBP\d{7}

=cut

sub looks_like_stable_id {
  my ($self, $id) = @_;
  return $id =~ /^VBP\d{7}$/;
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
