package Bio::Chado::VBPopBio::Result::Cvterm;

use base 'Bio::Chado::Schema::Result::Cv::Cvterm';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       # we could have a huge list of relationships here
		       # e.g. nd_experiments, stocks...
                       # but let's add them if/as we need them
		      });

# this is needed because the BCS Cvterm result class manually
# calls resultset_class() so we have to do the same here
# to avoid runtime warnings and incorrect assignment of the cvterm resultset
__PACKAGE__->resultset_class('Bio::Chado::VBPopBio::ResultSet::Cvterm');

=head1 NAME

Bio::Chado::VBPopBio::Result::Cvterm

=head1 SYNOPSIS

Cv::Cvterm object with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self) = @_;
  return {
	  name => $self->name,
	  accession => $self->dbxref->db->name().':'.$self->dbxref->accession(),
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

1; # End of Bio::Chado::VBPopBio::Result::Cvterm
