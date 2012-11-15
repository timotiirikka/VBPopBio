use Test::More tests => 3;

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
		  my $project2 = $projects->create_from_isatab({ directory=>'../../test-data/Test-ISA-Tab-pre-existing-VBS-ids/' });

		  my $stock1 = $project1->stocks->first;
		  my $stock2 = $project2->stocks->first;

#		  warn "project 1 stock uniquename = ".$stock1->uniquename."\n";
#		  warn "project 2 stock uniquename = ".$stock2->uniquename."\n";

		  is($project1->stocks->count, 60, "60 stocks");
		  is($stock1->external_id, $stock2->external_id, "stocks should have same external id");
		  is(scalar(@{$schema->{deferred_exceptions}}), 0, "no deferred exceptions");

		  # we were just pretending!
		  $schema->defer_exception("This is the only exception we should see.");
		}
	       );

