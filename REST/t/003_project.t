use Test::More tests => 16;
use strict;
use warnings;
use lib '../api/Bio-Chado-VBPopBio/lib';

# the order is important
use VBPopBioREST;
use Dancer::Test;

use JSON;

my $project_id = 'VBP0000001';
my $verbose = 0; # print JSON responses to terminal

#
# test project/ID/head
#

my ($url, $response, $json, $data);

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

$url = "/project/$project_id/stocks";
route_exists([ GET=>$url ], "$url route exists");
$response = dancer_response GET => $url;
$json = $response->{content};
diag("$url response:\n$json") if ($verbose); # print diagnostics to terminal
$data = eval { from_json $json };
ok($data, "$url json decoding");
is($data->{count}, 60, "$url number of stocks check");
# TO DO
# more tests on $data here


#
# the WHOLE project JSON (slower)
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
