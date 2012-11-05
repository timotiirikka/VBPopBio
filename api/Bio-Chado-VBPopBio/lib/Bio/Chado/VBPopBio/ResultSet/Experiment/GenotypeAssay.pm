package Bio::Chado::VBPopBio::ResultSet::Experiment::GenotypeAssay;

use base 'Bio::Chado::VBPopBio::ResultSet::Experiment';
use Carp;
use strict;

use Bio::Chado::VBPopBio::Util::Phenote qw/parse_phenote/;

my %phenote_data_cache; # filename => assay name => [ {heading=>value, ... }, { heading=>value, ... }, ... ]
# the last level is an array of rows in the file (hashrefs, key=>val)

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Experiment::GenotypeAssay

=head1 SYNOPSIS

GenotypeAssay resultset with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 new

overloaded constructor adds default resultset filtering on genotype assay type_id

=cut

sub new {
  my ($class, $source, $attribs) = @_;
  if (keys %{$attribs} == 0) {
    my $type = $source->schema->types->genotype_assay;
    $attribs = { where => { 'type_id' => $type->cvterm_id } };
  }
  return $class->SUPER::new($source, $attribs);
}

=head2 create_from_isatab

 Usage: $genotype_assays->create_from_isatab($assay_name, $assay_data, $project, $ontologies, $study, $isa_parser);

 Desc: This method creates genoype assay nd_experiment from the isatab assay sample hashref
 Ret : a new Experiment::GenotypeAssay row (is a NdExperiment)
 Args: string ASSAY_NAME
       hashref $isa->{studies}[N]{study_assay_lookup}{'genotype assay'}{samples}{SAMPLE_NAME}{assays}{ASSAY_NAME}
       Project object (Bio::Chado::VBPopBio)
       hashref $isa->{ontology_lookup} from ISA-Tab returned from Bio::Parser::ISATab
       hashref ISA-Tab current study (used for protocols)
       Bio::Parser::ISATab object

=cut

sub create_from_isatab {
  my ($self, $assay_name, $assay_data, $project, $ontologies, $study, $isa_parser) = @_;
  my $schema = $self->result_source->schema;

  if ($self->looks_like_stable_id($assay_name)) {
    my $existing_experiment = $self->find_by_stable_id($assay_name);
    if (defined $existing_experiment) {
      my $project_link = $existing_experiment->find_or_create_related('nd_experiment_projects',
								      { project => $project,
								      });
      return $existing_experiment;
    }
    $schema->defer_exception("$assay_name looks like a stable ID but we couldn't find it in the database");
  }

  # create the nd_experiment and stock linker type
  my $cvterms = $schema->cvterms;
  my $dbxrefs = $schema->dbxrefs;
  my $genotypes = $schema->genotypes;

  # always create a new nd_experiment object
  my $genotype_assay = $self->create();
  $genotype_assay->external_id($assay_name);
  my $stable_id = $genotype_assay->stable_id($project);

  my $project_link = $genotype_assay->find_or_create_related('nd_experiment_projects',
							     { project => $project,
							     });


  # add the protocols
  $genotype_assay->add_to_protocols_from_isatab($assay_data->{protocols}, $ontologies, $study);


  # load the genotype data from the phenote file(s)
  foreach my $phenote_file_name (keys %{$assay_data->{raw_data_files}}) {
    my $phenote =
      $phenote_data_cache{$isa_parser->directory.'/'.$phenote_file_name} ||=
	parse_phenote($phenote_file_name, $isa_parser, 'Assay');

    my @prop_rows;
    my @unique_info;
    # now loop through the rows for this particular assay and add the genotypes first
    foreach my $row (@{$phenote->{$assay_name}}) {
      # gather this for each genotype and its preceding properties
      push @unique_info, $row->{'type Name'}, $row->{'Description/Value'};

      if ($row->{'prop?'}) {
	push @prop_rows, $row; # deal with props later
      } else {
	# create the genotype
	my $type;
	if ($row->{'type ID'} =~ /^(.+):(.+)$/) {
	  my ($db, $acc) = ($1, $2);
	  $type = $dbxrefs->find({ accession => $acc, version => '', 'db.name' => $db },
				 { join => 'db' })->cvterm or croak "can't find cvterm for $db:$acc";
	}

	my $description = $row->{'Description/Value'};
	croak "no description for genotype of $assay_name" unless ($description);

	my $genotype = $genotypes->find_or_create({
						   name => $description,
						   uniquename => join(':',@unique_info),
						   description => $description,
						   type => $type,
						  });

	@unique_info = ();

	# link to the nd_experiment
	my $assay_link = $genotype->find_or_create_related('nd_experiment_genotypes',
							   { nd_experiment => $genotype_assay });

	# now add the genotypeprops that we already encountered in the phenote file
	# this time, only add a ontologised term (silently skip any with no db:acc provided
	while (my $prop_row = shift @prop_rows) {
	  if ($prop_row->{'type ID'} =~ /^(.+):(.+)$/) {
	    my ($db, $acc) = ($1, $2);
	    my $type = $dbxrefs->find({ accession => $acc, version => '', 'db.name' => $db },
				      { join => 'db' })->cvterm or croak "can't find cvterm for $db:$acc";

	    $genotype->find_or_create_related('genotypeprops',
					      { type => $type,
						value => $prop_row->{'Description/Value'},
					      });
	  }

	}

      }
    }
  }

  return $genotype_assay;

}


=head2 _type

private method to return type cvterm for this subclass

=cut

sub _type {
  my ($self) = @_;
  return $self->result_source->schema->types->genotype_assay;
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
