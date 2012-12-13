use Test::More tests => 6;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $fcs = $schema->field_collections();
isa_ok($fcs, 'Bio::Chado::VBPopBio::ResultSet::Experiment::FieldCollection', "resultset class test");

# test more field collection specific functions below...

$schema->txn_do(
		sub {
		  my $fc = $fcs->create( { nd_geolocation => { description => 'lab' },
				       });
		  my $linker = $fc->nd_experiment_stocks;
		  isa_ok($linker, 'Bio::Chado::VBPopBio::ResultSet::Linker::ExperimentStock');

#		  warn $fc->type;
		  isa_ok($fc->type, 'Bio::Chado::VBPopBio::Result::Cvterm');

		  is($schema->experiments->count, 1, 'One experiment direct from schema');
		  is($fcs->count, 1, 'One field collection direct from schema');
		  isa_ok($fcs->first, 'Bio::Chado::VBPopBio::Result::Experiment::FieldCollection', 'fc is correct class');

		  $schema->txn_rollback();
		}
	       );

