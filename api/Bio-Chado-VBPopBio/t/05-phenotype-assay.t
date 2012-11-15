use Test::More tests => 2;

use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

my $fcs = $schema->phenotype_assays();
isa_ok($fcs, 'Bio::Chado::VBPopBio::ResultSet::Experiment::PhenotypeAssay', "resultset class test");

# check that all results are actually field collections
# an error here suggests a mismatch between Bio::Chado::VBPopBio::Result::Experiment::classify()
# and the resultset_attributes filter in Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay
my @wrong_class = grep { !$_->isa('Bio::Chado::VBPopBio::Result::Experiment::PhenotypeAssay') } $fcs->all();
ok(@wrong_class == 0, "all results should be field collections");


# test more field collection specific functions below...
