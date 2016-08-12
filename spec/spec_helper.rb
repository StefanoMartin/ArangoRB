require "rspec"
require_relative File.expand_path('../../lib/arangorb', __FILE__)

RSpec.configure do |config|
	config.color = true
	config.before(:all) do
		ArangoServer.default_server user: "root", password: "", server: "localhost", port: "8529"
		ArangoServer.database = "MyDatabase"
		ArangoServer.collection = "MyCollection"
		ArangoServer.graph = "MyGraph"
		ArangoServer.user = "MyUser"
		ArangoServer.verbose = false
		ArangoServer.async = false
		@myDatabase = ArangoDatabase.new.create
		@myGraph = ArangoGraph.new.create
		@myCollection = ArangoCollection.new.create
		@myCollectionB = ArangoCollection.new(collection: "MyCollectionB").create
		@myDocument = ArangoDocument.new(body: {"Hello" => "World", "num" => 1}, key: "FirstDocument").create
		@myEdgeCollection = ArangoCollection.new(collection: "MyEdgeCollection").create_edge_collection
		@myGraph.addVertexCollection collection: "MyCollection"
		@myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
		@myAQL = ArangoAQL.new query: "FOR u IN MyCollection RETURN u.num"
		@myDoc = @myCollection.create_document document: [{"num" => 1, "_key" => "FirstKey"}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3}, {"num" => 2}, {"num" => 5}, {"num" => 2}]
		@myEdgeCollection.create_edge from: [@myDoc[0].id, @myDoc[1].id, @myDoc[2].id, @myDoc[3].id, @myDoc[7].id], to: [@myDoc[4].id, @myDoc[5].id, @myDoc[6].id, @myDoc[8].id]
		@myVertex = ArangoVertex.new(body: {"Hello" => "World", "num" => 1}, key: "FirstVertex").create
		@vertexA = ArangoVertex.new(body: {"Hello" => "World", "num" => 1}).create
	  @vertexB = ArangoVertex.new(body: {"Hello" => "Moon", "num" => 2}).create
	  @myEdge = ArangoEdge.new(from: @vertexA, to: @vertexB, collection: "MyEdgeCollection").create
		@myIndex = @myCollection.createIndex unique: false, fields: "num", type: "hash", id: "MyIndex"
		@myTraversal = ArangoTraversal.new
		@myUser = ArangoUser.new.create
		@myTask = ArangoTask.new id: "mytaskid", name: "MyTaskID", command: "(function(params) { require('@arangodb').print(params); })(params)", params: {"foo" => "bar", "bar" => "foo"}, period: 60
	end

	config.after(:all) do
		ArangoDatabase.new.destroy
		ArangoUser.new.destroy
		@myUser.destroy unless @myUser.nil?
		@myIndex.destroy unless @myIndex.nil?
	end
end
