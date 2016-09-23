# This example follows the example year.rb and it simply prints some results on the screen.

require_relative File.expand_path('../../lib/arangorb', __FILE__)

ArangoServer.default_server
ArangoServer.database = "year"
ArangoServer.graph = "yearGraph"

yearDatabase = ArangoDatabase.new.retrieve
print "I am using the following Database: #{yearDatabase.name}.\n"

collections = yearDatabase.collections
collections_names = collections.map{|x| x.name}
print "It has normal classes #{collections_names}"

system_collections = yearDatabase.collections excludeSystem: false
system_collections_names = system_collections.map{|x| x.name} - collections_names
print " and system classes #{system_collections_names}.\n"

years = yearDatabase["Year"].retrieve
print "The collection #{years.name} has #{years.count} elements with the following values: "
years_name = years.documents.map{|x| x.body["value"]}
print "#{years_name}.\n"

year2016 = years["2016"].retrieve
months2016 = year2016.out("TIME").map{|time| time.to}
print "The year #{year2016.body["value"]} has #{months2016.length} elements with the following values: "
print "#{months2016.map{|month| month.body["value"]}.sort}\n"

february2016 = months2016.select{|month| month.body["value"] == "2016-02"}
print "#{february2016}"
