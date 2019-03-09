# This example follows the example year.rb and it simply prints some results on the screen.

# require_relative File.expand_path('../../lib/arangorb', __FILE__)
require "awesome_print"
require "arangorb"

# OPEN REMOTE DATABASE
server_master = Arango::Server.new username: "root", password: "root", server: "", port: "8529"
database_master = server_master.database name: "year"
server_slave = Arango::Server.new username: "root", password: "root", server: "", port: "8529"
database_slave = server_slave.database name: "year" # It will be overwritten
myReplication = database_slave.replication(master: database_master)

print "\n === REPLICATE === \n"
# REPLICATION (only once)
# From our local database (tcp://173.17.8.101:8529) to our remote database (tcp://11.10.1.971:8529)
ap myReplication.sync

print "\n === INFORMATION === \n"
# INFO
ap database_slave.inventory # Fetch Collection data
print "\n =========== \n"
day_class = database_slave["Day"]
print day_class.dump # Fetch all the data in one class from one tick to another
print "\n =========== \n"
ap myReplication.logger # Returns the current state of the server's replication logger
print "\n =========== \n"
print myReplication.loggerFollow # Returns data from the server's replication log.
print "\n =========== \n"
ap myReplication.firstTick # Return the first available tick value from the server
print "\n =========== \n"
ap myReplication.rangeTick # Returns the currently available ranges of tick values for all currently available WAL logfiles.
print "\n =========== \n"
ap myReplication.serverId # Returns the servers id.
print "\n =========== \n"

# REPLICATION (master-slave)
# From the master: our local database (tcp://173.17.8.101:8529), to the slave: our remote database (tcp://11.10.1.971:8529)
print "\n === CREATE SLAVE === \n"
myReplication.idleMinWaitTime = 10
myReplication.verbose = true
ap myReplication.enslave

# MANAGE THE REPLICATION

print "\n === MANAGE REPLICATION === \n"
ap myReplication.configuration # check the Configuration of the Replication
print "\n =========== \n"
ap myReplication.state # check the status of the Replication
print "\n =========== \n"
ap myReplication.stop # stop the Replication
print "\n =========== \n"
myReplication.idleMinWaitTime = 100
myReplication.idleMaxWaitTime = 10
ap myReplication.modify  # modify the Configuration of the Replication (you can modify only a stopped Replication)
print "\n =========== \n"
ap myReplication.start # restart the replication
print "\n =========== \n"
ap myReplication.configurationn # check the modification
print "\n =========== \n"
myReplication.stopn # stop the Replication
