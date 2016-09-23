# This example follows the example year.rb and it simply prints some results on the screen.

require_relative File.expand_path('../../lib/arangorb', __FILE__)

ArangoServer.default_server
ArangoServer.database = "year"

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

february2016 = months2016.select{|month| month.body["value"] == "2016-02"}.first
january2016 = february2016.in("NEXT")[0].from
march2016 = february2016.out("NEXT")[0].to
print "The month #{february2016.body["value"]} comes after #{january2016.body["value"]} and before #{march2016.body["value"]}.\n"

today = "2016-09-23T10:56"
today = today.split(/-|T|:/).map{|x| x.to_i}
query = "FOR v,e,p IN 1..4 ANY \"Year/#{today[0]}\" GRAPH \"yearGraph\" FILTER p.vertices[1].num == #{today[1]} && p.vertices[2].num == #{today[2]} && p.vertices[3].num == #{today[3]} && p.vertices[4].num == #{today[4]} RETURN p.vertices[4]"
value = ArangoAQL.new(query: query).execute
print "This example was created at this date: #{value.result.first.body["value"]}.\n"
