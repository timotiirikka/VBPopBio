package Bio::Chado::VBPopBio::Result::Experiment::SpeciesIdentificationAssay;

use base 'Bio::Chado::VBPopBio::Result::Experiment';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({ }); # must call this routine even if not setting up relationships.

=head1 NAME

Bio::Chado::VBPopBio::Result::Experiment::SpeciesIdentificationAssay

=head1 SYNOPSIS

Genotype assay


=head1 SUBROUTINES/METHODS

=head2 special

Do something special for species identification assay

=cut

sub special {
  my ($self) = @_;
  return 'I am very special';
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
