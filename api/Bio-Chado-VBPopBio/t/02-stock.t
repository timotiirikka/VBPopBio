use Test::More tests => 4;

# the next 4 lines were already tested in 01-api.t
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $stocks = $schema->stocks();
my $organisms = $schema->organisms();
my $cvterms = $schema->cvterms();

ok($organisms->count() > 1, "Some organisms are loaded");

my $organism = $organisms->first;

isa_ok($organism, 'Bio::Chado::VBPopBio::Result::Organism');

# try creating and deleting a stock (in a transaction)
my $new_stock_data =
    $schema->txn_do(sub {

	my $stock_type = $cvterms->create_with({ name => 'temporary type',
						 cv => 'VBcv',
					       });

	my $new_stock = $stocks->create({ organism => $organism,
					  name => 'Test stock 123',
					  uniquename => 'Test0123',
					  description => 'Should never get committed',
					  type => $stock_type
					});
	my %data = $new_stock->get_columns();
	$new_stock->delete();
	return \%data;
      });

ok($new_stock_data->{name} eq 'Test stock 123', "inserted stock correct name");

my $not_there_stock = $stocks->find({ description => 'Should never get committed' });
ok(!defined $not_there_stock, "stock deletion check");
