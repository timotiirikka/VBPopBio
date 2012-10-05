package Bio::Chado::VBPopBio::ResultSet::Cvterm;

use strict;
use base 'Bio::Chado::Schema::Result::Cv::Cvterm::ResultSet';
use Carp;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Project

=head1 SYNOPSIS

Project resultset with extra convenience functions


=head1 SUBROUTINES/METHODS


=head2 create_with

Ensures cv option is our own subclass of Cv::Cv.

=cut

sub create_with {
  my ($self, $opts) = @_;
  my $schema = $self->result_source->schema;

  $opts->{cv} = 'null' unless defined $opts->{cv};

  # use, find, or create the given cv
  $opts->{cv} = ref $opts->{cv} ? $opts->{cv}
    : $schema->resultset('Cv') # our version of Cv
      ->find_or_create({ name => $opts->{cv} });

  return $self->SUPER::create_with($opts);
}

=head2 find_by_accession

Look up cvterm by dbxref provided by hashref argument
Returns a single cvterm or undef on failure.

Usage: $cvterm = $cvterms->find_by_accession({ term_source_ref => 'TGMA',
                                               term_accession_number => '0000000' });

=cut


sub find_by_accession {
  my ($self, $arg) = @_;
  if (defined $arg && defined $arg->{term_source_ref} && defined $arg->{term_accession_number}) {
    my $dbxref = $self->result_source->schema->dbxrefs->find
      ({ accession => $arg->{term_accession_number},
	 version => '',
	 'db.name' => $arg->{term_source_ref}
       },
       { join => 'db' }
      );
    if (defined $dbxref) {
      return $dbxref->cvterm;
    }
  }
  return undef; # on failure
}

=head2 find_by_name

Look up cvterm by name, and dbxref->db->name (we can't trust cv.name because it can sometimes be verbose)

Returns a single cvterm or undef on failure.

Usage: $cvterm = $cvterms->find_by_accession({ term_source_ref => 'OBI',
                                               term_name => 'SNP microarray' });

=cut

sub find_by_name {
  my ($self, $arg) = @_;
  if (defined $arg && defined $arg->{term_source_ref} && defined $arg->{term_name}) {
    my $search = $self->result_source->schema->cvterms->search
      ({
	'me.name' => $arg->{term_name},
	'db.name' => $arg->{term_source_ref}
       },
       { join => { dbxref => 'db' }});

    if ($search->count() == 1) {
      return $search->first;
    }
  }
  return undef;
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
