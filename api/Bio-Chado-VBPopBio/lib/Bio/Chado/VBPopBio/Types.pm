package Bio::Chado::VBPopBio::Types;

use Moose;


=head1 NAME

Bio::Chado::VBPopBio::Types

=head1 SYNOPSIS

Single class to provide commonly used cvterms used as types in props.

  my $props = $project->search_related('projectprops',
	       { type_id => $schema->types->project_external_ID->id });

=cut

=head1 ATTRIBUTES

=head2 schema

=cut

has 'schema' => (
		 is => 'ro',
		 isa => 'Bio::Chado::VBPopBio',
		 required => 1,
		);

=head2 project_external_ID

User-provided ID for projects, e.g. 2011-Smith-Mali-Aedes-larvae

=cut

sub project_external_ID {
  my $self = shift;
  return $self->schema->cvterms->create_with
    ({ name => 'project external ID',
       cv => 'VBcv',
       description => 'An ID of the format YYYY-AuthorSurname-Keyword(s) - '.
       'should be unique with respect to all VectorBase population data submissions.'
     });
}

=head2 sample_external_ID

User-provided ID for samples, e.g. Mali-1234

=cut

sub sample_external_ID {
  my $self = shift;
  return $self->schema->cvterms->create_with
    ({ name => 'sample external ID',
       cv => 'VBcv',
       description => 'A sample ID (originating in ISA-Tab Sample Name column).'.
       'It need not follow any formatting rules, but it'.
       'should be unique within a data submission.'
     });
}

=head2 experiment_external_ID

User-provided ID for experiments, e.g. Mali-1234

=cut

sub experiment_external_ID {
  my $self = shift;
  return $self->schema->cvterms->create_with
    ({ name => 'experiment external ID',
       cv => 'VBcv',
       description => 'An experiment ID (originating in ISA-Tab Assay Name column).'.
       'It need not follow any formatting rules, but it'.
       'should be unique within the entire ISA-Tab data submission.'
     });
}

=head2 start_date

VBcv:start date

=cut

sub start_date {
  my $self = shift;
  return $self->schema->cvterms->find_by_name({ term_source_ref => 'VBcv',
						term_name => 'start date' });

}

=head2 end_date

VBcv:end date

=cut

sub end_date {
  my $self = shift;
  return $self->schema->cvterms->find_by_name({ term_source_ref => 'VBcv',
						term_name => 'end date' });
}

=head2 placeholder

any old term

=cut

sub placeholder {
  my $self = shift;
  return $self->schema->cvterms->find_by_accession( { term_source_ref => 'VBcv',
						      term_accession_number => '0000000',
						    } );
}


=head1 nd_experiment.type values

=head2 field_collection

=cut

sub field_collection {
  my $self = shift;
  return $self->schema->cvterms->find_by_name({ term_name => 'field collection',
						term_source_ref => 'VBcv',
					      });
}

=head2 phenotype_assay

=cut


sub phenotype_assay {
  my $self = shift;
  return $self->schema->cvterms->find_by_name({ term_name => 'phenotype assay',
						term_source_ref => 'VBcv',
					      });
}

=head2 genotype_assay

=cut

sub genotype_assay {
  my $self = shift;
  return $self->schema->cvterms->find_by_name({ term_name => 'genotype assay',
						term_source_ref => 'VBcv',
					      });
}

=head2 species_identification_assay

=cut

sub species_identification_assay {
  my $self = shift;
  return $self->schema->cvterms->create_with({ name => 'species identification assay',
					       cv => 'TEMPcv',
					       db => 'TEMPcv',
					       dbxref => 'species_id_assay',
					     });
}

1;
