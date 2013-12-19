#!/usr/bin/perl
# Script to update master and read back timestamps from slaves to calculate actual replication delay
# Michael Coburn, Percona, 2013-12-19
# 
# How to use:
# * Update database and statsd information first
# 1. run one instance of the script against the master to update the timestamps:
# * perl synthetic_slave_lag.pl master update
# 2. run a second instance of the script against each slave to read back timestamps:
# * perl synthetic_slave_lag.pl slave monitor
#
# Assumptions:
# * Servers are all running ntpd, otherwise the output will be meaningless
# * That you have already created a percona heartbeat table (pt-heartbeat)
# * Optional: Statsd is running, and category timing defined

use Time::HiRes qw(usleep gettimeofday tv_interval);
use DBI;
use strict;
use warnings;
use POSIX;
use Net::Statsd;

# get FQDN hostname and mode to run, mode of 'update' and 'monitor'
my $dbfqdn = $ARGV[0];
my $mode = $ARGV[1];

# DB connection information
my $dbuser = 'dbuser';
my $dbpass = 'dbpass';
my $dbname = 'percona';
my $dbtable = 'heartbeat';
# FQDN or IP
my $dbmaster = '10.90.128.99';
my $serverid = 99;

# How long to sleep. 100000 = 0.1 seconds
my $delay = 100000;

# Statsd, if you use it.
my $statsd_host = 'statsd.example.com';
my $statsd_port = 8125;
# Set below to 1 to actually submit results
my $statsd_enabled = 0;

## Shouldn't have to change anything below this line
####################################################

$Net::Statsd::HOST = $statsd_host;                                                                                                                                                                                
$Net::Statsd::PORT = $statsd_port;

# Database connections
my $dsn_slave = "DBI:mysql:database=$dbname;host=$dbfqdn";
my $dbh_slave = DBI->connect($dsn_slave, $dbuser, $dbpass);
my $dsn_master = "DBI:mysql:database=$dbname;host=$dbmaster";
my $dbh_master = DBI->connect($dsn_master, $dbuser, $dbpass);

# determine host portion of FQDN
my ($dbhost, @garbage) = split(/\./, $dbfqdn);

# Main loop
while ( 1 ) {
	my $now = gettimeofday();

    if ($mode eq "update") {
	    my $sth_master = $dbh_master->do("UPDATE $dbtable SET ts = " . $dbh_master->quote("$now") . " WHERE server_id = $serverid");
    }

    if ($mode eq "monitor") {
		my $sth_slave = $dbh_slave->prepare("SELECT ts from $dbtable where server_id = $serverid");
		$sth_slave->execute();
		while (my $ref = $sth_slave->fetchrow_hashref()) {
            # calculate current time, and do arithmetic to find delay
			my $t0 = gettimeofday();
			my $t1 = $ref->{'ts'};
			my $elapsed = ($t0 - $t1) * 1000;
            # round up to nearest integer
            $elapsed = ceil($elapsed);
	        print $elapsed, "\n";
            if ($statsd_enabled == 1) {
                Net::Statsd::timing("synthetic_slave_lag.master.$dbhost" => "$elapsed");
            }
        }
	}
    # Sleep before running again
	usleep ($delay);
}
