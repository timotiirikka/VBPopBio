package Bio::Chado::VBPopBio::Result::Phenotype;

use base 'Bio::Chado::Schema::Result::Phenotype::Phenotype';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       nd_experiment_phenotypes => 'Bio::Chado::VBPopBio::Result::Linker::ExperimentPhenotype',
		       assay => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       attr => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       observable => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       cvalue => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Phenotype

=head1 SYNOPSIS

Phenotype object with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 as_data_for_jsonref

returns a json-like hashref of arrayrefs and hashrefs

this method is specifically for dojox.json.ref style json

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 'pt'.$self->phenotype_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
#    $self->discard_changes unless ($self->has_column_loaded('uniquename'));
    return {
	    id => $id,
	    uniquename => $self->uniquename,
	    observable => display_cvterm($self->observable),
	    attribute => display_cvterm($self->attr),
	    cvalue => display_cvterm($self->cvalue),
	    value => $self->value,
	   };
  }
}

=head2 display_cvterm

Likely to be deprecated method to produce a single text string for the term

=cut

sub display_cvterm {
  my ($cvterm) = @_;
  return $cvterm ? $cvterm->cv->name.':'.$cvterm->name : undef;
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

1; # End of Bio::Chado::VBPopBio::Result::Phenotype
