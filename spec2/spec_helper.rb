require "rspec"
require "arangorb"
# require_relative File.expand_path('../../lib/arangorb', __FILE__)

RSpec.configure do |config|
	config.color = true
	config.before(:all) do
		@server = Arango::Server.new user: "root", password: "root",
			server: "localhost", port: "8529"
		@myDatabase    = @server.database(name: "MyDatabase").create
		@myGraph       = @server.graph(name: "MyGraph").create
		@myCollection  = @myDatabase.collection(name: "MyCollection").create
		@myCollectionB = @myDatabase.collection(name: "MyCollectionB").create
		@myDocument    = @myCollection.document(name: "FirstDocument",
			body: {"Hello" => "World", "num" => 1}).create
		@myEdgeCollection = @myDatabase.collection.new(
			collection: "MyEdgeCollection", type: "Edge").create
		@myGraph.addVertexCollection collection: "MyCollection"
		@myGraph.addEdgeCollection collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
		@myAQL = @myDatabase.aql query: "FOR u IN MyCollection RETURN u.num"
		@myDoc = @myCollection.createDocuments document: [{"num" => 1, "_key" => "FirstKey"},
			{"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1}, {"num" => 1},
			{"num" => 1}, {"num" => 2}, {"num" => 2}, {"num" => 2}, {"num" => 3},
			{"num" => 2}, {"num" => 5}, {"num" => 2}]
		@myCollection.graph = @myGraph
		@myVertex = @myCollection.vertex(body: {"Hello" => "World", "num" => 1},
			name: "FirstVertex").create
		@vertexA = @myCollection.vertex(body: {"Hello" => "World", "num" => 1}).create
	  @vertexB = @myCollection.vertex(body: {"Hello" => "Moon", "num" => 2}).create
	  @myEdge = @myEdgeCollection.edge(from: @vertexA, to: @vertexB).create
		@myIndex = @myCollection.index(unique: false, fields: "num", type: "hash",
			id: "MyIndex").create
		@myTraversal = @vertexA.traversal
		@myUser = @server.user(name: "MyUser")
		print @myUser.destroy
		@myUser.create
		@myTask = @myDatabase.task(id: "mytaskid", name: "MyTaskID",
			command: "(function(params) { require('@arangodb').print(params); })(params)",
			params: {"foo" => "bar", "bar" => "foo"}, period: 60)
	end

	config.after(:all) do
		@myDatabase.destroy
		@myUser.destroy  unless @myUser.nil?
		@myIndex.destroy unless @myIndex.nil?
	end
end
