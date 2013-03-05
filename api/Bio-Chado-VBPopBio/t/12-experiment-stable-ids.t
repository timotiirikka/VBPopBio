use Test::More tests => 11;

#
# tests experiment/assay stable IDs
#
#
# KNOWN BUG: does not properly test database persistence
# tests pass without the $self->update() calls in Stock->stable_id()
#

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $projects = $schema->projects;
my $stocks = $schema->stocks;
my $experiments = $schema->experiments;

my $result =
  $schema->txn_do(sub {
		    my $proj_extID_type = $schema->types->project_external_ID;
		    my $expt_extID_type = $schema->types->experiment_external_ID;

		    my $stock_type = $schema->types->placeholder;

		    my $project = $projects->create
		      ({
			name => 'test project unique name 123',
			description => 'should not exist',
#			projectprops => [ { type => $proj_extID_type,
#					    value => '1970-Smith-test',
#					    rank => 0
#					  } ]
		       });
		    $project->external_id('1970-Smith-test');

		    my $project_stable_id = $project->stable_id;

		    #
		    # note that we're not going to link the stocks to the project (via nd_experiment)
		    # which we would normally do when loading an experiment
		    #

		    my $stock1 = $stocks->create({ name => 'Test stock 1',
						   uniquename => 'Test0001',
						   description => 'Should never get committed',
						   type => $stock_type
						 });
		    my $stock1_stable_id = $stock1->stable_id($project);



		    my $experiment1 = $schema->phenotype_assays->create();
		    $experiment1->external_id('MyLovelyAssay001');

		    my $experiment2 = $schema->phenotype_assays->create();
		    $experiment2->external_id('MyLovelyAssay002');

		    # see if we can assign a stable id via project
		    my $expt1_stable_id = $experiment1->stable_id($project);
		    ok($experiments->looks_like_stable_id($expt1_stable_id), "stable ID looks ok");

		    # test some project/experiment linkage
		    is($project->experiments->count, 0, "project has no expts");
		    $project->add_to_experiments($experiment1);
		    is($project->experiments->count, 1, "project has 1 expt");
		    $experiment2->add_to_projects($project);
		    is($project->experiments->count, 2, "now has two");

		    # second stable id should be different to first
		    isnt($expt1_stable_id, $experiment2->stable_id($project), "expts1+2 different IDs");
		    my $expt2_stable_id = $experiment2->stable_id;

		    # now try to retrieve it without project
		    is($experiment1->stable_id, $expt1_stable_id, "quick fetch ok");

		    # now delete the experiment and recreate it exactly the same way
		    $experiment1->delete();

		    my $experiment1a = $schema->phenotype_assays->create();
		    $experiment1a->external_id('MyLovelyAssay001');

		    # now check that we can't just get the stable id without project
		    is(eval { $experiment1a->stable_id() }, undef, "couldn't get stable_id without project");

		    # now check that the one we get properly is the same as before
		    is($experiment1a->stable_id($project), $expt1_stable_id, "same ID as before");
		    is($experiment1a->stable_id(), $expt1_stable_id, "same ID as before again");

		    # now test find_by_stable_id

		    my $e2 = $experiments->find_by_stable_id($expt2_stable_id);
		    isa_ok($e2, "Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay", "found expt and got correct subclass");
		    # internal db ids are the same
		    is($e2->id, $experiment2->id, "same primary key");


		    $schema->txn_rollback();
		  });


