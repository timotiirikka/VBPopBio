package Bio::Chado::VBPopBio::Result::Publication;

use base 'Bio::Chado::Schema::Result::Pub::Pub';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       project_pubs => 'Bio::Chado::VBPopBio::Result::Linker::ProjectPublication',
		       type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Publication

=head1 SYNOPSIS

Publication object with extra convenience functions

We will store DOI in Chado's "uniquename" and Pubmed ID in "miniref".

Author names will be stored as provided in pubauthor.surname.
We won't currently attempt to parse surnames, initials, etc.

=head1 MANY-TO-MANY RELATIONSHIPS

=head2 projects

Type: many_to_many

Returns a list of projects

Related object: Bio::Chado::Schema::Result::Project::Project

=cut

__PACKAGE__->many_to_many
    (
     'projects',
     'project_pubs' => 'project',
    );

=head1 SUBROUTINES/METHODS

=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self, $depth) = @_;
  $depth = INT_MAX unless (defined $depth);
  return {
	  title => $self->title,
	  pubmed_id => $self->miniref,
	  doi => $self->uniquename,
	  authors => [ map { $_->surname } sort { $a->rank <=> $b->rank } $self->pubauthors ],
	  status => $self->type->as_data_structure,
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

1; # End of Bio::Chado::VBPopBio::Result::Phenotype
