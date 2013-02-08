package Bio::Chado::VBPopBio::Result::Contact;

use base 'Bio::Chado::Schema::Result::Contact::Contact';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       project_contacts => 'Bio::Chado::VBPopBio::Result::Linker::ProjectContact',
		       type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Contact

=head1 SYNOPSIS

Contact object with extra convenience functions

=head1 SUBROUTINES/METHODS

=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self, $depth) = @_;
  $depth = INT_MAX unless (defined $depth);
  return $self->description,
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
