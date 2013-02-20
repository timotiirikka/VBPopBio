package Bio::Chado::VBPopBio::Result::Cvtermpath;

use base 'Bio::Chado::Schema::Result::Cv::Cvtermpath';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       subject => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       object => 'Bio::Chado::VBPopBio::Result::Cvterm',
		       cv => 'Bio::Chado::VBPopBio::Result::Cv',
		      });
__PACKAGE__->resultset_attributes({ order_by => 'pathdistance' });

=head1 NAME

Bio::Chado::VBPopBio::Result::Cvtermpath

=head1 SYNOPSIS

Cv::Cvtermpath object with extra convenience functions

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

1; # End of Bio::Chado::VBPopBio::Result::Cvtermpath
