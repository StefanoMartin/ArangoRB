# This example creates a Database with a Year graph with the following structure.
# Year --(TIME)--> Month --(TIME)--> Day --(TIME)--> Hour --(TIME)--> Minute
# Year --(NEXT)--> Next Year
# Month --(NEXT)--> Next Month
# Day --(NEXT)--> Next Day
# Hour --(NEXT)--> Next Hour
# Minute --(NEXT)--> Next Minute

require_relative File.expand_path('../../lib/arangorb', __FILE__)

year = 2016

print "\n === DATABASE === \n"

ArangoServer.default_server
ArangoServer.database = "year"
ArangoServer.graph = "yearGraph"
ArangoDatabase.new.destroy
ArangoDatabase.new.create

print "\n === COLLECTIONS === \n"

minuteC = ArangoCollection.new(collection: "Minute").create
hourC   = ArangoCollection.new(collection: "Hour").create
dayC    = ArangoCollection.new(collection: "Day").create
monthC  = ArangoCollection.new(collection: "Month").create
yearC   = ArangoCollection.new(collection: "Year").create

nextC = ArangoCollection.new(collection: "NEXT").create_edge_collection
timeC = ArangoCollection.new(collection: "TIME").create_edge_collection

edgeDefinitions = [
  { collection: "NEXT", from: ["Year", "Month", "Day", "Hour", "Minute"], to: ["Year", "Month", "Day", "Hour", "Minute"] },
  { collection: "TIME", from: ["Year", "Month", "Day", "Hour"], to: ["Month", "Day", "Hour", "Minute"] }
]
ArangoGraph.new(edgeDefinitions: edgeDefinitions).create

print "\n === INITIALIZATION === \n"


t = Time.new(year)

new_year = t.strftime("%Y"); new_month = t.strftime("%m"); new_day = t.strftime("%d"); new_hour = t.strftime("%H"); new_minute = t.strftime("%M")
years = []; months = []; days = []; hours = []; minutes = []
nexts = []; times = []

new_yearV   = ArangoDocument.new key: "#{new_year}", collection: yearC, body: {"value" => "#{new_year}", "num" => new_year.to_i}
new_monthV  = ArangoDocument.new key: "#{new_year}-#{new_month}", collection: monthC, body: {"value" => "#{new_year}-#{new_month}", "num" => new_month.to_i}
new_dayV    = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}", collection: dayC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}", "num" => new_day.to_i}
new_hourV   = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", collection: hourC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", "num" => new_hour.to_i}
new_minuteV = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}-#{new_minute}", collection: minuteC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}T#{new_hour}:#{new_minute}", "num" => t.min}
years << new_yearV; months << new_monthV; days << new_dayV; hours << new_hourV; minutes << new_minuteV

times << ArangoDocument.new(collection: timeC, from: new_yearV,  to: new_monthV)
times << ArangoDocument.new(collection: timeC, from: new_monthV, to: new_dayV)
times << ArangoDocument.new(collection: timeC, from: new_dayV,   to: new_hourV)
times << ArangoDocument.new(collection: timeC, from: new_hourV,  to: new_minuteV)

old_yearV = new_yearV; old_monthV = new_monthV; old_dayV = new_dayV; old_hourV = new_hourV; old_minuteV = new_minuteV
old_year = new_year; old_month = new_month; old_day = new_day; old_hour = new_hour


while(t.year < year+1)
  t += 60
  new_minute = t.strftime("%M")
  new_hour = t.strftime("%H")
  if(new_hour != old_hour)
    new_day = t.strftime("%d")
    if(new_day != old_day)
      new_month = t.strftime("%m")
      if(new_month != old_month)
        print "M"
        new_year = t.strftime("%Y")
        if(new_year != old_year)
          new_yearV = ArangoDocument.new key: "#{new_year}", collection: yearC, body: {"value" => "#{new_year}", "num" => new_year.to_i}
          nexts << ArangoDocument.new(collection: nextC, from: old_yearV, to: new_yearV)
          years << new_yearV
          old_yearV = new_yearV
          old_year = new_year
        end
        new_monthV = ArangoDocument.new key: "#{new_year}-#{new_month}", collection: monthC, body: {"value" => "#{new_year}-#{new_month}", "num" => new_month.to_i}
        nexts << ArangoDocument.new(collection: nextC, from: old_monthV, to: new_monthV)
        times << ArangoDocument.new(collection: timeC, from: new_yearV, to: new_monthV)
        months << new_monthV
        old_monthV = new_monthV
        old_month = new_month
      end
      new_dayV = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}", collection: dayC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}", "num" => new_day.to_i}
      nexts << ArangoDocument.new(collection: nextC, from: old_dayV, to: new_dayV)
      times << ArangoDocument.new(collection: timeC, from: new_monthV, to: new_dayV)
      days << new_dayV
      old_dayV = new_dayV
      old_day = new_day
    end
    new_hourV = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", collection: hourC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", "num" => new_hour.to_i}
    nexts << ArangoDocument.new(collection: nextC, from: old_hourV, to: new_hourV)
    times << ArangoDocument.new(collection: timeC, from: new_dayV, to: new_hourV)
    hours << new_hourV
    old_hourV = new_hourV
    old_hour = new_hour
  end
  new_minuteV = ArangoDocument.new key: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}-#{new_minute}", collection: minuteC, body: {"value" => "#{new_year}-#{new_month}-#{new_day}T#{new_hour}:#{new_minute}", "num" => t.min}
  nexts << ArangoDocument.new(collection: nextC, from: old_minuteV, to: new_minuteV)
  times << ArangoDocument.new(collection: timeC, from: new_hourV, to: new_minuteV)
  minutes << new_minuteV
  old_minuteV = new_minuteV
end

print "\n === CREATION === \n"

ArangoServer.async = true
minuteC.create_document document: minutes; print "C"
hourC.create_document document: hours;     print "C"
dayC.create_document document: days;       print "C"
monthC.create_document document: months;   print "C"
yearC.create_document document: years;     print "C"
nextC.create_document document: nexts;     print "C"
timeC.create_document document: times;     print "C\n"
