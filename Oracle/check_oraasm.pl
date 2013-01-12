#!/usr/bin/perl
# This is a nagios plugin to check oracle asm disk space availability
# licensed under GPLv2
# Marcelo Bartsch <spam-mb+github@bartsch.cl>
# 
use warnings;
use strict;
use DBI;
use Nagios::Plugin;
use Nagios::Plugin::Getopt;
use Data::Dumper;
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
           help => q(Exit with CRITICAL status if used space is above 85%),
           required => 1,
           default => 90,
         );

$ng->arg(
           spec => 'warning|w=i',
           help => q(Exit with WARNING status if used space is above 70%),
           required => 1,
           default => 80,
         );

$ng->arg(
           spec => 'asminstance|a=s',
           help => q(ASM Instance name),
           required => 1,
           default => '+ASM',
         );

$ng->arg(
           spec => 'host|H=s',
           help => q(HOSTNAME Instance name),
           required => 1,
           default => 'localhost',
         );
$ng->arg(
           spec => 'port|p=i',
           help => q(listener port number Instance name),
           required => 1,
           default => 1521
         );

$ng->arg(
           spec => 'username|u=s',
           help => q(ASM DBA username),
           required => 1,
           default => 'sys'
         );

$ng->arg(
           spec => 'password|P=s',
           help => q(ASM DBA password),
           required => 1,
           default => 'oracle'
         );
$ng->getopts;

my $dbname = $ng->get('asminstance');
my $host = $ng->get('host');
my $port = $ng->get('port');
my $username = $ng->get('username');
my $password = $ng->get('password');

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
        $pct_used = sprintf("%.2f",$pct_used);
	if ($pct_used > $ng->get('critical')){
		print "CRIT: $hashref->{'NAME'} has $hashref->{FREE_MB} MB Free of $hashref->{TOTAL_MB} MB ( $pct_used % Used )";
		$critical = 1;
	}
	if ($pct_used > $ng->get('warning')){
		print "WARN: $hashref->{'NAME'} has $hashref->{FREE_MB} MB Free of $hashref->{TOTAL_MB} MB ( $pct_used % Used )";
		$warning = 1;
	}
	$np->add_perfdata(
		label => "$hashref->{'NAME'} % Used Space",
		value => $pct_used
		warning   => $ng->get('warning'),
		critical   => $ng->get('critical'),
                max => 100,
                min => 0
	);
}
$dbh->disconnect();
if ($critical) {
	print "\n";
	$np->nagios_exit ( CRITICAL , "ASM DiskGroup under " . $ng->get('critical') . "  % of free space" );
} elsif ($warning) {
	print "\n";
	$np->nagios_exit ( WARNING , "ASM DiskGroup under " . $ng->get('warning') . " % of free space" );
} else {
	$np->nagios_exit ( OK , "ASM DiskGroup OK");
}
