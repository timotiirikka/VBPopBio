package Bio::Chado::VBPopBio::Result::Geolocation;

use feature 'switch';
use base 'Bio::Chado::Schema::Result::NaturalDiversity::NdGeolocation';
__PACKAGE__->load_components(qw/+Bio::Chado::VBPopBio::Util::Subclass/);
__PACKAGE__->subclass({
		       nd_experiments => 'Bio::Chado::VBPopBio::Result::Experiment',
		       nd_geolocationprops => 'Bio::Chado::VBPopBio::Result::Geolocationprop',
		      });

=head1 NAME

Bio::Chado::VBPopBio::Result::Experiment

=head1 SYNOPSIS

Geolocation object with extra convenience functions.

=head1 SUBROUTINES/METHODS

=head2 as_data_structure

returns a json-like hashref of arrayrefs and hashrefs

=cut

sub as_data_structure {
  my ($self) = @_;
  return {
	  $self->get_columns,
	  nd_geolocationprops => [
				  map {
				    { $_->get_columns,
					'type.name' => $_->type->name, }
				  } $self->nd_geolocationprops
				 ],
	 };
}

=head2 as_data_for_jsonref

returns json-like data with dojox.json.ref references

=cut

sub as_data_for_jsonref {
  my ($self, $seen) = @_;
  my $id = 'geo'.$self->nd_geolocation_id;
  if ($seen->{$id}++) {
    return { '$ref' => $id };
  } else {
    return {
	    id => $id,
	    description => $self->description,
	    latitude => $self->latitude,
	    longitude => $self->longitude,
	    geodetic_datum => $self->geodetic_datum,
	    altitude => $self->altitude,
	    props => [ map { $_->as_data_for_jsonref($seen) } $self->nd_geolocationprops ],

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

1;
