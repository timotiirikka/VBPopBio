use Test::More tests => 1;

use strict;
use JSON;
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $projects = $schema->projects;

my $json = JSON->new->pretty;

$schema->txn_do(
		sub {
		  my $project = $projects->create_from_isatab({ directory=>'../../test-data/VectorBase_PopBio_ISA-Tab_full_example' });

		  # make some human readable text from the project and related objects:
		  my $project_json = $json->encode($project->as_data_structure);
		  diag("Project '", $project->name, "' was created temporarily as:\n$project_json");

		  # if (open(TEMP, ">temp-project.json")) { print TEMP $project_json."\n";  close(TEMP); }

		  # run some tests
		  is($project->name, 'Example ISA-Tab for VectorBase PopBio', "project name");

#		  is($project->stocks->count, 60, "60 stocks");
#		  is($project->field_collections->count, 4, "4 field collections");
#		  is($project->genotype_assays->count, 60, "60 genotype assays");
#		  is($project->phenotype_assays->count, 0, "0 phenotype assays");
#		  is($project->stocks->first->nd_experiments->count, 3, "3 assays for one stock");
#
		  # we were just pretending!
		  $schema->txn_rollback();

		}
	       );

