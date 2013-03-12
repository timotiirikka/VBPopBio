use Test::More tests => 9;
use strict;
use warnings;
use lib '../api/Bio-Chado-VBPopBio/lib';

# the order is important
use VBPopBioREST;
use Dancer::Test;

use JSON;

my $assay_id = 'VBA0000038';
my $verbose = 1; # print JSON responses to terminal
my ($url, $response, $json, $data, $genotype);

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
is($data->{name}, "SM-NRUE.ga1", "$url name check");
ok(!defined $data->{geolocation}, "$url should NOT have a geolocation");
ok(defined $data->{genotypes}, "$url should have genotypes");
is(scalar(@{$data->{genotypes}}), 2, "$url should have 2 genotypes");
$genotype = $data->{genotypes}[0];
is(ref($genotype), 'HASH', "$url genotype is a hashref/object");
is($genotype->{name}, '2La/a', "$url genotype's name is correct");


