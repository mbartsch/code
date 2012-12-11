use DBI;
use JSON::XS;
use strict;                     # Good practice
use warnings;                   # Good practice
my $dbname   = "XXXX";
my $host     = "XXXXXXXXXXXXXXXXXXXXXXXXX";
my $port     = "1521";
my $username = "XXXXXXX";
my $password = "XXXXXXX";
my $lines = 0;
my $totalinserts = 0;
my $dbh = DBI->connect("dbi:Oracle:host=$host;sid=$dbname;port=$port",
                     $username,
                     $password,
                     {AutoCommit => 0, RaiseError => 0, PrintError => 1}
                   );

sub acstime2human($) {
 my $acstime=shift(@_);
 my $epoch=($acstime-122192928000000000)/10000000;
 my $secs = ($epoch - int $epoch) * 1_000;
 my $intpoch = int $epoch;
 my ($sec, $min, $hour, $day,$month,$year) = (localtime($intpoch))[0,1,2,3,4,5];
 #my $a = $intpoch . "+" . substr($secs, 0 ,3) . "|";
 my $timestring = sprintf("%s-%s-%s %02s:%02s:%02s.%03s",$year+1900,$month+1,$day,$hour,$min,$sec,int $secs);
  return $timestring;
};

my $query='insert into monitorpoints (           id,
                                      componentname, 
                                       propertyname,
                                   monitorpointname,
                                       serialnumber,
                                           location,
                                            acstime,
                                       monitorvalue,
                                             tstamp,
                                                idx) 
                                             values(
                                 mpoint_seq.nextval,
                                                  ?,
                                                  ?,
                                                  ?,
                                                  ?,
                                                  ?,
                                                  ?,
                                                  ?,
      to_timestamp(?,\'YYYY-MM-DD HH24:MI:SS.FF3\'),
                                                  ?)';
my $sth = $dbh->prepare($query);
my $counter = 0;
my $debug   = 0;
open JSONFILE, '<', $ARGV[0];
while (<JSONFILE>)
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
        print "acsTime          : " . acstime2human($decoded_json->{'acsTime'}) . "\n";
        print "monitorValue     : " . $decoded_json->{'monitorValue'} . "\n";
        print "index            : " . $decoded_json->{'index'} . "\n";
        print "date             : " . $decoded_json->{'date'}->{'$date'} . "\n";
        }
        $sth->execute($decoded_json->{'componentName'},
                       $decoded_json->{'propertyName'},
                   $decoded_json->{'monitorPointName'},
                       $decoded_json->{'serialNumber'},
                           $decoded_json->{'location'},
                            $decoded_json->{'acsTime'},
                       $decoded_json->{'monitorValue'},
                       acstime2human($decoded_json->{'acsTime'}),
                       $decoded_json->{'index'});
        my $rv = $dbh->err;
        if ($rv) {
		print "\n\n\n Error " . $rv;
		$dbh->commit();
                $counter=0;
	}
        $counter++;
	if ($counter > 100000) {
                $totalinserts = $totalinserts + $counter;
                print "ORA Commit ($totalinserts) " . `date` ;
		$dbh->commit();
		$counter = 0;
	}
}
close JSONFILE;
$dbh->commit();
$dbh->disconnect();
exit(0);
