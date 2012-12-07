package Bio::Chado::VBPopBio::Result::Genotype;

use base 'Bio::Chado::Schema::Result::Genetic::Genotype';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       nd_experiment_genotypes => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentGenotype',
		       genotypeprops => 'Bio::Chado::VBPopBio::Result::Genotypeprop',
		       type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Genotype

=head1 SYNOPSIS

Genotype object with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self, $seen) = @_;
  return {
	  name => $self->name,
	  uniquename => $self->uniquename,
	  description => $self->description,
	 #  props => [ map { $_->as_data_structure } $self->genotypeprops ],
	  warning => 'Bob needs to do more on genotype serialisation',
	 };
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

1; # End of Bio::Chado::VBPopBio::Result::Genotype
