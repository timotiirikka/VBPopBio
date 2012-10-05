package Bio::Chado::VBPopBio::ResultSet::Geolocation;

use base 'DBIx::Class::ResultSet';
use Carp;

=head1 NAME

Bio::Chado::VBPopBio::ResultSet::Geolocation

=head1 SYNOPSIS

Re-branded NdGeolocation object


=head1 SUBROUTINES/METHODS

=head2 find_or_create_from_isatab

 Usage: $geolocations->find_or_create_from_isatab($isatab_assay_data, $stock, $project, $ontologies, $study);

 Desc: This method creates a stock object from the isatab sample hashref (from a field collection assay)
 Ret : a new Experiment::FieldCollection row (is a NdExperiment)
 Args: hashref $isa->{studies}[N]{study_assay_lookup}{'field collection'}{samples}{SAMPLE_ID}
       (example contents below)
         {
           characteristics => { 'Collection site' => { value => 'Kela',
                                                       term_accession_number => 123,
                                                       term_source_ref => 'GAZ' } },
         }
       Stock object (Bio::Chado::VBPopBio)
       Project object (Bio::Chado::VBPopBio)
       hashref $isa->{ontology_lookup} from ISA-Tab returned from Bio::Parser::ISATab
       hashref ISA-Tab current study (used for protocols)

=cut

sub find_or_create_from_isatab {
  my ($self, $assay_data, $stock, $project, $ontologies, $study) = @_;
  my $schema = $self->result_source->schema;

  # create the nd_experiment and stock linker type
  my $cvterms = $schema->cvterms;

  my $geolocation =
    $self->find_or_create({
			   description => $assay_data->{characteristics}{'Collection site'}{value} || undef,
			   latitude => $assay_data->{characteristics}{'Collection site latitude'}{value} || undef,
			   longitude => $assay_data->{characteristics}{'Collection site longitude'}{value} || undef,
			   altitude => $assay_data->{characteristics}{'Collection site altitude'}{value} || undef,
			   geodetic_datum => 'WGS 84',
			  });

  # next, add the GAZ term as a property if it has been provided
  # notes: the logic here needs refining - especially if GAZ has lat/long, need to fill that in
  # do we want to do the look-up first in props based on GAZ term?
  # or do we allow multiple locations (with different lat/long) with same GAZ term (Bob thinks yes)
  # expect some bloat in this table until we come up with a suitable policy.

  my $site = $assay_data->{characteristics}{'Collection site'}; # shorthand hashref
  if ($site->{term_source_ref} && $site->{term_source_ref} eq 'GAZ' # really we should check in $ontologies->{GAZ}{term_source_description} eq 'Gazetteer'
      && defined $site->{term_accession_number}) {

    # look up GAZ cvterm via its accession number
    my $gaz_db = $schema->dbs->find( { name => 'GAZ' }, { key => 'db_c1' } );
    if ($gaz_db) {
      my $gaz_dbxref = $schema->dbxrefs->find( { accession => sprintf("%08d", $site->{term_accession_number}),
				 	         db => $gaz_db,
						 version => '',
					       }, { key => 'dbxref_c1' });

      if ($gaz_dbxref && (my $gaz_term = $cvterms->find( { dbxref => $gaz_dbxref }, { key => 'cvterm_c2' } ))) {
	# add the geolocationprop manually (BCS convenience function doesn't seem suitable here)
	# maybe check for agreement between text provided and gaz_term->name?
	# could be issues with international characters etc
	$geolocation->find_or_create_related('nd_geolocationprops',
					     { type => $gaz_term,
					       # no value required (what about rank?)
					     });
      } else {
	# insert better error handling here
	$schema->defer_exception_once("can't find GAZ:$site->{term_accession_number} for $site->{value}");
      }
    } else {
      croak "can't find db name=GAZ in Chado\n";
    }
  }


  # load simple text (no GAZ because we should already have that for "leaf) gelocation props for
  foreach my $geotype (qw/village country county region district location locality province/) {
    my $value = $assay_data->{characteristics}{"Collection site $geotype"}{value};
    if ($value) {
      $geolocation->create_geolocationprops( { "collection site $geotype" => $value },
					     {
					      autocreate => 1,
					      cv_name => 'VBcv',
					     }
					   );
    }
  }

  return $geolocation;
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
