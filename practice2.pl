use strict;

use Furl;
use JSON;
use URI;
use File::Spec;
use Data::Dumper;

my $target_url = "http://localhost:8545";
my $COUNT = 0;

my $res;
my $args = {
    jsonrpc => "2.0",
    method  => "web3_clientVersion",
    params  => [],
};

my $prev_eth;
my $now_eth;

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
$prev_eth = $eth;
print "your ETH:" . hex($prev_eth) ."\n";

=pod
print "---- make smart contract\n";
my $contract_source = File::Spec->catfile("simpleStorage.sol");
$args->{method} = "eth_compileSolidity";
$args->{params} = [ $contract_source ];
my $res = &_get($args);
print Dumper($res) . "\n";
=cut

print "----set transaction\n";

$args->{method} = "eth_sendTransaction";
$args->{params} = [{
    from => $address,
    gas  => "0x76c0",
    gasPrice => "0x9184e72a000",
    data => "0x6060604052603b8060106000396000f3606060405260e060020a600035046360fe47b1811460245780636d4ce63c14602e575b005b6004356000556022565b6000546060908152602090f3",
}];
$res = &_get($args);
print Dumper($res) . "\n";

print "---- contract hash\n";

my $contract_hash = $res->{result};
print "your contract hash:" . $contract_hash ."\n";

#sleep(60);

print "----get contract address\n";
my $contract_address;
my $loop;
while (!$contract_address) {

    $args->{method} = "eth_getTransactionReceipt";
    $args->{params} = [$contract_hash];
    $res = &_get($args);
# print Dumper($res) . "\n";
    $contract_address = $res->{result}->{contractAddress};
    print ".";
    sleep(1);
    $loop++;
    exit if $loop > 600;
}
print "\ncontract address:" . $contract_address ."\n";

print "---get code\n";
$args->{method} = "eth_getCode";
$args->{params} = [ $contract_address, "latest" ];
$res = &_get($args);
print Dumper($res) . "\n";
print "code address:" . $res->{result} . "\n";

print "----get ETH\n";

$args->{method} = "eth_getBalance";
$args->{params} = [ $address, "latest"];
$res = &_get($args);
print Dumper($res) . "\n";

$eth =  $res->{result};
$eth =~ s/\0x//;
$now_eth = $eth;
print "your ETH:" . hex($now_eth)."\n";
print "consumed  ETH:" . hex($prev_eth - $now_eth)."\n";
$prev_eth = $now_eth;

print "----call smartcontract\n";

$args->{method} = "web3_sha3";
$args->{params} = [ 'get()' ];
$res = &_get($args);
print Dumper($res) . "\n";

my $data = $res->{result};
print "data : $data\n";

$args->{method} = "eth_call";
$args->{params} = [{
    from => $address,
    to   => $contract_address,
    gas  => "0x76c0",
    data => $data, # ここにSha3でエンコードされたget()を入れる
 }];
$res = &_get($args);
print Dumper($res) . "\n";

sub _get {
    my $args = shift @_;
    
    $COUNT++;

    $args->{id} = $COUNT;
print Dumper($args) ."\n";
    my $furl = Furl->new();
    my $res = $furl->post($target_url,[], encode_json $args);

    return decode_json($res->content);
}
