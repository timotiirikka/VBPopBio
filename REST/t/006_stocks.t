use Test::More tests => 27;
use strict;
use warnings;
use lib '../api/Bio-Chado-VBPopBio/lib';

# the order is important
use VBPopBioREST;
use Dancer::Test;

use JSON;

my $verbose = 0; # print JSON responses to terminal

#
# test projects/head
#

my ($url, $response, $json, $data, $stock);

$url = "/stocks/head";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 160, "$url number of stocks check");
$stock = $data->{records}[0];
is(ref($stock), 'HASH', "$url first stock is a hashref/object");
ok(defined $stock->{id}, "$url first stock has an id");
ok(!defined $stock->{field_collections}, "$url first stock shouldn't have FCs");

#
# get a few full stocks
#
$url = "/stocks?o=0;l=3";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 160, "$url total number of stocks check");
is(scalar @{$data->{records}}, 3, "$url correct number of stocks");
is($data->{start}, 1, "$url start == 1");
is($data->{end}, 3, "$url end == 3");

$stock = $data->{records}[0];
is(ref($stock), 'HASH', "$url first stock is a hashref/object");
ok(defined $stock->{id}, "$url first stock has an id");
ok(defined $stock->{field_collections}, "$url first stock should have FCs");


#
# get the next page of full stocks
#

$url = "/stocks?o=3;l=3";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 160, "$url total number of stocks check");
is(scalar @{$data->{records}}, 3, "$url correct number of stocks");
is($data->{start}, 4, "$url start == 4");
is($data->{end}, 6, "$url end == 6");

#
# get last page of stocks - pagesize 50
#

$url = "/stocks/head?o=150;l=50";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 160, "$url total number of stocks check");
is(scalar @{$data->{records}}, 10, "$url correct number of stocks");
is($data->{start}, 151, "$url start == 151");
is($data->{end}, 160, "$url end == 160");

