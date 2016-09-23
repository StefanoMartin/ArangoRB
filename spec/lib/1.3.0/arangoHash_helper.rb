require_relative './../../spec_helper'

describe "ArangoHash" do
  context "#hash" do
    it "hash" do
      @myDatabase.retrieve
      @myCollection.retrieve
      @myEdgeCollection.retrieve
      @myGraph.retrieve
      @myAQL.execute
      @myVertex.retrieve
      @myEdge.retrieve
      @myIndex.retrieve
      @myUser.retrieve
      @myTask.retrieve

      print "#{@myDatabase.to_h}\n"
      print "#{@myCollection.to_h}\n"
      print "#{@myEdgeCollection.to_h}\n"
      print "#{@myGraph.to_h}\n"
      print "#{@myAQL.to_h}\n"
      print "#{@myVertex.to_h}\n"
      print "#{@myEdge.to_h}\n"
      print "#{@myIndex.to_h}\n"
      print "#{@myUser.to_h}\n"
      print "#{@myTask.to_h}\n"
      expect(@myTask.to_hash.class).to be Hash
    end
  end
end
