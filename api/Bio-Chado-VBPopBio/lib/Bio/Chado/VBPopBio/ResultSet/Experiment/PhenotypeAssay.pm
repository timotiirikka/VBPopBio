package Bio::Chado::VBPopBio::ResultSet::Experiment::PhenotypeAssay;

use base 'Bio::Chado::VBPopBio::ResultSet::Experiment';
use Carp;
use strict;

use Bio::Chado::VBPopBio::Util::Phenote qw/parse_phenote/;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Experiment::PhenotypeAssay

=head1 SYNOPSIS

PhenotypeAssay resultset with extra convenience functions


=head1 SUBROUTINES/METHODS

=head2 new

overloaded constructor adds default resultset filtering on phenotype assay type_id

=cut

sub new {
  my ($class, $source, $attribs) = @_;
  if (keys %{$attribs} == 0) {
    my $type = $source->schema->types->phenotype_assay;
    $attribs = { where => { 'type_id' => $type->cvterm_id } };
  }
  return $class->SUPER::new($source, $attribs);
}

=head2 create_from_isatab

 Usage: $phenotype_assays->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study, $isa_parser);

 Desc: This method creates genoype assay nd_experiment from the isatab assay sample hashref
 Ret : a new Experiment::PhenotypeAssay row (is a NdExperiment)
 Args: string ASSAY_NAME
       hashref $isa->{studies}[N]{study_assay_lookup}{'phenotype assay'}{samples}{SAMPLE_NAME}{assays}{ASSAY_NAME}
       Project object (Bio::Chado::VBPopBio)
       hashref $isa->{ontology_lookup} from ISA-Tab returned from Bio::Parser::ISATab
       hashref ISA-Tab current study (used for protocols)
       Bio::Parser::ISATab object

=cut

my %phenote_data_cache; # see GenotypeAssay.pm

sub create_from_isatab {
  my ($self, $assay_name, $assay_data, $project, $ontologies, $study, $isa_parser) = @_;
  my $schema = $self->result_source->schema;

  if ($self->looks_like_stable_id($assay_name)) {
    my $existing_experiment = $self->find_by_stable_id($assay_name);
    if (defined $existing_experiment) {
      $existing_experiment->add_to_projects($project);
      return $existing_experiment;
    }
    $schema->defer_exception("$assay_name looks like a stable ID but we couldn't find it in the database");
  }

  # create the nd_experiment and stock linker type
  my $cvterms = $schema->cvterms;
  my $dbxrefs = $schema->dbxrefs;
  my $phenotypes = $schema->phenotypes;

  # always create a new nd_experiment object
  my $phenotype_assay = $self->create();
  $phenotype_assay->external_id($assay_name);
  my $stable_id = $phenotype_assay->stable_id($project);

  # add it to the project
  $phenotype_assay->add_to_projects($project);

  # add the protocols
  $phenotype_assay->add_to_protocols_from_isatab($assay_data->{protocols}, $ontologies, $study);

  # load the phenotype data from the phenote file(s)
  foreach my $phenote_file_name (keys %{$assay_data->{raw_data_files}}) {
    my $phenote =
      $phenote_data_cache{$isa_parser->directory.'/'.$phenote_file_name} ||=
	parse_phenote($phenote_file_name, $isa_parser, 'Assay');

    my @prop_rows;
    my @unique_info;
    # now loop through the rows for this particular assay and add the phenotypes first
    foreach my $row (@{$phenote->{$assay_name}}) {
      # gather this for each phenotype and its preceding properties
      push @unique_info, $row->{'Entity Name'}, $row->{'Attribute Name'}, $row->{'Quality Name'}, $row->{Value};

      croak "Units not handled by phenotype loader yet." if ($row->{'Unit Name'} || $row->{'Unit ID'});

      if ($row->{'prop?'}) {
	push @prop_rows, $row; # deal with props later
      } else {
	# create the phenotype
	my ($entity, $attribute, $quality);

	if ($row->{'Entity ID'} =~ /^(.+):(.+)$/) {
	  my ($db, $acc) = ($1, $2);
	  $entity = $dbxrefs->find({ accession => $acc, version => '', 'db.name' => $db },
				   { join => 'db' })->cvterm or croak "can't find cvterm for entity $db:$acc";
	}
	if ($row->{'Attribute ID'} =~ /^(.+):(.+)$/) {
	  my ($db, $acc) = ($1, $2);
	  $attribute = $dbxrefs->find({ accession => $acc, version => '', 'db.name' => $db },
				      { join => 'db' })->cvterm or croak "can't find cvterm for attribute $db:$acc";
	}
	if ($row->{'Quality ID'} =~ /^(.+):(.+)$/) {
	  my ($db, $acc) = ($1, $2);
	  $quality = $dbxrefs->find({ accession => $acc, version => '', 'db.name' => $db },
				    { join => 'db' })->cvterm or croak "can't find cvterm for quality $db:$acc";
	}
	my $value = $row->{Value};

	my $phenotype = $phenotypes->find_or_create({
						     uniquename => join(':',@unique_info),
						     defined $entity ? ( observable => $entity ) : (),
						     defined $attribute ? ( attr => $attribute ) : (),
						     defined $quality ? ( cvalue => $quality ) : ( value => $value ),
						    });

	@unique_info = ();

	# link to the nd_experiment
	my $assay_link = $phenotype->find_or_create_related('nd_experiment_phenotypes',
							    { nd_experiment => $phenotype_assay });

	# now add the phenotypeprops that we already encountered in the phenote file
	# this time, only add a ontologised term (silently skip any with no db:acc provided)
	while (my $prop_row = shift @prop_rows) {

	  croak "Loader can't handle phenotype props yet.";
	  # see GenotypeAssay.pm for how to implement this
	}
      }
    }
  }

  return $phenotype_assay;

}

=head2 _type

private method to return type cvterm for this subclass

=cut

sub _type {
  my ($self) = @_;
  return $self->result_source->schema->types->phenotype_assay;
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
