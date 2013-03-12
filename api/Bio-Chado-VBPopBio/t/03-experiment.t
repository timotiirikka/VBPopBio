use Test::More tests => 11;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $cvterms = $schema->cvterms;
my $stocks = $schema->stocks;
my $experiments = $schema->experiments;
my $field_collections = $schema->field_collections;
my $species_id_assays = $schema->species_identification_assays;
my $genotype_assays = $schema->genotype_assays;
my $phenotype_assays = $schema->phenotype_assays;
my $geolocations = $schema->geolocations;


#
# create a stock and all four assays?
#

my $data =
    $schema->txn_do(sub {

#
# at some point create a stock and attach experiments and test
# some of the relationships and special methods
#
#		      my $stock_type = $cvterms->create_with({ name => 'temporary type',
#						 cv => 'VBcv',
#					       });
#
#		      my $stock = $stocks->create({
#					  name => 'Test stock 123',
#					  uniquename => 'Test0123',
#					  description => 'Should never get committed',
#					  type => $stock_type
#					});
#

		      is($field_collections->count, 0, "should be no field collections prior");

		      my $geoloc = $geolocations->create({
							  description => 'somewhere',
							  latitude => 1.23,
							  longitude => 4.56,
							 });

		      my $fc = $field_collections->create({
							   nd_geolocation => $geoloc
							  });
		      $fc->description('very interesting');

		      my $sp = $species_id_assays->create();
		      my $ga = $genotype_assays->create();
		      my $pa = $phenotype_assays->create();


		      is($field_collections->count, 1, "should now be one field collection");

		      my %data = (
				  fc_id => $fc->id,
				  fc_descrip => $fc->description,
				  fc_type => $fc->type->name,
				  geo_id => $geoloc->id,
				  geo_longitude => $geoloc->longitude,
				 );

		      isa_ok($fc, 'Bio::Chado::VBPopBio::Result::Experiment::FieldCollection', 'fc type');
		      isa_ok($sp, 'Bio::Chado::VBPopBio::Result::Experiment::SpeciesIdentificationAssay', 'sp type');
		      isa_ok($ga, 'Bio::Chado::VBPopBio::Result::Experiment::GenotypeAssay', 'ga type');
		      isa_ok($pa, 'Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay', 'pa type');

		      $geoloc->delete();
		      $fc->delete();
		      $sp->delete();
		      $ga->delete();
		      $pa->delete();

		      # $stock->delete();
		      return \%data;
		    });


is($data->{fc_type}, 'field collection', 'fc type');
is($data->{fc_descrip}, 'very interesting', 'experiment->description');
is($data->{geo_longitude}, 4.56, 'geo longitude');

my $no_fc = $field_collections->find($data->{fc_id});
ok(!defined $no_fc, "field collection deletion");

my $no_geo = $geolocations->find($data->{geo_id});
ok(!defined $no_geo, "geolocation deletion");


#
# would be nice to test some of this again
# (difficult without test data - maybe include these tests after loading from ISA-tab in 20-isatab-agsnp.t)
#
#
# check search_on_properties
# ok($schema->experiments->search_on_properties( { name => 'end time of day', value => '05:00' } )->count >= 1, "search for at least one experiment with 'end time of day' equal to '05:00'");

# check search_on_properties_cv_acc
# ok($schema->experiments->search_on_properties_cv_acc('MIRO:30000035')->count >= 1, "search by MIRO:30000035");

