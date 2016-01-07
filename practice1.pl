use strict;

use Furl;
use JSON;
use URI;
use Data::Dumper;

my $target_url = "http://localhost:8545";
my $COUNT = 0;

my $res;
my $args = {
    jsonrpc => "2.0",
    method  => "web3_clientVersion",
    params  => [],
};

print "----get client vistion\n";

$res = &_get($args);
print Dumper($res) . "\n";


print "----get coinbase\n";

$args->{method} = "eth_coinbase";
$res = &_get($args);
print Dumper($res) . "\n";
my $address = $res->{result};

print "----get ETH\n";

$args->{method} = "eth_getBalance";
$args->{params} = [ $address, "latest"];
$res = &_get($args);
print Dumper($res) . "\n";

print "---- wallet\n";

my $eth = $res->{result};
$eth =~ s/\0x//;
print "your ETH:" . hex($eth)."\n";


sub _get {
    my $args = shift @_;
    
    $COUNT++;

    $args->{id} = $COUNT;

    my $furl = Furl->new();
    my $res = $furl->post($target_url,[], encode_json $args);

    return decode_json($res->content);
}
