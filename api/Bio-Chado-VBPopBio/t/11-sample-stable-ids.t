use Test::More tests => 9;

#
# tests sample stable IDs
#
#
# KNOWN BUG: does not properly test database persistence
# tests pass without the $self->update() calls in Stock->stable_id()
#

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $projects = $schema->projects;
my $organisms = $schema->organisms;
my $stocks = $schema->stocks;

my $result =
  $schema->txn_do(sub {
		    my $proj_extID_type = $schema->types->project_external_ID;
		    my $samp_extID_type = $schema->types->sample_external_ID;
		    my $organism = $organisms->first;
		    my $stock_type = $schema->types->placeholder;

		    my $project = $projects->create
		      ({
			name => 'test project unique name 123',
			description => 'should not exist',
			projectprops => [ { type => $proj_extID_type,
					    value => '1970-Smith-test',
					    rank => 0
					  } ]
		       });

		    ok(defined $project, "project object defined");
		    is($project->external_id, '1970-Smith-test', "external id");
		    like($project->stable_id, qr/^VBP\d+$/, "stable ID looks ok");

		    #
		    # note that we're not going to link the stocks to the project (via nd_experiment)
		    # which we would normally do when loading an experiment
		    #

		    my $stock1 = $stocks->create({ organism => $organism,
						   name => 'Test stock 1',
						   uniquename => 'Test0001',
						   description => 'Should never get committed',
						   type => $stock_type
						 });
		    ok(! defined eval { $stock1->stable_id }, "stable_id missing project arg");

		    my $stable_id1 = $stock1->stable_id($project);
		    ok(defined $stable_id1, "stable ID returned");
		    like($stable_id1, qr/^VBS\d+$/, "stable ID looks good");

		    my $stock2 = $stocks->create({ organism => $organism,
						   name => 'Test stock 2',
						   uniquename => 'Test0002',
						   description => 'Should never get committed',
						   type => $stock_type
						 });
		    my $stable_id2 = $stock2->stable_id($project);
		    isnt($stable_id1, $stable_id2, "stable IDs for stock1 and stock2 are different");
		    like($stable_id2, qr/^VBS\d+$/, "stable ID for stock2 looks good");


		    # now delete the first stock and make it again - it should pick up the same stable ID

		    $stock1->delete;
		    my $stock1a = $stocks->create({ organism => $organism,
						   name => 'Test stock 1',
						   uniquename => 'Test0001',
						   description => 'Should never get committed',
						   type => $stock_type
						 });
		    my $stable_id1a = $stock1a->stable_id($project);
		    is($stable_id1, $stable_id1a, "recreated stock stable id is the same");

		    $schema->txn_rollback();
		  });


