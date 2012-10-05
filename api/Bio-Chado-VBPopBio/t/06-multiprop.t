use Test::More tests => 13;

# the next 4 lines were already tested in 01-api.t
use Bio::Chado::VBPopBio;
use aliased 'Bio::Chado::VBPopBio::Util::Multiprop';

my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $cvterms = $schema->cvterms();
my $stocks = $schema->stocks();
my $organisms = $schema->organisms();
my $dbxrefs = $schema->dbxrefs();

#
# tests unrelated to Chado
#

my $multiprop = Multiprop->new(cvterms=> [ $cvterms->first ]);

ok(defined $multiprop, "Made a multiprop");

use JSON;
my $json = JSON->new->pretty;

my $out = $json->encode($multiprop->as_data_structure);
# warn $out;
ok($out =~ /name/, "json check");


#
# tests with Chado objects
#

$schema->txn_do(
		sub {

		  my $organism = $organisms->first;
		  my $stock_type = $cvterms->create_with({ name => 'temporary type',
							   cv => 'VBcv',
							 });


		  my $stock = $stocks->create({ organism => $organism,
						name => 'Long green-haired stock',
						uniquename => 'Green100',
						description => 'Should never get committed',
						type => $stock_type
					      });


		  my $hair_color = $dbxrefs->find({ accession => '0003924',
						    'db.name' => 'EFO',
						  },
						  { join => 'db' }
						 )->cvterm;

		  my $green = $dbxrefs->find({ accession => '0000320',
					       'db.name' => 'PATO',
					     },
					     { join => 'db' }
					    )->cvterm;

		  my $length = $dbxrefs->find({ accession => '0000122',
					       'db.name' => 'PATO',
					     },
					     { join => 'db' }
					    )->cvterm;

		  my $cm = $dbxrefs->find({ accession => '0000015',
					       'db.name' => 'UO',
					     },
					  { join => 'db' }
					 )->cvterm;

		  is($stock->stockprops->count, 0, "No pre-existing props");

		  my $multiprop = $stock->add_multiprop(Multiprop->new(cvterms=> [ $hair_color, $green, $length, $cm ], value => 100));

		  is($multiprop->rank, 1, "returned multiprop rank is 1");
		  is($stock->stockprops->count, 4, "Now has three props");

		  my @multiprops = $stock->multiprops;
		  is(scalar @multiprops, 1, "Has one Multiprop");

		  is($multiprops[0]->rank, 1, "First Multiprop rank is 1");
		  is($multiprops[0]->value, 100, "First Multiprop value is 100");

		  # warn $json->encode($multiprops[0]->as_data_structure);


		  # add a valueless multiprop
		  my $wing = $dbxrefs->find( { accession => '0000196',
					       'db.name' => 'TGMA' },
					     { join => 'db' }
					   )->cvterm;

		  my $truncated = $dbxrefs->find( { accession => '0000936',
						    'db.name' => 'PATO' },
						  { join => 'db' }
						)->cvterm;

		  my $multiprop2 = $stock->add_multiprop(Multiprop->new(cvterms=> [ $wing, $truncated ]));

		  my $red = $dbxrefs->find({ accession => '0000322',
					     'db.name' => 'PATO' },
					   { join => 'db' }
					  )->cvterm;

		  # and another valued multiprop
		  my $multiprop3 = $stock->add_multiprop(Multiprop->new(cvterms=> [ $hair_color, $red, $length, $cm ], value=>25));

		  @multiprops = $stock->multiprops;
		  is(scalar @multiprops, 3, "Has three Multiprops");

		  is($multiprops[0]->value, 100, "First Multiprop value is still 100");
		  is($multiprops[1]->value, undef, "Second Multiprop value is correctly undef");
		  is($multiprops[2]->value, 25, "Third Multiprop value is 25");

		  is($multiprops[2]->rank, 7, "Third Multiprop, rank is 7");

		  # warn $json->encode($stock->as_data_structure);

		  $schema->txn_rollback();
		}
	       );


