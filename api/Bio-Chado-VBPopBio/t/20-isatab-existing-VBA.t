use Test::More tests => 7;

use strict;
use JSON;
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });


my $projects = $schema->projects;
# isa_ok($projects, 'Bio::Chado::VBPopBio::ResultSet::Project', "resultset correct class");

my $json = JSON->new->pretty;

$schema->txn_do_deferred(
		sub {
		  my $project1 = $projects->create_from_isatab({ directory=>'../../test-data/Test-ISA-Tab-for-Chado-loading/' });
		  my $project2 = $projects->create_from_isatab({ directory=>'../../test-data/Test-ISA-Tab-pre-existing-VBA-ids/' });

		  my $stock1 = $project1->stocks->first;
		  my $stock2 = $project2->stocks->first;

		  is($project1->stocks->count, 60, "60 stocks");
 		  is($project2->stocks->count, 2, "2 stocks");

		  # the two stocks should have different stable ids
		  isnt($stock1->stable_id, $stock2->stable_id, "different stable ids");
		  # the two stocks should have the same field collection
		  is($stock1->field_collections->first->stable_id, $stock2->field_collections->first->stable_id, "same field collection");

		  is($project2->field_collections->count, 1, "project2 only one field collection");
		  isnt($project1->field_collections->count, 1, "project1 doesn't have one field collection");

		  is(scalar(@{$schema->{deferred_exceptions}}), 0, "no deferred exceptions");

		  # we were just pretending!
		  $schema->defer_exception("This is the only exception we should see.");
		}
	       );

