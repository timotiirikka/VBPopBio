package Bio::Chado::VBPopBio::Result::Project::MetaProject;

use base 'Bio::Chado::VBPopBio::Result::Project';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({ }); # must call this routine even if not setting up relationships.

# the next line is copied from Experiment::FieldCollection as a reminder
# __PACKAGE__->resultset_attributes({ join => 'type', where => { 'type.name' => 'field collection' } });
# there's no simple way to set up a default resultset that returns
# just MetaProjects (because there's no type column in the db)
# it should be possible to query for projects that have a certain type of relationship with another

=head1 NAME

Bio::Chado::VBPopBio::Result::Project::MetaProject

=head1 SYNOPSIS

This class may make creating an IR experiment easier to handle.

=head1 RELATIONSHIPS

This class

B<has a> Experiment::FieldCollection result

B<has many> Experiment::PhenotypeAssay results

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

1;
