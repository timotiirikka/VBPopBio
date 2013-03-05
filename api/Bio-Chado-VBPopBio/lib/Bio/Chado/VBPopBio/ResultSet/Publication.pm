package Bio::Chado::VBPopBio::ResultSet::Publication;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Carp;
use aliased 'Bio::Chado::VBPopBio::Util::Multiprop';


=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Publication

=head1 SYNOPSIS


=head1 SUBROUTINES/METHODS

=head2 find_or_create_from_isatab

  Usage: $publications->find_or_create_from_isatab($publication_data)

Arguments:
  publication_data: hashref from $isatab_study->{study_publications}[$index]


The publication will be looked up in the database (for re-use) by the ISA-Tab field
$publication_data->{study_publication_doi}.  If it already exists, it will be re-used
no-questions-asked (i.e. no verification that the title, authors etc are the same).

=cut

sub find_or_create_from_isatab {
  my ($self, $publication_data) = @_;
  my $schema = $self->result_source->schema;
  my $doi = $publication_data->{study_publication_doi};

  # http://stackoverflow.com/questions/27910/finding-a-doi-in-a-document-or-page
  unless (defined $doi && $doi =~ qr{\b(10[.][0-9]{4,}(?:[.][0-9]+)*/(?:(?!["&\'<>])\S)+)\b}) {
    $schema->defer_exception("Publication DOI ".
			     (defined $doi ?
			      "'$doi' is badly formed" :
			      "is missing but mandatory"));
    return;
  }

  # check for required args
  my @bad_args;
  $publication_data->{$_} or push @bad_args, $_
    for qw/study_publication_author_list
	   study_publication_title
	   study_publication_status
	   study_publication_status_term_accession_number
	   study_publication_status_term_source_ref/;
  if (@bad_args) {
    $schema->defer_exception("Publication $doi is missing details for @bad_args");
    return;
  }

  # status = pub.type
  my $status = $schema->cvterms->find_by_accession
    ({
      term_source_ref => $publication_data->{study_publication_status_term_source_ref},
      term_accession_number => $publication_data->{study_publication_status_term_accession_number},
     });
  unless ($status) {
    $schema->defer_exception("couldn't find status ontology term for publication $doi");
    return;
  }

  my $publication = $schema->publications->find_or_create
    ({
      uniquename => $publication_data->{study_publication_doi},
      type => $status,
     });

  # if we got it back from the database, it will have a title already
  # if not, we need to add those fields
  unless ($publication->title) {
    # basic info
    $publication->update
      ({
	title => $publication_data->{study_publication_title},
	miniref => $publication_data->{study_pubmed_id},
       });
    # authors
    my $rank = 1;
    foreach my $author_string (split /[,;]\s*/, $publication_data->{study_publication_author_list}) {
      $publication->add_to_pubauthors({ surname => $author_string, rank => $rank++ });
    }
  }

  return $publication;
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
