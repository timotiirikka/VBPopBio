use Test::More tests => 6;

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
		  my $project = $projects->create_from_isatab({ directory=>'../../test-data/Test-ISA-Tab-for-Chado-loading/' });

		  # make some human readable text from the project and related objects:
		  # my $project_json = $json->encode($project->as_data_structure);
		  # diag("Project '", $project->name, "' was created temporarily as:\n$project_json");

		  # if (open(TEMP, ">temp-project.json")) { print TEMP $project_json."\n";  close(TEMP); }

		  # run some tests
		  is($project->stocks->count, 60, "60 stocks");
		  is($project->name, 'Neafsey et al., 2010 Anopheles gambiae M, S and Bamako populations', "project name");
		  is($project->field_collections->count, 4, "4 field collections");
		  is($project->genotype_assays->count, 60, "60 genotype assays");
		  is($project->phenotype_assays->count, 0, "0 phenotype assays");
		  is($project->stocks->first->nd_experiments->count, 3, "3 assays for one stock");

		  # we were just pretending!
		  $schema->defer_exception("This is the only exception we should see.");

		}
	       );

