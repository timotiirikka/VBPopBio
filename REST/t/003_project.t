use Test::More tests => 39;
use strict;
use warnings;
use lib '../api/Bio-Chado-VBPopBio/lib';

# the order is important
use VBPopBioREST;
use Dancer::Test;

use JSON;

my $project_id = 'VBP0000001';
my $verbose = 1; # print JSON responses to terminal

#
# test project/ID/head
#

my ($url, $response, $json, $data, $stock_data);

$url = "/project/$project_id/head";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{id}, $project_id, "$url ID check");
is($data->{name}, "Neafsey et al., 2010 Anopheles gambiae M, S and Bamako populations", "$url name check");
is($data->{external_id}, "2010-Neafsey-M-S-Bamako", "$url external_id check");
like($data->{description}, qr/placeholder/, "$url description =~ /placeholder/");

#
# test project/ID/stocks
#
# the stocks should be returned "full depth"
#


$url = "/project/$project_id/stocks?o=0;l=5";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 60, "$url number of stocks check");
is($data->{start}, 1, "$url starts at 1");
is($data->{end}, 5, "$url ends at 5");
$stock_data = $data->{records}->[0];
ok($stock_data, "$url first stock ok");
like($stock_data->{id}, qr/^VBS\d+$/, "$url first stock should have an id");
ok($stock_data->{field_collections}, "$url first stock should have field_collections");
ok($stock_data->{genotype_assays}, "$url first stock should have genotype_assays");
ok($stock_data->{species_identification_assays}, "$url first stock should have species_identification_assays");


$url = "/project/$project_id/stocks/head?o=0;l=5";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 60, "$url number of stocks check");
is($data->{start}, 1, "$url starts at 1");
is($data->{end}, 5, "$url ends at 5");
$stock_data = $data->{records}->[0];
ok($stock_data, "$url first stock ok");
like($stock_data->{id}, qr/^VBS\d+$/, "$url first stock should have an id");
ok(!defined $stock_data->{field_collections}, "$url first stock should have no field_collections");
ok(!defined $stock_data->{genotype_assays}, "$url first stock should have no genotype_assays");
ok(!defined $stock_data->{species_identification_assays}, "$url first stock should have no species_identification_assays");


# test request for second page of stocks for project
$url = "/project/$project_id/stocks/head?o=5;l=5";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 60, "$url number of stocks check");
is($data->{start}, 6, "$url starts at 6");
is($data->{end}, 10, "$url ends at 10");

#
# the WHOLE project JSON (slower)
#
# project contains stocks contain field_collections, phenotype_assays, genotype_assays and species_identification_assays
#

$url = "/project/$project_id";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
# same 4 tests as project/ID/head
is($data->{id}, $project_id, "$url ID check");
is($data->{name}, "Neafsey et al., 2010 Anopheles gambiae M, S and Bamako populations", "$url name check");
is($data->{external_id}, "2010-Neafsey-M-S-Bamako", "$url external_id check");
like($data->{description}, qr/placeholder/, "$url description =~ /placeholder/");
# and some new tests on the deeper data structure
is(scalar @{$data->{stocks}}, 60, "$url number of stocks check");
# check a stock has field_collections
ok($data->{stocks}->[0]->{field_collections}, "$url first stock should have field_collections");
#
# we'll cover stock and assays in more detail in other tests
#
