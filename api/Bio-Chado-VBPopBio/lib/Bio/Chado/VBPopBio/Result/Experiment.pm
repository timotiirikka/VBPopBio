package Bio::Chado::VBPopBio::Result::Experiment;

use strict;
use Carp;
use feature 'switch';
use base 'Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass DynamicSubclass/);
__PACKAGE__->subclass({ nd_experiment_stocks => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentStock',
		        nd_geolocation => 'Bio::Chado::VBPopBio::Result::Geolocation',
			nd_experimentprops => 'Bio::Chado::VBPopBio::Result::Experimentprop',
		        nd_experiment_protocols => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentProtocol',
		        nd_experiment_genotypes => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentGenotype',
		        nd_experiment_phenotypes => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentPhenotype',
			type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

__PACKAGE__->typecast_column('type_id');

=head1 NAME

Bio::Chado::VBPopBio::Result::Experiment

=head1 SYNOPSIS

Experiment object with extra convenience functions.
Specialised experiment classes can be found in the.
Bio::Chado::VBPopBio::Result::Experiment::* namespace.


=head1 SUBROUTINES/METHODS

=head2 stocks

Get all stocks for this experiment.

=cut

###
# now provided by Bio::Chado::Schema (http://github.com/bobular/Bio-Chado-Schema)
###
# sub stocks {
#   my ($self) = @_;
#   return $self->search_related('nd_experiment_stocks')->search_related('stock');
# }
###

=head2 properties

=cut

sub properties {
  my ($self) = @_;
  return $self->search_related('nd_experimentprops', {}, { order_by => 'rank' });
}

=head2 classify

Sets correct subclass (FieldCollection, PhenotypeAssay etc) when object is
created, fetched or have its type value changed.  Not for general
use.  See DBIx::Class::DynamicSubclass.

=cut

sub classify {
  my $self = shift;

  # this is what the new (>5.10) Perl switch statement looks like
  given ($self->type->name) {
    when ('field collection') {
      bless $self, 'Bio::Chado::VBPopBio::Result::Experiment::FieldCollection';
    }
    when ('phenotype assay') {
      bless $self, 'Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay';
    }
    when ('genotype assay') {
      bless $self, 'Bio::Chado::VBPopBio::Result::Experiment::GenotypeAssay';
    }
    when ('species identification assay') {
      bless $self, 'Bio::Chado::VBPopBio::Result::Experiment::SpeciesIdentificationAssay';
    }
    default {
      # do nothing
    }
  }
}



=head2 add_to_protocols_from_isatab

  Usage: $genotype_assay->add_to_protocols_from_isatab($assay_data->{protocols});

  Return value: a Perl list of the protocols added.

  Args:  hashref to $study->{study_assay_lookup}{'some type of assay'}{samples}{SAMPLE_NAME}{assays}{ASSAY_NAME}{protocols}

Adds zero or more protocols from ISA-Tab data.

I guess we are doing this here (in Experiment) to avoid subclassing the NdProtocol class.
But if we have to do that one day, then maybe we should follow the pattern and have a
Protocol::create_from_isatab method.

=cut

sub add_to_protocols_from_isatab {
  my ($self, $protocols_data, $ontologies, $study) = @_;
  my @protocols;

  if ($protocols_data) {
    my $schema = $self->result_source->schema;
    my $protocols = $schema->protocols;
    my $cvterms = $schema->cvterms;
    my $dbxrefs = $schema->dbxrefs;

    while (my ($protocol_ref, $protocol_data) = each %{$protocols_data}) {
      my $protocol_info = $study->{study_protocol_lookup}{$protocol_ref};

      croak "Protocol REF $protocol_ref not described in ISA-Tab" unless ($study->{study_protocol_lookup}{$protocol_ref});

# now that protocols are mostly ontologised (in i_investigation.txt)
# the description shouldn't be mandatory
#      croak "No description for $protocol_ref" unless ($study->{study_protocol_lookup}{$protocol_ref}{study_protocol_description});

      my $protocol_type;

      # protocol.type is mandatory
      if ($protocol_info->{study_protocol_type_term_source_ref} &&
	  length($protocol_info->{study_protocol_type_term_accession_number})) {

	$protocol_type = $cvterms->find_by_accession({ 'term_source_ref' => $protocol_info->{study_protocol_type_term_source_ref},
						       'term_accession_number' => $protocol_info->{study_protocol_type_term_accession_number},
						     });

      }

      if (!defined $protocol_type) {
	# maybe create a placeholder here and store the error
	# $protocol_info->{study_protocol_type}
	$schema->defer_exception("Study Protocol Type ontology term for protocol $protocol_ref missing or not found\n");
	$protocol_type = $schema->types->placeholder;
      }

      my $protocol = $protocols->find_or_create({
						 name => $study->{study_identifier}.":".$protocol_ref,
						 type => $protocol_type,
						});



      if ($protocol_info->{study_protocol_description}) {
	$protocol->create_nd_protocolprops( { description => $protocol_info->{study_protocol_description} },
					    { cv_name => 'VBcv',
					      autocreate => 1,
					    });
      }

      # link this experiment to the protocol
      my $nd_experiment_protocol = $self->find_or_create_related('nd_experiment_protocols', {  nd_protocol => $protocol } );

      if ($protocol_data->{parameter_values}) {

	# if we had a nd_experiment_protocolprops table we could attach the props to $nd_experiment_protocol
	# but we'll have to attach them to the nd_experiment ($self) for now

	while (my ($param_name, $param_data) = each %{$protocol_data->{parameter_values}}) {

	  #
	  # 1. find or create a temporary VBcv cvterm for the parameter TYPE
	  #

	  my $param_type_acc = $protocol_info->{study_protocol_parameter_lookup}{$param_name}{study_protocol_parameter_name_term_accession_number};
	  my $param_type_db = $protocol_info->{study_protocol_parameter_lookup}{$param_name}{study_protocol_parameter_name_term_source_ref};
	  my $param_type_cvterm;
	  if (length($param_type_acc) && $param_type_db) {
	    $param_type_cvterm = $dbxrefs->find({ accession => $param_type_acc,
						  'db.name' => $param_type_db },
						{ join => 'db' })->cvterm;

	  } else {
	    $param_type_cvterm = $cvterms->create_with({ name => $param_name,
							 cv => 'VBcv',
						       });
	  }

	  #
	  # 2. find or create a temporary VBcv term for the parameter value
	  # e.g. insecticide with MIRO term
	  #      unit UO cvterm
	  #      'parameter value' VBcv term
	  my $param_value_cvterm;
	  my $param_value = '';  # what to store in the prop's value field (would prefer undef!)
	  if ($param_data->{term_source_ref} && length($param_data->{term_accession_number})) {
	    $param_value_cvterm = $dbxrefs->find({ accession => $param_data->{term_accession_number},
						   'db.name' => $param_data->{term_source_ref} },
						 { join => 'db' })->cvterm;
	    # $param_value stays unset - ignore any text value provided in ISA-Tab
	  } elsif ($param_data->{unit} && $param_data->{unit}{term_source_ref} &&
		   length($param_data->{unit}{term_accession_number})) {
	    $param_value_cvterm = $dbxrefs->find({ accession => $param_data->{unit}{term_accession_number},
						   'db.name' => $param_data->{unit}{term_source_ref} },
						 { join => 'db' })->cvterm;
	    $param_value = $param_data->{value};
	  } else {
	    $param_value_cvterm = $cvterms->create_with({ name => 'parameter value',
							  cv => 'VBcv',
							});
	    $param_value = $param_data->{value};
	  }

	  #
	  # 3. see if the protocol already has a prop for $param_type_cvterm
	  #    if not, create a new positive rank for it and create the prop
	  #

	  my $rank;
	  my $pp_search = $protocol->search_related('nd_protocolprops',
						    { 'type_id' => $param_type_cvterm->cvterm_id });
	  my $pp_count = $pp_search->count;
	  if ($pp_count > 1) {
	    croak $param_type_cvterm->name." is an nd_protocolprop with two ranks... fatal.";
	  } elsif ($pp_count) {
	    $rank = $pp_search->first->rank;
	  } else {
	    # search for positively ranked props
	    # find out the next available rank
	    $pp_search = $protocol->search_related('nd_protocolprops',
						   { 'rank' => { '>' => 0 } });
	    if ($pp_search->count) {
	      $rank = $pp_search->get_column('rank')->max + 1;
	    } else {
	      $rank = 1;
	    }
	  }

	  #
	  # 4. add the protocolprop ($param_type_cvterm)
	  #

	  $protocol->find_or_create_related('nd_protocolprops',
					    { type => $param_type_cvterm,
					      rank => $rank });
	  #
	  # 5. add both terms as nd_experimentprops
	  #    with the SAME RANK
	  #

	  $self->find_or_create_related('nd_experimentprops',
					{ type => $param_type_cvterm,
					  value => '',
					  rank => $rank
					});


	  $self->find_or_create_related('nd_experimentprops',
					{ type => $param_value_cvterm,
					  value => $param_value,
					  rank => $rank
					});
	}
      }

      push @protocols, $protocol;

#      use Data::Dumper;
#      warn Dumper("just added a protocol",  { $protocol->get_columns, props => [ map { { $_->get_columns } } $protocol->nd_protocolprops ] } );
    }
  }



  return @protocols;
}


=head2 delete

deletes the experiment in a cascade which deletes all would-be orphan related objects

=cut

sub delete {
  my $self = shift;

  my $linkers = $self->related_resultset('nd_experiment_stocks');
  while (my $linker = $linkers->next) {
    # check that the stock is only attached to one experiment (has to be this one)
    if ($linker->stock->experiments->count == 1) {
      $linker->stock->delete;
    }
    $linker->delete;
  }
  my $geoloc = $self->nd_geolocation;
  if ($geoloc->nd_experiments->count == 1) {
    $geoloc->delete;
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

	  'type.name' => $self->type->name,

 	  nd_geolocation => $self->nd_geolocation->as_data_structure,

	  genotypes => [ map {
	    { $_->get_columns,
		genotypeprops => [ map {
		  { 'type.name' => $_->type->name,
		      $_->get_columns,
		    }
		} $_->genotypeprops ],
	      }
	  } $self->genotypes,
		       ],

	  phenotypes => [ map {
	    { $_->get_columns,
		$_->observable ? ( 'observable.name' => $_->observable->name ) : (),
		  $_->attr ? ( 'attr.name' => $_->attr->name ) : (),
		    $_->cvalue ? ( 'cvalue.name' => $_->cvalue->name ) : (),
		  }
	  } $self->phenotypes,
			],

	  nd_experimentprops => [ map {
	    { $_->get_columns,
		'type.name' => $_->type->name,
	      }
	  } $self->nd_experimentprops,
				],

	  nd_protocols => [ map {
	    { $_->get_columns,
		protocolprops => [ map {
		  { 'type.name' => $_->type->name,
		      $_->get_columns,
		  }
		} $_->nd_protocolprops,
				 ],
			       }
	  } $self->nd_protocols
			  ],
	 };
}

=head2 as_data_for_jsonref

returns json-like data with dojox.json.ref references

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 'e'.$self->nd_experiment_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
    return {
	    id => $id,

	    type => $self->type->name, # should be the next line
	    # type => $self->type->cv->name.':'.$self->type->name,

	    genotypes => [ map { $_->as_data_for_jsonref($seen) } $self->genotypes ],
	    phenotypes => [ map { $_->as_data_for_jsonref($seen) } $self->phenotypes ],

	    geolocation => $self->nd_geolocation->as_data_for_jsonref($seen),
	    protocols => [ map { $_->as_data_for_jsonref($seen) } $self->nd_protocols ],

	    props => [ map { $_->as_data_for_jsonref($seen) } $self->nd_experimentprops ],
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

1; # End of Bio::Chado::VBPopBio::Result::Experiment
