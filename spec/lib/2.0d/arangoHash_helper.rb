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

      # print "#{@myDatabase.to_h}\n"
      # print "#{@myCollection.to_h}\n"
      # print "#{@myEdgeCollection.to_h}\n"
      # print "#{@myGraph.to_h}\n"
      # print "#{@myAQL.to_h}\n"
      # print "#{@myVertex.to_h}\n"
      # print "#{@myEdge.to_h}\n"
      # print "#{@myIndex.to_h}\n"
      # print "#{@myUser.to_h}\n"
      # print "#{@myTask.to_h}\n"
      # print "#{@server.cache.to_h}\n"
      [@server, @myDatabase, @myCollection, @myEdgeCollection, @myGraph, @myAQL,
        @myVertex, @myEdge, @myIndex, @myUser, @myTask, @server.cache].each do |s|
          expect(s.to_h.class).to eq Hash
      end
    end
  end
end
