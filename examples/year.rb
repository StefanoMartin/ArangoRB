# This example creates a Database with a Year graph with the following structure.
# Year --(TIME)--> Month --(TIME)--> Day --(TIME)--> Hour --(TIME)--> Minute
# Year --(NEXT)--> Next Year
# Month --(NEXT)--> Next Month
# Day --(NEXT)--> Next Day
# Hour --(NEXT)--> Next Hour
# Minute --(NEXT)--> Next Minute

require_relative '../lib/arangorb'
require 'objspace'

year = 2016

print "\n === DATABASE === \n"

server = Arango::Server.new username: "root", password: "root", server: "localhost",
  port: "8529", pool: false, active_cache: false, verbose: false
database = server.database name: "year"
graph = database.graph name: "yearGraph"
database.destroy rescue ""
database.create

print "\n === COLLECTIONS === \n"

minuteC = database.collection(name: "Minute").create
hourC   = database.collection(name: "Hour").create
dayC    = database.collection(name: "Day").create
monthC  = database.collection(name: "Month").create
yearC   = database.collection(name: "Year").create

nextC = database.collection(name: "NEXT", type: :edge).create
timeC = database.collection(name: "TIME", type: :edge).create

edgeDefinitions = [
  { collection: "NEXT", from: ["Year", "Month", "Day", "Hour", "Minute"], to: ["Year", "Month", "Day", "Hour", "Minute"] },
  { collection: "TIME", from: ["Year", "Month", "Day", "Hour"], to: ["Month", "Day", "Hour", "Minute"] }
]
graph.edgeDefinitions = edgeDefinitions
graph.create

print "\n === INITIALIZATION === \n"

t = Time.new(year)
new_year = t.strftime("%Y"); new_month = t.strftime("%m"); new_day = t.strftime("%d"); new_hour = t.strftime("%H"); new_minute = t.strftime("%M")
years = []; months = []; days = []; hours = []; minutes = []
nexts = []; times = []

new_yearV   = yearC.document name: "#{new_year}",
  body: {"value": "#{new_year}", "num": new_year.to_i}

new_monthV  = monthC.document name: "#{new_year}-#{new_month}",
  body: {"value": "#{new_year}-#{new_month}", "num": new_month.to_i}
new_dayV    = dayC.document name: "#{new_year}-#{new_month}-#{new_day}",
  body: {"value": "#{new_year}-#{new_month}-#{new_day}", "num": new_day.to_i}
new_hourV   = hourC.document name: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}",
  body: {"value": "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", "num": new_hour.to_i}
new_minuteV = minuteC.document name: "#{new_year}-#{new_month}-#{new_day}T#{new_hour}-#{new_minute}",
  body: {"value": "#{new_year}-#{new_month}-#{new_day}T#{new_hour}:#{new_minute}", "num": t.min}
years << new_yearV; months << new_monthV; days << new_dayV; hours << new_hourV; minutes << new_minuteV

times << timeC.document(from: new_yearV,  to: new_monthV)
times << timeC.document(from: new_monthV, to: new_dayV)
times << timeC.document(from: new_dayV,   to: new_hourV)
times << timeC.document(from: new_hourV,  to: new_minuteV)

old_yearV = new_yearV; old_monthV = new_monthV; old_dayV = new_dayV;
old_hourV = new_hourV; old_minuteV = new_minuteV
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
          new_yearV = yearC.document(name: "#{new_year}", body:
            {"value": "#{new_year}", "num": new_year.to_i})
          nexts << nextC.document(from: old_yearV, to: new_yearV)
          years << new_yearV
          old_yearV = new_yearV
          old_year = new_year
        end
        new_monthV = monthC.document(name: "#{new_year}-#{new_month}",
          body: {"value": "#{new_year}-#{new_month}", "num": new_month.to_i})
        nexts << nextC.document(from: old_monthV, to: new_monthV)
        times << timeC.document(from: new_yearV, to: new_monthV)
        months << new_monthV
        old_monthV = new_monthV
        old_month = new_month
      end
      new_dayV = dayC.document(name: "#{new_year}-#{new_month}-#{new_day}",
        body: {"value": "#{new_year}-#{new_month}-#{new_day}", "num": new_day.to_i})
      nexts << nextC.document(from: old_dayV, to: new_dayV)
      times << timeC.document(from: new_monthV, to: new_dayV)
      days << new_dayV
      old_dayV = new_dayV
      old_day = new_day
    end
    new_hourV = hourC.document(name:  "#{new_year}-#{new_month}-#{new_day}T#{new_hour}",
      body: {"value": "#{new_year}-#{new_month}-#{new_day}T#{new_hour}", "num": new_hour.to_i})
    nexts << nextC.document(from: old_hourV, to: new_hourV)
    times << timeC.document(from: new_dayV, to: new_hourV)
    hours << new_hourV
    old_hourV = new_hourV
    old_hour = new_hour
  end
  new_minuteV = Arango::Document.new(name:  "#{new_year}-#{new_month}-#{new_day}T#{new_hour}-#{new_minute}",
    collection: minuteC,
    body: {"value": "#{new_year}-#{new_month}-#{new_day}T#{new_hour}:#{new_minute}", "num": t.min})
  nexts << nextC.document(from: old_minuteV, to: new_minuteV)
  times << timeC.document(from: new_hourV, to: new_minuteV)
  minutes << new_minuteV
  old_minuteV = new_minuteV
end

print "\n === CREATION === \n"

server.async = true
minuteC.createDocuments document: minutes; print "C"
hourC.createDocuments document: hours;     print "C"
dayC.createDocuments document: days;       print "C"
monthC.createDocuments document: months;   print "C"
yearC.createDocuments document: years;     print "C"
nextC.createDocuments document: nexts;     print "C"
timeC.createDocuments document: times;     print "C\n"
