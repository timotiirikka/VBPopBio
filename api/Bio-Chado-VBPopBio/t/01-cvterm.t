use Test::More tests => 5;

#
# read-only tests - ASSUMING CVTERMS ARE IN DATABASE
#

# the next 4 lines were already tested in 01-api.t
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $cvterms = $schema->cvterms();


my $whole_organism = $cvterms->find_by_accession({
						  term_source_ref=>'EFO',
						  term_accession_number=>'0002906',
						 });

ok(defined $whole_organism, "cvterm defined");
is($whole_organism->name, 'whole organism', "cvterm name is 'whole organism'");

my $not_there = $cvterms->find_by_accession({
					     term_source_ref=>'DODO',
					     term_accession_number=>'123',
					    });

ok(!defined $not_there, "not found ok");


my $snp_microarray = $cvterms->find_by_name({ term_source_ref => 'OBI',
					      term_name => 'SNP microarray' });

ok(defined $snp_microarray, "name lookup ok");

my $snp_microarray2 = $cvterms->find_by_name({ term_source_ref => 'OBIXXX',
					      term_name => 'SNP microarray' });

ok(!defined $snp_microarray2, "name lookup should fail due to wrong ontology");

