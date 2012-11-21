use Test::More tests => 3;
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

my ($url, $response, $json, $data);

$url = "/projects/head";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 2, "$url number of projects check");
