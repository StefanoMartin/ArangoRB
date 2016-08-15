require_relative './../../spec_helper'

describe ArangoDatabase do
  context "#retrieve" do
    it "walk" do
      print "#{@myDatabase.name}\n"
      print "#{@myDatabase['MyCollection'].name}\n"
      print "#{@myDatabase['MyCollection'].documents.map{|x| x.name}}\n"
      print "#{@myDatabase['MyCollection']["FirstKey"].name}\n"
      print "#{@myDatabase['MyCollection'][@myDatabase['MyCollection']["FirstKey"]].name}\n"
      print "#{@myDatabase['MyCollection']["FirstKey"].out("MyEdgeCollection").map{|x| x.name}}\n"
      print "#{@myDatabase['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.body["num"]}\n"
      print "#{@myDatabase['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.database.name}\n"
      print "#{@myDatabase['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.database['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.body["num"]}\n"
      expect(@myDatabase['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.database['MyCollection']["FirstKey"].out("MyEdgeCollection")[0].to.body["num"]).to eq 1
    end
  end
end
