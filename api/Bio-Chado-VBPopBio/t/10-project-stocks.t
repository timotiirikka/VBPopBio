use Test::More tests => 19;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $organisms = $schema->organisms();
my $cvterms = $schema->cvterms();

ok($organisms->count() > 1, "Some organisms are loaded");

my $organism = $organisms->first;

my $projects = $schema->projects();
my $stocks = $schema->stocks();

isa_ok($projects, 'Bio::Chado::VBPopBio::ResultSet::Project', "resultset correct class");


# check that we can create and delete a project
my $result =
  $schema->txn_do(sub {
		    my $proj_extID_type = $schema->types->project_external_ID;

		    my $project = $projects->create
		      ({
			name => 'test project unique name 123',
			description => 'should not exist',
		       });
		    $project->external_id('1970-Smith-test');

		    ok(defined $project, "project object defined");
		    is($project->external_id, '1970-Smith-test', "external id");
		    ok($projects->looks_like_stable_id($project->stable_id), "stable ID looks ok");

		    my $stock_type = $cvterms->create_with({ name => 'temporary type',
							     cv => 'VBcv',
							   });

		    my $new_stock = $stocks->create({ organism => $organism,
						      name => 'Test stock 123',
						      uniquename => 'Test0123',
						      description => 'Should never get committed',
						      type => $stock_type
						    });

		    $project->add_to_stocks($new_stock);
		    my $stocks1 = $project->stocks;
		    isa_ok($stocks1, "Bio::Chado::VBPopBio::ResultSet::Stock", "got stock(s)");
		    is($stocks1->count, 1, "project has one stock");

		    my $new_stock2 = $stocks->create({ organism => $organism,
						       name => 'Test stock 1234',
						       uniquename => 'Test01234',
						       description => 'Should never get committed',
						       type => $stock_type
						     });

		    $project->add_to_stocks($new_stock2);
		    my $stocks2 = $project->stocks;
my $refs = $stocks2->as_query;
warn $$refs->[0];
		    isa_ok($stocks2, "Bio::Chado::VBPopBio::ResultSet::Stock", "got stock(s)");
		    is($stocks2->count, 2, "project has two stocks now");

		    my $project2 = $projects->create
		      ({
			name => 'test project unique name 12345',
			description => 'should not exist',
		       });
		    $project2->external_id('1970-Smith-test2');

		    $project2->add_to_stocks($new_stock2);


		    my $projects2 = $new_stock2->projects;
my $ref = $projects2->as_query;
warn $$ref->[0];

		    isa_ok($projects2, "Bio::Chado::VBPopBio::ResultSet::Project", "stock got projects");
		    is($projects2->count, 2, "stock got 2 projects");

		    # adding from the stock, but it's already there
		    $new_stock2->add_to_projects($project2); # should be a no-op
		    is($new_stock2->projects->count, 2, "should be the same");

		    # now add a third project to new_stock2
		    my $project3 = $projects->create
		      ({
			name => 'test project unique name 123456',
			description => 'should not exist',
		       });
		    $project3->external_id('1970-Smith-test3');

		    $new_stock2->add_to_projects($project3);
		    is($new_stock2->projects->count, 3, "should be the three now");

		    is($projects->count, 3, "three projects");
		    is($projects->stocks->count, 2, "two stocks via projects");
		    is($projects->search({'me.name' => 'test project unique name 123456'})->stocks->count, 1, "one stock via project 3");

		    is($stocks->count, 2, "two stocks");
		    is($stocks->projects->count, 3, "three projects via stocks");
		    is($stocks->search({'uniquename'=>'Test0123'})->projects->count, 1, "one project via stock 1 search");

		    $schema->txn_rollback();
		  });


