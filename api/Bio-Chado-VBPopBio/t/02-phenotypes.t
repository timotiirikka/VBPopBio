use Test::More tests => 2;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $phenotypes = $schema->phenotypes();
my $cvterms = $schema->cvterms();

# try creating and deleting a new phenotype (in a transaction)
my $new_object_data =
    $schema->txn_do(sub {

	my $dummy_term1 = $cvterms->create_with({ name => 'temporary term1',
						  cv => 'VBcv',
						});
	my $dummy_term2 = $cvterms->create_with({ name => 'temporary term2',
						  cv => 'VBcv',
						});

	my $new_object = $phenotypes->create({
					      uniquename => 'Test0123only',
					      name => 'Should never get committed',
					      observable => $dummy_term1,
					      attr => $dummy_term2,
					      value => 'pretending!',
					     });
	my %data = $new_object->get_columns();
	$new_object->delete();
	return \%data;
      });

ok($new_object_data->{value} eq 'pretending!', "inserted object with correct name");

my $not_there_anymore = $phenotypes->find({ uniquename => 'Test0123only' });
ok(!defined $not_there_anymore, "object deletion check");
