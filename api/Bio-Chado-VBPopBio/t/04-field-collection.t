use Test::More tests => 4;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $fcs = $schema->field_collections();
isa_ok($fcs, 'Bio::Chado::VBPopBio::ResultSet::Experiment::FieldCollection', "resultset class test");

# the following test is a no-op on an empty database (it passes but doesn't really test anything)

# check that all results are actually field collections
# an error here suggests a mismatch between Bio::Chado::VBPopBio::Result::Experiment::classify()
# and the resultset_attributes filter in Bio::Chado::VBPopBio::Result::Experiment::FieldCollection
my @wrong_class = grep { !$_->isa('Bio::Chado::VBPopBio::Result::Experiment::FieldCollection') } $fcs->all();
ok(@wrong_class == 0, "all results should be field collections");


# test more field collection specific functions below...

my $cvterms = $schema->cvterms;

$schema->txn_do(
		sub {
		  my $fc = $fcs->create( { nd_geolocation => { description => 'lab' },
					 type => $cvterms->first,
				       });
		  my $linker = $fc->nd_experiment_stocks;
		  isa_ok($linker, 'Bio::Chado::VBPopBio::ResultSet::Linker::ExperimentStock');

#		  warn $fc->type;
		  isa_ok($fc->type, 'Bio::Chado::VBPopBio::Result::Cvterm');

		  $schema->txn_rollback();
		}
	       );

