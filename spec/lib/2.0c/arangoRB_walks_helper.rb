require_relative './../../spec_helper'

describe Arango::Database do
  context "#retrieve" do
    it "walk" do
      # print "\n"
      # print "#{@myDatabase.name}\n"
      # print "#{@myDatabase['MyCollection'].name}\n"
      # print "#{@myDatabase['MyCollection'].documents.map{|x| x.name}}\n"
      # print "#{@myDatabase['MyCollection']["Second_Key"].name}\n"
      # print "#{@myDatabase['MyCollection'][@myDatabase['MyCollection']["Second_Key"]].name}\n"
      # print "#{@myDatabase['MyCollection']["Second_Key"].out("MyEdgeCollection").map{|x| x.name}}\n"
      # print "#{@myDatabase['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.retrieve.body[:num]}\n"
      # print "#{@myDatabase['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.retrieve.database.name}\n"
      # print "#{@myDatabase['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.retrieve.database['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.retrieve.body[:num]}\n"
      expect(@myDatabase['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.database['MyCollection']["Second_Key"].out("MyEdgeCollection")[0].to.retrieve.body[:num]).to eq 2
    end
  end
end
