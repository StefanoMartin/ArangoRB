# ==== GRAPH ====

class ArangoGraph < ArangoServer
  def initialize(graph: @@graph, database: @@database, edgeDefinitions: [], orphanCollections: [])  # TESTED
    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end

    if graph.is_a?(String)
      @graph = graph
    elsif database.is_a?(ArangoGraph)
      @graph = graph.graph
    else
      raise "graph should be a String or an ArangoGraph instance, not a #{graph.class}"
    end

    if edgeDefinitions.is_a?(Array)
      @edgeDefinitions = edgeDefinitions
    else
      raise "edgeDefinitions should be an Array, not a #{edgeDefinitions.class}"
    end

    if orphanCollections.is_a?(Array)
      @orphanCollections = orphanCollections
    else
      raise "orphanCollections should be an Array, not a #{orphanCollections.class}"
    end

    @idCache = "GRA_#{@graph}"
  end

  attr_reader :graph, :edgeDefinitions, :orphanCollections, :database, :idCache
  alias name graph

# === RETRIEVE ===

  def database
    ArangoDatabase.new(database: @database)
  end

# === GET ===

  def retrieve  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    return result if @@verbose
    return result["errorMessage"] if result["error"]
    @edgeDefinitions = result["graph"]["edgeDefinitions"]
    @orphanCollections = result["graph"]["orphanCollections"]
    self
  end

# === POST ===

  def create  # TESTED
    body = { "name" => @graph, "edgeDefinitions" => @edgeDefinitions, "orphanCollections" => @orphanCollections }
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/gharial", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : self
  end

# === DELETE ===

  def destroy  # TESTED
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

# === VERTEX COLLECTION  ===

  def vertexCollections  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/vertex", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoCollection.new(collection: x)}
  end

  def addVertexCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    body = { "collection" => collection }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/vertex", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      @orphanCollections << collection unless result["error"]
      result
    else
      return result["errorMessage"] if result["error"]
      @orphanCollections << collection
      self
    end
  end

  def removeVertexCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{collection}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      @orphanCollections -= [collection] unless result["error"]
      result
    else
      return result["errorMessage"] if result["error"]
      @orphanCollections -= [collection]
      self
    end
  end

# === EDGE COLLECTION ===

  def edgeCollections  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/edge", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoCollection.new(collection: x)}
  end

  def addEdgeCollection(collection:, from:, to:, replace: false)  # TESTED
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
