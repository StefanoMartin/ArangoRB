# ==== GRAPH ====

class ArangoGraph < ArangoServer
  def initialize(graph: @@graph, database: @@database, edgeDefinitions: [], orphanCollections: [])  # TESTED
    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String, not a #{collection.class}"
    end

    if graph.is_a?(String)
      @graph = graph
    else
      raise "graph should be a String, not a #{graph.class}"
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
  end

  attr_reader :graph, :edgeDefinitions, :orphanCollections, :database

# === GET ===

  def retrieve  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @edgeDefinitions = result["graph"]["edgeDefinitions"]
          @orphanCollections = result["graph"]["orphanCollections"]
          self
        end
      end
    end
  end

# === POST ===

  def create  # TESTED
    body = { "name" => @graph, "edgeDefinitions" => @edgeDefinitions, "orphanCollections" => @orphanCollections }
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/gharial", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : self
    end
  end

# === DELETE ===

  def destroy  # TESTED
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : true
    end
  end

# === VERTEX COLLECTION  ===

  def vertexCollections  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/vertex", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoCollection.new(collection: x)}
    end
  end

  def addVertexCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    body = { "collection" => collection }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/vertex", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @orphanCollections << collection
          self
        end
      end
    end
  end

  def removeVertexCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{collection}", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @orphanCollections -= [collection]
          self
        end
      end
    end
  end

# === EDGE COLLECTION ===

  def edgeCollections  # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/edge", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoCollection.new(collection: x)}
    end
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

    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result["error"]
          @edgeDefinitions = result["graph"]["edgeDefinitions"]
          @orphanCollections = result["graph"]["orphanCollections"]
        end
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @edgeDefinitions = result["graph"]["edgeDefinitions"]
          @orphanCollections = result["graph"]["orphanCollections"]
          self
        end
      end
    end
  end

  def replaceEdgeCollection(collection:, from:, to:)  # TESTED
    self.addEdgeCollection(collection: collection, from: from, to: to, replace: true)
  end

  def removeEdgeCollection(collection:)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{collection}", @@request)

    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        unless result["error"]
          @edgeDefinitions = result["graph"]["edgeDefinitions"]
          @orphanCollections = result["graph"]["orphanCollections"]
        end
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          @edgeDefinitions = result["graph"]["edgeDefinitions"]
          @orphanCollections = result["graph"]["orphanCollections"]
          self
        end
      end
    end
  end
end
