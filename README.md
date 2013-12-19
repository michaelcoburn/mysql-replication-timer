mysql-replication-timer
=======================

MySQL Replication Timer

Script to update master and read back timestamps from slaves to calculate actual replication delay
Michael Coburn, Percona, 2013-12-19
  
How to use:
* Update database and statsd information first
1. run one instance of the script against the master to update the timestamps:
* perl synthetic_slave_lag.pl master update
2. run a second instance of the script against each slave to read back timestamps:
* perl synthetic_slave_lag.pl slave monitor
 
Assumptions:
* Servers are all running ntpd, otherwise the output will be meaningless
* That you have already created a percona heartbeat table (pt-heartbeat)
* Optional: Statsd is running, and category timing defined
