use Test::More tests => 6;
use strict;
use warnings;
use lib '../api/Bio-Chado-VBPopBio/lib';

# the order is important
use VBPopBioREST;
use Dancer::Test;

use JSON;

my $assay_id = 'VBA0000001';
my $verbose = 1; # print JSON responses to terminal
my ($url, $response, $json, $data);

#
# test assay/ID
#

$url = "/assay/$assay_id";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{id}, $assay_id, "$url ID check");
is($data->{external_id}, "Kela.c1", "$url external_id check");
ok(defined $data->{geolocation}, "$url should have a geolocation");
is($data->{geolocation}{name}, "Kela", "$url geolocation name check");


