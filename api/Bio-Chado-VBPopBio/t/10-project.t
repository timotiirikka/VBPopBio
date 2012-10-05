use Test::More tests => 10;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $projects = $schema->projects();

isa_ok($projects, 'Bio::Chado::VBPopBio::ResultSet::Project', "resultset correct class");


# check that we can create and delete a project
my $result =
  $schema->txn_do(sub {
		    my $proj_extID_type = $schema->types->project_external_ID;

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

		    my $project2 = $projects->create
		      ({
			name => 'test project unique name 12345',
			description => 'should not exist',
			projectprops => [ { type => $proj_extID_type,
					    value => '1970-Smith-test2',
					    rank => 0
					  } ]
		       });

		    like($project2->stable_id, qr/^VBP\d+$/, "second stable ID looks ok");
		    isnt($project->stable_id, $project2->stable_id, "two project stable IDs are different");

		    my $project3 = $projects->create
		      ({
			name => 'test project unique name 0000',
			description => 'should not exist',
			projectprops => [ { type => $proj_extID_type,
					    value => '1970-Smith-test3',
					    rank => 0
					  } ]
		       });

		    like($project3->stable_id, qr/^VBP\d+$/, "third stable ID looks ok");
		    isnt($project3->stable_id, $project2->stable_id, "second and third are different");

		    is($project3->stable_id, $project3->stable_id, "two calls return same stable id");

		    my $stable_id3 = $project3->stable_id;
		    $project3->delete;

		    my $project3b = $projects->create
		      ({
			name => 'test project unique name 0000',
			description => 'should not exist',
			projectprops => [ { type => $proj_extID_type,
					    value => '1970-Smith-test3',
					    rank => 0
					  } ]
		       });

		    is($stable_id3, $project3b->stable_id, "deleted and recreated project has same stable id");


		    $schema->txn_rollback();
		  });


