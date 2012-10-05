use Test::More tests => 1;

use strict;
use JSON;
use Bio::Chado::VBPopBio;
my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });

use lib 'bin';
use IRTypes;

use Carp;

my $projects = $schema->projects;
# isa_ok($projects, 'Bio::Chado::VBPopBio::ResultSet::Project', "resultset correct class");

my $json = JSON->new->pretty;

my $cvterms = $schema->cvterms;
my $dbxrefs = $schema->dbxrefs;

my $vbcv = $schema->cvs->find({ name => 'VectorBase miscellaneous CV' });
my $vbdb = $schema->dbs->find({ name => 'VBcv' });

$schema->txn_do(
		sub {


		  #
		  # 1. Add all the VBcv terms for KDT60 etc (see IRTypes.pm in this directory)
		  #    with accessions like this VBcv:9000084
		  #    (so that these can be loaded correctly from the phenote file)
		  #

		  while (my ($name, $acc) = each %IRTypes::name2acc) {
		    my ($db_name, $db_acc) = split /:/, $acc;
		    croak unless ($db_name eq 'VBcv' && length($db_acc));
		    my $new_cvterm =
		      $dbxrefs->find_or_create( { accession => $db_acc,
						  db => $vbdb },
						{ join => 'db' })->
						  find_or_create_related('cvterm',
									 { name => $name,
									   definition => 'Temporary IR assay result type',
									   cv => $vbcv
									 });
		  }

		  # sanity check
		  # my $kdt60 = $cvterms->find( { name => 'KDT60', cv => $vbcv } );
		  # warn "kdt60 has name ".$kdt60->name." and db ".$kdt60->dbxref->db->name."\n";


		  #
		  # 2. load the ISA-Tab
		  #



		  my $irbase = $projects->create_from_isatab({ directory=>'../../test-data/IRbase-test-study114' });

		  # my $project_json = $json->encode($irbase->as_data_structure);
		  # warn("Project '", $irbase->name, "' was created temporarily as:\n$project_json");
		  # if (open(TEMP, ">temp-project.json")) { print TEMP $project_json."\n";  close(TEMP); }


		  is($irbase->name, 'Results of a rapid susceptibility survey of Anopheles culicifacies in Bombay State. India. during 1959. revealing continued susceptibility to DDT, except in a few scattered pockets', 'project name test');



		  $schema->txn_rollback;
    });




