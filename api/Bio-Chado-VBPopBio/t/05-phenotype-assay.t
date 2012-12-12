use Test::More tests => 6;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $fcs = $schema->field_collections();
my $pas = $schema->phenotype_assays();
isa_ok($pas, 'Bio::Chado::VBPopBio::ResultSet::Experiment::PhenotypeAssay', "resultset class test");



# test more field collection specific functions below...

$schema->txn_do(
		sub {
		  my $fc = $fcs->create( { nd_geolocation => { description => 'Nepal' },
				       });

		  my $pa = $pas->create( { nd_geolocation => { description => 'lab' },
				       });
		  my $linker = $pa->nd_experiment_stocks;
		  isa_ok($linker, 'Bio::Chado::VBPopBio::ResultSet::Linker::ExperimentStock');

#		  warn $pa->type;
		  isa_ok($pa->type, 'Bio::Chado::VBPopBio::Result::Cvterm');

		  is($schema->experiments->count, 2, 'Two experiments direct from schema');
		  is($pas->count, 1, 'One phenotype assay from schema');
		  isa_ok($pas->first, 'Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay', 'pa is correct class');

		  $schema->txn_rollback();
		}
	       );

