package Bio::Chado::VBPopBio::Result::Cv;

use base 'Bio::Chado::Schema::Result::Cv::Cv';
__PACKAGE__->load_components('+Bio::Chado::VBPopBio::Util::Subclass');
__PACKAGE__->subclass({
		       cvterms => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Cv

=head1 SYNOPSIS

Cv::Cvterm object with extra convenience functions

We have to wrap this so that $cvterms->create_with() works properly.

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

1; # End of Bio::Chado::VBPopBio::Result::Cvterm
