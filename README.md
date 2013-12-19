mysql-replication-timer
=======================

# MySQL Replication Timer

Script to update master and read back timestamps from slaves to calculate actual replication delay
  
## How to use:

1. Update database and statsd information first
2. Run one instance of the script against the master to update the timestamps:
3. Run a second instance of the script against each slave to read back timestamps:

## Assumptions:
* Servers are all running ntpd, otherwise the output will be meaningless
* That you have already created a percona heartbeat table (pt-heartbeat)
* Optional: Statsd is running, and category timing defined

## Syntax

`perl synthetic_slave_lag.pl master update`

`perl synthetic_slave_lag.pl slave monitor`
