# This example follows the example year.rb and it simply prints some results on the screen.

require_relative File.expand_path('../../lib/arangorb', __FILE__)
require "awesome_print"

ArangoServer.default_server
ArangoServer.database = "year"
ArangoServer.graph = "yearGraph"

myDB = ArangoDatabase.new
ap myDB.inventory # Fetch Collection data
day_class = myDB["Day"]
print day_class.dump from: "40468131", to: "40468200"# Fetcj all the data in one class from one tick to another

# Start replication

test1 = myDB.sync endpoint: "tcp://172.17.8.101:8529", username: "root", password: "tretretre"
ap test1
