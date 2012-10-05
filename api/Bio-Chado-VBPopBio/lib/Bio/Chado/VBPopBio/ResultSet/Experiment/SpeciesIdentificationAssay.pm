package Bio::Chado::VBPopBio::ResultSet::Experiment::SpeciesIdentificationAssay;

use strict;
use base 'Bio::Chado::VBPopBio::ResultSet::Experiment';
use Carp;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Experiment::SpeciesIdentificationAssay

=head1 SYNOPSIS

SpeciesIdentificationAssay resultset with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 new

overloaded constructor adds default resultset filtering on species identification assay type_id

=cut

sub new {
  my ($class, $source, $attribs) = @_;
  if (keys %{$attribs} == 0) {
    my $type = $source->schema->types->species_identification_assay;
    $attribs = { where => { 'type_id' => $type->cvterm_id } };
  }
  return $class->SUPER::new($source, $attribs);
}

=head2 create_from_isatab

 Usage: $species_identification_assays->create_from_isatab($isatab_assay_data, $project, $ontologies, $study);

 Desc: This method creates a stock object from the isatab assay sample hashref
 Ret : a new Experiment::SpeciesIdentificationAssay row (is a NdExperiment)
 Args: hashref $isa->{studies}[N]{study_assay_lookup}{'species identification assay'}{samples}{SAMPLE_NAME}{assays}{ASSAY_NAME}
       Project object (Bio::Chado::VBPopBio)
       hashref $isa->{ontology_lookup} from ISA-Tab returned from Bio::Parser::ISATab
       hashref ISA-Tab current study (used for protocols)

=cut

sub create_from_isatab {
  my ($self, $assay_data, $project, $ontologies, $study) = @_;
  my $schema = $self->result_source->schema;
  my $cvterms = $schema->cvterms;

  # create the nd_experiment and stock linker type

  # always create a new nd_experiment object
  my $species_identification_assay = $self->create();

  my $project_link = $species_identification_assay->find_or_create_related('nd_experiment_projects',
							     { project => $project,
							     });


  $species_identification_assay->add_to_protocols_from_isatab($assay_data->{protocols}, $ontologies, $study);

  # now actually load the assay result!
  # as a nd_experimentprop where type = MIRO species CV term
  if (defined (my $organism_data = $assay_data->{characteristics}{'Organism'})) {

    if (  # ($organism_data->{term_source_ref} eq 'NCBITaxon' ||
	$organism_data->{term_source_ref} eq 'MIRO' &&
	length($organism_data->{term_accession_number})) {

      my $dbname = $organism_data->{term_source_ref};
      my $acc = $organism_data->{term_accession_number};
      my $cvterm = $cvterms->find( { 'dbxref.accession' => $acc,
				       'db.name' => $dbname,
				   },
				   { join => { 'dbxref' => 'db' } });

      croak "Can't find species id results MIRO CV term $dbname:$acc\n" unless ($cvterm);

      $species_identification_assay->find_or_create_related('nd_experimentprops',
							    { type => $cvterm,
							      value => '',
							    });
    }
  }

  return $species_identification_assay;

}


=head2 _type

private method to return type cvterm for this subclass

=cut

sub _type {
  my ($self) = @_;
  return $self->result_source->schema->types->species_identification_assay;
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
