package Bio::Chado::VBPopBio::Result::Geolocationprop;

use feature 'switch';
use base 'Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocationprop';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({ nd_geolocation => 'Bio::Chado::VBPopBio::Result::Geolocation',
			type => 'Bio::Chado::VBPopBio::Result::Cvterm',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Geolocationprop

IS THIS REQUIRED ANY MORE?

Reconsider after adding multiprop functionality to Geolocation.

=head1 SUBROUTINES/METHODS

=head2 as_data_for_jsonref

returns a json-like hashref of arrayrefs and hashrefs

this method is specifically for dojox.json.ref style json

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 'geop'.$self->nd_geolocationprop_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
    return {
	    id => $id,
	    type => $self->type->cv->name.':'.$self->type->name,
	    value => $self->value,
	    rank => $self->rank,
	 };
  }
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

1; # End of Bio::Chado::VBPopBio::Result::Geolocationprop
