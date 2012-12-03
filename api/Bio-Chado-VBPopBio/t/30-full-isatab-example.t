use Test::More tests => 8;

use strict;
use JSON;
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $projects = $schema->projects;

my $json = JSON->new->pretty;

$schema->txn_do_deferred(
		sub {
		  my $project = $projects->create_from_isatab({ directory=>'../../test-data/VectorBase_PopBio_ISA-Tab_full_example' });

		  # make some human readable text from the project and related objects:
		  my $project_json = $json->encode($project->as_data_structure);
		  diag("Project '", $project->name, "' was created temporarily as:\n$project_json");

		  # if (open(TEMP, ">temp-project.json")) { print TEMP $project_json."\n";  close(TEMP); }

		  # run some tests
		  is($project->name, 'Example ISA-Tab for VectorBase PopBio', "project name");

		  my $stock = $project->stocks->first;
		  isa_ok($stock, "Bio::Chado::VBPopBio::Result::Stock", "first stock is a stock");

		  is($stock->field_collections->count, 1, "stock has 1 FC");
		  my $fc = $stock->field_collections->first;
		  isa_ok($fc, "Bio::Chado::VBPopBio::Result::Experiment::FieldCollection", "fc is correct class");
		  my $geo = $fc->geolocation;
		  isa_ok($geo, "Bio::Chado::VBPopBio::Result::Geolocation", "geo is correct class");


		  is($stock->genotype_assays->count, 2, "stock has two genotype_assays");

		  # karyotype assay is loaded first (comes first in investigation sheet)
		  my ($ka, $ga) = $stock->genotype_assays->all;

		  isa_ok($ka, "Bio::Chado::VBPopBio::Result::Experiment::GenotypeAssay", "genotype_assay is correct class");

		  # my $kap = $ka->protocols;



#		  is($project->stocks->count, 60, "60 stocks");
#		  is($project->field_collections->count, 4, "4 field collections");
#		  is($project->genotype_assays->count, 60, "60 genotype assays");
#		  is($project->phenotype_assays->count, 0, "0 phenotype assays");
#		  is($project->stocks->first->nd_experiments->count, 3, "3 assays for one stock");
#

		  is(scalar(@{$schema->{deferred_exceptions}}), 0, "no deferred exceptions");
		  # we were just pretending!
		  $schema->defer_exception("This is the only exception we should see.");
		}
	       );
