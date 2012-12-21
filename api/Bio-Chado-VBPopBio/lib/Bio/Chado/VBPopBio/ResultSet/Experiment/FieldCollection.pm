package Bio::Chado::VBPopBio::ResultSet::Experiment::FieldCollection;

use base 'Bio::Chado::VBPopBio::ResultSet::Experiment';
use Carp;
use strict;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Experiment::FieldCollection

=head1 SYNOPSIS

FieldCollection resultset with extra convenience functions

    my $fcs = $schema->field_collections()->search_on_something_location_related_xxx(...);

=head1 SUBROUTINES/METHODS

=head2 new

overloaded constructor adds default resultset filtering on field collection type_id

=cut

sub new {
  my ($class, $source, $attribs) = @_;
  $attribs = {} unless $attribs;
  $attribs->{where}{type_id} = $source->schema->types->field_collection->cvterm_id;
  return $class->SUPER::new($source, $attribs);
}

=head2 create_from_isatab

 Usage: $field_collections->create_from_isatab($assay_name, $isatab_assay_data, $project, $ontologies, $study);

 Desc: This method creates a FieldCollection nd_experiment object from the isatab assay sample hashref
       (from a field collection assay)
 Ret : a new Experiment::FieldCollection row (is a NdExperiment)
 Args: hashref $isa->{studies}[N]{study_assay_lookup}{'field collection'}{samples}{SAMPLE_ID}
       (example contents below)
         {
           characteristics => { 'Collection site' => { value => 'Kela',
                                                       term_accession_number => 123,
                                                       term_source_ref => 'GAZ' } },
         }
       Project object (Bio::Chado::VBPopBio)
       hashref $isa->{ontology_lookup} from ISA-Tab returned from Bio::Parser::ISATab
       hashref ISA-Tab current study (used for protocols)

=cut

sub create_from_isatab {
  my ($self, $assay_name, $assay_data, $project, $ontologies, $study) = @_;

  my $field_collection = $self->find_and_link_existing($assay_name, $project);

  unless (defined $field_collection) {

    # create the nd_experiment and stock linker type
    my $schema = $self->result_source->schema;
    my $cvterms = $schema->cvterms;

    # potentially re-use a geolocation
    my $geolocations = $schema->geolocations;
    my $geolocation = $geolocations->find_or_create_from_isatab($assay_data, $ontologies, $study);

    # always create a new nd_experiment object
    $field_collection = $self->create({ nd_geolocation => $geolocation });
    $field_collection->external_id($assay_name);
    my $stable_id = $field_collection->stable_id($project);

    # link it to the project
    $field_collection->add_to_projects($project);

    # add the protocols
    $field_collection->add_to_protocols_from_isatab($assay_data->{protocols}, $ontologies, $study);

    # dates
    my $date;
    if (defined ($date = $assay_data->{characteristics}{'Collection start date'}{value})) {
      $field_collection->find_or_create_related('nd_experimentprops',
						{ type => $schema->types->start_date,
						  value => sanitise_date($date) } );
    }
    if (defined ($date =
		 $assay_data->{characteristics}{'Collection end date'}{value} ||
		 $assay_data->{characteristics}{'Collection start date'}{value} )) {
      $field_collection->find_or_create_related('nd_experimentprops',
						{ type => $schema->types->end_date,
						  value => sanitise_date($date) });
    }

    # Collection method - add nd_experimentprop only if defined with CV+ACC

    my $cm_data = $assay_data->{characteristics}{'Collection method'};
    if (defined $cm_data && $cm_data->{term_source_ref} && $cm_data->{term_accession_number}) {
      warn "Loading deprecated 'Characteristics [Collection method]' as an nd_protocol + props...\n";

      # load the protocol info the 'new' way with fabricated ISA-Tab information
      # that we would normally get from the $study isa
      # (the 'new' way is to have a Protocol REF column + Parameter Values in the assay table)
      #
      $field_collection->add_to_protocols_from_isatab({ 'collection' => { } },
						      $ontologies,
						      {
						       study_identifier => $study->{study_identifier},
						       study_protocol_lookup =>
						       { 'collection' =>
							 {
							  study_protocol_type => $cm_data->{value},
							  study_protocol_type_term_source_ref => $cm_data->{term_source_ref},
							  study_protocol_type_term_accession_number => $cm_data->{term_accession_number},
							 }
						       }
						      });

      ### this is how we used to load the nd_experimentprop
      #
      #    my $dbname = $cm_data->{term_source_ref};
      #    my $acc = $cm_data->{term_accession_number};
      #    my $cvterm = $cvterms->find( { 'dbxref.accession' => $acc,
      #				   'db.name' => $dbname,
      #				 },
      #				 { join => { 'dbxref' => 'db' } });
      #    if (defined $cvterm) {
      #      $field_collection->find_or_create_related('nd_experimentprops',
      #						{ type => $cvterm,
      #						  value => '',
      #						});
      #    } else {
      #      carp "Couldn't find collection method via $dbname:$acc\n";
      #    }
    }

    # also add temperature, etc
    # also add nd_experiment_contacts
  }
  return $field_collection;
}


=head2 _type

private method to return type cvterm for this subclass

=cut

sub _type {
  my ($self) = @_;
  return $self->result_source->schema->types->field_collection;
}

=head2 sanitise_date

some dates have zeroes instead of nothing (e.g. 2001-00-00 should really just be 2001)

=cut

sub sanitise_date {
  my $date = shift;
  # fix the zero month/day thing
  $date =~ s/-00.*//;
  # fix other things (other delimiters?)


  return $date
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
