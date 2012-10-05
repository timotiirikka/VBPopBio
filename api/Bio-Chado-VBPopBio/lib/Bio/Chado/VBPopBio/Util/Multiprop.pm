package Bio::Chado::VBPopBio::Util::Multiprop;

use Moose;

=head1 NAME

Bio::Chado::VBPopBio::Util::Multiprop

=head1 SYNOPSIS

  use aliased 'Bio::Chado::VBPopBio::Util::Multiprop';
  $multiprop = new Multiprop(cvterms => [ $cvterm1 => $cvterm2 => $cvterm3 ], value => 150);

=head1 ATTRIBUTES

=head2 cvterms

arrayref of Bio::Chado::VBPopBio::Result::Cvterm

=cut

has 'cvterms' => (
		  is => 'ro',
		  isa => 'ArrayRef[Bio::Chado::VBPopBio::Result::Cvterm]',
		  auto_deref => 1,
		  required => 1,
		 );

=head2 value

optional string value

=cut

has 'value' => (
		is => 'ro',
		isa => 'Maybe[Str]',
		required => 0,
	       );

=head2 rank

This will be undefined if the multiprop hasn't yet been inserted into the database.

Not currently used for anything meaningful, but will be useful when/if we allow
overwriting/replacement of existing multiprops.

=cut

has 'rank' => (
		is => 'rw',
		isa => 'Int',
		required => 0,
	       );



=head2 as_data_structure

returns a data structure suitable for JSONification

=cut

sub as_data_structure {
  my $self = shift;
  return { cvterms => [ map { $_->as_data_structure } $self->cvterms ],
	   defined $self->value ? (value => $self->value) : (),
	   # rank => $self->rank,  # don't waste bandwidth until needed
	 };
}

=head2 as_text

=cut

sub as_text {
  my $self = shift;
  return join ", ", (map { $_->name } $self->cvterms), defined $self->value ? ($self->value) : ();
}

1;
