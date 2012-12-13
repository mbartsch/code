#!/usr/bin/perl
use warnings;
use strict;
use DBI;
use Nagios::Plugin;
use Nagios::Plugin::Getopt;
use Data::Dumper;
my $dbname   = "+ASM1";
my $host     = "oracl1";
my $port     = "1521";
my $username = "sys";
my $password = "asm4dba";
my $lines = 0;
my $totalinserts = 0;
my $dbi_errorstr;
my $dbh;
my $np = Nagios::Plugin->new; 
my $hashref;
my $critical = 0;
my $warning = 0;

my $ng = Nagios::Plugin::Getopt->new(
           usage => "Usage: %s -H <host> -w <warning> -c <critical>",
           version => '0.1',
           url => 'http://www.openfusion.com.au/labs/nagios/',
           blurb => 'This plugin tests various stuff.',
         );
$ng->arg(
           spec => 'critical|c=i',
           help => q(Exit with CRITICAL status if fewer than INTEGER foobars are free),
           required => 1,
           default => 10,
         );

$ng->arg(
           spec => 'warning|w=i',
           help => q(Exit with WARNING status if fewer than INTEGER foobars are free),
           required => 1,
           default => 10,
         );

$ng->getopts;

eval {
	$dbh = DBI->connect("dbi:Oracle:host=$host;sid=$dbname;port=$port",
                     $username,
                     $password,
                     { ora_session_mode => 2 ,AutoCommit => 0, RaiseError => 0, PrintError => 0}
                   )
};
if (!$dbh){
	$np->nagios_exit( CRITICAL, "Cant connect to the database //$host:$port/$dbname");
}

my $query = "select name,total_mb,free_mb from v\$asm_diskgroup_stat";
my $sth = $dbh->prepare($query);
$sth->execute();
while ($hashref = $sth->fetchrow_hashref()){
        my $used_space=$hashref->{TOTAL_MB}-$hashref->{FREE_MB};
	my $pct_used=$used_space/$hashref->{TOTAL_MB}*100;
	if ($pct_used > $ng->get('critical')){
		print "CRIT: $hashref->{'NAME'} has $hashref->{FREE_MB} MB Free of $hashref->{TOTAL_MB}\n";
		$critical = 1;
	}
	if ($pct_used > $ng->get('warning')){
		print "WARN: $hashref->{'NAME'} has $hashref->{FREE_MB} MB Free of $hashref->{TOTAL_MB}\n";
		$warning = 1;
	}
	$np->add_perfdata(
		label => "$hashref->{'NAME'}",
		value => $hashref->{TOTAL_MB}-$hashref->{FREE_MB},
		warning   => $ng->get('warning'),
		critical   => $ng->get('critical'),
                max => $hashref->{TOTAL_MB},
                min => 0
	);
}
$dbh->disconnect();
if ($critical) {
	$np->nagios_exit ( CRITICAL , "ASM DiskGroup under " . $ng->get('critical') . "  % of free space" );
} elsif ($warning) {
	$np->nagios_exit ( WARNING , "ASM DiskGroup under " . $ng->get('warning') . " % of free space" );
} else {
	$np->nagios_exit ( OK , "ASM DiskGroup OK");
}
