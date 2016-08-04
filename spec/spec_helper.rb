require "rspec"
require_relative File.expand_path('../../lib/arangorb', __FILE__)

RSpec.configure do |config|
	config.color = true
	config.before(:all) do
		ArangoS.default_server user: "root", password: "", server: "localhost", port: "8529"
		ArangoS.database = "MyDatabase"
		ArangoS.collection = "MyCollection"
		ArangoS.graph = "MyGraph"
		ArangoS.user = "MyUser"
		ArangoS.async = false
		@myDatabase = ArangoDB.new.create
		@myGraph = ArangoG.new.create
		@myCollection = ArangoC.new.create
		@myCollectionB = ArangoC.new(collection: "MyCollectionB").create
		@myDocument = ArangoDoc.new(body: {"Hello" => "World", "num" => 1}, key: "FirstDocument").create
		@myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
		@myGraph.addVertexCollection collection: "MyCollection"
		@myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
		@myAQL = ArangoAQL.new query: "FOR u IN MyCollection RETURN u.num"
		@myDoc = @myCollection.create_document document: [{"num" => 1, "_key" => "FirstKey"}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3}, {"num" => 2}, {"num" => 5}, {"num" => 2}]
		@myEdgeCollection.create_edge from: [@myDoc[0].id, @myDoc[1].id, @myDoc[2].id, @myDoc[3].id, @myDoc[7].id], to: [@myDoc[4].id, @myDoc[5].id, @myDoc[6].id, @myDoc[8].id]
		@myVertex = ArangoV.new(body: {"Hello" => "World", "num" => 1}, key: "FirstVertex").create
		@vertexA = ArangoV.new(body: {"Hello" => "World", "num" => 1}).create
	  @vertexB = ArangoV.new(body: {"Hello" => "Moon", "num" => 2}).create
	  @myEdge = ArangoE.new(from: @vertexA, to: @vertexB, collection: "MyEdgeCollection").create
		@myIndex = @myCollection.createIndex unique: false, fields: "num", type: "hash"
		@myTraversal = ArangoT.new
		@myUser = ArangoU.new.create
	end

	config.after(:all) do
		ArangoDB.new.destroy
		ArangoU.new.destroy
	end
end
#
# before :all do
# 	ArangoS.default_server user: "root", password: "tretretre", server: "localhost", port: "8529"
# 	ArangoS.database = "MyDatabase"
# 	ArangoS.collection = "MyCollection"
# 	ArangoS.graph = "MyGraph"
# 	ArangoDB.new.create
# 	@myGraph = ArangoG.new.create
# 	@myCollection = ArangoC.new.create
# 	@myEdgeCollection = ArangoC.new(collection: "MyEdgeCollection").create_edge_collection
# 	@myGraph.addVertexCollection collection: "MyCollection"
# 	@myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
# 	@myAQL = ArangoAQL.new query: "FOR u IN MyCollection RETURN u.num"
# 	@myDoc = @myCollection.create_document document: [{"num" => 1, "_key" => "FirstKey"}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3}, {"num" => 2}, {"num" => 5}, {"num" => 2}]
# 	@myEdgeCollection.create_edge from: [@myDoc[0].id, @myDoc[1].id, @myDoc[2].id, @myDoc[3].id, @myDoc[7].id], to: [@myDoc[4].id, @myDoc[5].id, @myDoc[6].id, @myDoc[8].id]
# end
#
# after :all do
# 	ArangoDB.new.destroy
# end
