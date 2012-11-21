#!/usr/bin/perl -w

#
# usage: bin/this_script.pl
#
# (no args)
#
#
#

use strict;
use Carp;

use lib '../api/Bio-Chado-VBPopBio/lib'; # use the latest local uninstalled API
use Bio::Chado::VBPopBio;

#use JSON;
#my $json = JSON->new->pretty;

my $dsn = "dbi:Pg:dbname=$ENV{CHADO_DB_NAME}";
my $schema = Bio::Chado::VBPopBio->connect($dsn, $ENV{USER}, undef, { AutoCommit => 1 });
my $projects = $schema->projects;

#
# NEAFSEY
#

$schema->txn_do(
                sub {
                    my $neafsey = $projects->create_from_isatab({ directory=>'../test-data/Test-ISA-Tab-for-Chado-loading' });
    });


#
# and also some UC Davis data
#

$schema->txn_do(
                sub {
                  my $project = $projects->create_from_isatab({ directory=>'../test-data/ucdavis_sevare_subset' });
});



