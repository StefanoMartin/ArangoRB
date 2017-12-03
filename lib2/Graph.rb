# ==== GRAPH ====

module Arango
class Graph
  def initialize(graph:, database:, edgeDefinitions: [], orphanCollections: [])
    satisfy_class?(graph, "graph", [Arango::Graph, String])
    satisfy_class?(database, "database", [Arango::Database])
    satisfy_class?(edgeDefinitions, "edgeDefinitions", [Arango::Collection, String])
    satisfy_class?(orphanCollections, "orphanCollections", [Arango::Collection, String])

    @database = database
    @client = @database.client
    edgeDefinitions.each do |edge|
      if edge.is_a?(String)
        edge = Arango::Collection.new(collection: edge, database: @database)
      end
    end
    @edgeDefinitions = edgeDefinitions
    orphanCollections.each do |orphanCollection|
      if orphanCollection.is_a?(String)
        orphanCollection = Arango::Collection.new(collection: orphanCollection, database: @database)
      end
    end
    @orphanCollections = orphanCollections

    if graph.is_a?(String)
      @graph = graph
    elsif database.is_a?(Arango::Graph)
      @graph = graph.name
    end
  end

  attr_reader :graph, :database, :client, :edgeDefinitions, :orphanCollections
  alias name graph

# === RETRIEVE ===

  def to_hash
    {
      "graph" => @graph,
      "collection" => @collection.to_h,
      "database" => @database.to_h,
      "edgeDefinitions" => @edgeDefinitions.map{|x| x.to_h},
      "orphanCollections" => @orphanCollections.map{|x| x.to_h}
    }.delete_if{|k,v| v.nil?}
  end
  alias to_h to_hash

# === GET ===

  def retrieve  # TESTED
    result = @client.request(action: "GET",
      url: "/_db/#{@database.name}/_api/gharial/#{@graph}")
    return result if @client.async != false
    @edgeDefinitions = result["graphs"]["edgeDefinitions"].map do |edge|
      Arango::Collection.new(collection: edge["collection"], database: @database, from: edge["from"], to: edge["to"], type: "Edge")
    end
    @orphanCollections = result["graph"]["orphanCollections"].map |orpCol|
      Arango::Collection.new(collection: orpCol["collection"], database: @database)
    end
    self
  end

# === POST ===

  def create  # TESTED
    body = { "name" => @graph, "edgeDefinitions" => @edgeDefinitions, "orphanCollections" => @orphanCollections }
    @client.request(action: "POST",
     url: "/_db/#{@database.name}/_api/gharial", body: body)
    return result if @client.async != false
    self
  end

# === DELETE ===

  def destroy  # TESTED
    @client.request(action: "DELETE",
     url: "/_db/#{@database.name}/_api/gharial/#{@graph}")
  end

# === VERTEX COLLECTION  ===

  def vertexCollections  # TESTED
    @client.request(action: "GET",
      url: "/_db/#{@database.name}/_api/gharial/#{@graph}/vertex"
    return result if @client.async != false
    result["collections"].map do |x|
      Arango::Collection.new(collection: x, database: @database)
    end
  end

  def addVertexCollection(collection:)
    satisfy_class?(collection, "collection", [Arango::Collection, String])
    if collection.is_a?(String)
      collection = Arango::Collection.new(collection: collection,
        database: @database)
    end
    body = { "collection" => collection.name }
    result = @client.request(action: "POST", body: body,
      url: "/_db/#{@database.name}/_api/gharial/#{@graph}/vertex")
    return result if @client.async != false
    @orphanCollections << collection
  end

  def removeVertexCollection(collection:)
    satisfy_class?(collection, "collection", [Arango::Collection, String])
    collection = collection.is_a?(String) ? collection : collection.name
    result = @client.request(action: "DELETE",
      url: "/_db/#{@database.name}/_api/gharial/#{@graph}/vertex/#{collection}")
    return result if @client.async != false
    @orphanCollections -= [collection]
    self
  end

# === EDGE COLLECTION ===

  def edgeCollections
    @client.request(action: "GET",
      url: "/_db/#{@database.name}/_api/gharial/#{@graph}/edge"
    return result if @client.async != false
    result["collections"].map do |x|
      Arango::Collection.new(collection: x, database: @database)
    end
  end

  def addEdgeCollection(collection:, from:, to:, replace: false)
    satisfy_class?(collection, "from", [Arango::Collection, String])
    satisfy_class?(collection, "to", [Arango::Collection, String])
    from = from.is_a?(String) ? [from] : from.is_a?(ArangoCollection) ? [from.collection] : from
    to = to.is_a?(String) ? [to] : to.is_a?(ArangoCollection) ? [to.collection] : to
    body = {}
    collection = collection.is_a?(String) ? collection : collection.collection
    body["collection"] = collection
    body["from"] = from.map{|f| f.is_a?(String) ? f : f.id }
    body["to"] = to.map{|t| t.is_a?(String) ? t : t.id }
    request = @@request.merge({ :body => body.to_json })
    if replace
      result = self.class.put("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{collection}", request)
    else
      result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/edge", request)
    end
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @edgeDefinitions = result["graph"]["edgeDefinitions"]
        @orphanCollections = result["graph"]["orphanCollections"]
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @edgeDefinitions = result["graph"]["edgeDefinitions"]
      @orphanCollections = result["graph"]["orphanCollections"]
      self
    end
  end

  def replaceEdgeCollection(collection:, from:, to:)  # TESTED
    self.addEdgeCollection(collection: collection, from: from, to: to, replace: true)
  end

  def removeEdgeCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{collection}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @edgeDefinitions = result["graph"]["edgeDefinitions"]
        @orphanCollections = result["graph"]["orphanCollections"]
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @edgeDefinitions = result["graph"]["edgeDefinitions"]
      @orphanCollections = result["graph"]["orphanCollections"]
      self
    end
  end
end
