use JSON::XS;
use strict;                     # Good practice
use warnings;                   # Good practice
use Tie::File;

sub acstime2human($) {
 my $acstime=shift(@_);
 my $epoch=($acstime-122192928000000000)/10000000;
 my $secs = ($epoch - int $epoch) * 1_000;
 my $intpoch = int $epoch;
 my ($sec, $min, $hour, $day,$month,$year) = (localtime($intpoch))[0,1,2,3,4,5]; 
 #my $a = $intpoch . "+" . substr($secs, 0 ,3) . "|";
 my $timestring = sprintf("%s-%s-%sT%02s:%02s:%02s.%03sZ",$year+1900,$month+1,$day,$hour,$min,$sec,int $secs);
 return $timestring;
}

my $lines = 0;
my $debug = 0;
my $count = 0;

tie @array, 'Tie::File', $ARGV[0] or die ...;
while (shift @array)
{
        if ($lines < $ARGV[1]) { $lines++; next; };
	my $json = $_;
	my $decoded_json = JSON::XS->new->utf8->decode( $json );
        if ($debug) {
        print "componentName    : " . $decoded_json->{'componentName'} . "\n";
        print "propertyName     : " . $decoded_json->{'propertyName'} . "\n";
        print "monitorPointName : " . $decoded_json->{'monitorPointName'} . "\n";
        print "serialNumber     : " . $decoded_json->{'serialNumber'} . "\n";
        print "location         : " . $decoded_json->{'location'} . "\n";
        print "acsTime          : " . $decoded_json->{'acsTime'} . "\n";
        print "monitorValue     : " . $decoded_json->{'monitorValue'} . "\n";
        print "index            : " . $decoded_json->{'index'} . "\n";
        print "date             : " . $decoded_json->{'date'}->{'$date'} . "\n";
        }
	printf("%s,%s,%s,%s,%s,%s,%s,%s\n",
		acstime2human($decoded_json->{'acsTime'}),
		$decoded_json->{'acsTime'},
		$decoded_json->{'componentName'},
		$decoded_json->{'propertyName'},
		$decoded_json->{'monitorPointName'},
		$decoded_json->{'serialNumber'},
		$decoded_json->{'monitorValue'},
		$decoded_json->{'location'},
		$decoded_json->{'index'});
		
}
close JSONFILE;
exit(0);
