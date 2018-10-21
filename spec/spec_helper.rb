require "rspec"
require "pry-byebug"
# require "arangorb"
require_relative File.expand_path('../../lib/arangorb', __FILE__)

RSpec.configure do |config|
	config.color = true
	config.before(:all) do
		@server = Arango::Server.new username: "root", password: "root",
			server: "localhost", port: "8529", pool: true
		@myDatabase    = @server.database(name: "MyDatabase")
		@myDatabase.create
		@myGraph       = @myDatabase.graph(name: "MyGraph").create
		@myCollection  = @myDatabase.collection(name: "MyCollection").create
		@myCollectionB = @myDatabase.collection(name: "MyCollectionB").create
		@myDocument    = @myCollection.document(name: "FirstDocument",
			body: {"Hello": "World", "num": 1}).create
		@myEdgeCollection = @myDatabase.collection(
			name: "MyEdgeCollection", type: "Edge").create
		@myGraph.addVertexCollection collection: "MyCollection"
		@myGraph.addEdgeDefinition collection: "MyEdgeCollection", from: "MyCollection", to: "MyCollection"
		@myAQL = @myDatabase.aql query: "FOR u IN MyCollection RETURN u.num"
		@myDoc = @myCollection.createDocuments document: [{"num": 1, "_key": "FirstKey"},
			{"num": 1}, {"num": 1}, {"num": 1}, {"num": 1}, {"num": 1},
			{"num": 1}, {"num": 2}, {"num": 2}, {"num": 2}, {"num": 3},
			{"num": 2}, {"num": 5}, {"num": 2}]
		@myCollection.graph = @myGraph
		@myEdgeCollection.graph = @myGraph
		@myVertex = @myCollection.vertex(body: {"Hello": "World", "num": 1},
			name: "FirstVertex").create
		@vertexA = @myCollection.vertex(body: {"Hello": "World", "num": 1}, name: "Second_Key").create
	  @vertexB = @myCollection.vertex(body: {"Hello": "Moon", "num": 2}).create
	  @myEdge = @myEdgeCollection.edge(from: @vertexA, to: @vertexB).create
		@myIndex = @myCollection.index(unique: false, fields: "num", type: "hash",
			id: "MyIndex").create
		@myTraversal = @vertexA.traversal
		@myUser = @server.user(name: "MyUser")
		begin
			@myUser.destroy
		rescue Arango::Error => e
		end
		@myUser.create
		@myTask = @myDatabase.task(id: "mytaskid", name: "MyTaskID",
			command: "(function(params) { require('@arangodb').print(params); })(params)",
			params: {"foo": "bar", "bar": "foo"}, period: 60).create
	end

	config.after(:all) do
		[@myIndex, @myDatabase, @myUser].each do |c|
			begin
				c.destroy unless c.nil?
			rescue Arango::Error => e
			end
		end
	end
end
