package Bio::Chado::VBPopBio::Result::Protocol;

use strict;
use Carp;
use feature 'switch';
use base 'Bio::Chado::Schema::Result::NaturalDiversity::NdProtocol';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({ nd_experiment_protocols => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentProtocol',
		        nd_protocolprops => 'Bio::Chado::VBPopBio::Result::Protocolprop',
			type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Protocol

=head1 SYNOPSIS

Protocol object with extra convenience functions.
Specialised experiment classes can be found in the.
Bio::Chado::VBPopBio::Result::Experiment::* namespace.

=head1 MANY-TO-MANY RELATIONSHIPS

=head2 nd_experiments

Type: many_to_many

Returns a list of nd_experiments

Related object: Bio::Chado::Schema::Result::NaturalDiversity::NdExperiment

=cut

__PACKAGE__->many_to_many
    (
     'nd_experiments',
     'nd_experiment_protocols' => 'nd_experiment',
    );


=head1 CONVENIENCE METHODS

=head2 create_nd_protocolprops

  Usage: $set->create_nd_protocolprops({ baz => 2, foo => 'bar' });
  Desc : convenience method to create experiment properties using cvterms
          from the ontology with the given name
  Args : hashref of { propname => value, ...},
         options hashref as:
          {
            autocreate => 0,
               (optional) boolean, if passed, automatically create cv,
               cvterm, and dbxref rows if one cannot be found for the
               given experimentprop name.  Default false.

            cv_name => cv.name to use for the given experimentprops.
                       Defaults to 'nd_protocol_property',

            db_name => db.name to use for autocreated dbxrefs,
                       default 'null',

            dbxref_accession_prefix => optional, default
                                       'autocreated:',
            definitions => optional hashref of:
                { cvterm_name => definition,
                }
             to load into the cvterm table when autocreating cvterms

             rank => force numeric rank. Be careful not to pass ranks that already exist
                     for the property type. The function will die in such case.

             allow_duplicate_values => default false.
                If true, allow duplicate instances of the same experiment
                and types in the properties of the experiment.  Duplicate
                types will have different ranks.
          }
  Ret  : hashref of { propname => new experimentprop object }

=cut

sub create_nd_protocolprops {
    my ($self, $props, $opts) = @_;

    # process opts
    $opts->{cv_name} = 'nd_protocol_property'
        unless defined $opts->{cv_name};
    return Bio::Chado::Schema::Util->create_properties
        ( properties => $props,
          options    => $opts,
          row        => $self,
          prop_relation_name => 'nd_protocolprops',
        );
}


=head1 SUBROUTINES/METHODS

=head1 AUTHOR

VectorBase, C<< <info at vectorbase.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 VectorBase.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Bio::Chado::VBPopBio::Result::Protocol
