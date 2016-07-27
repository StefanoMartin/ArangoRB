# ==== GRAPH ====

class ArangoG < ArangoS
  def initialize(graph: @@graph, database: @@database, edgeDefinitions: [], orphanCollections: [])
    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String, not a #{collection.class}"
    end

    if graph.is_a?(String)
      @graph = graph
      ArangoS.graph = graph
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

  def retrieve
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}").parsed_response
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

# === POST ===

  def create
    body = { "name" => @graph, "edgeDefinitions" => @edgeDefinitions, "orphanCollections" => @orphanCollections }
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/gharial", new_Document).parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : self
  end

# === DELETE ===

  def destroy
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["removed"]
  end

# === VERTEX COLLECTION  ===

  def vertexCollections
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/vertex").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoC.new(collection: x)}
  end

  def addVertexCollection(collection:)
    collection = collection.is_a?(String) ? collection : collection.collection
    body = { "collection" => collection }
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/vertex", new_Document).parsed_response
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

  def removeVertexCollection(collection:)
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{collection}")
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

# === EDGE COLLECTION ===

  def edgeCollections
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/edge").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["collections"].map{|x| ArangoC.new(collection: x)}
  end

  def addEdgeCollection(collection:, from:, to:, replace: false)
    from = from.is_a?(String) ? [from] : from.is_a?(ArangoC) ? [from.collection] : from
    to = to.is_a?(String) ? [to] : to.is_a?(ArangoC) ? [to.collection] : to
    body = {}
    collection = collection.is_a?(String) ? collection : collection.collection
    body["collection"] = collection
    body["from"] = from.map{|f| f.is_a?(String) ? f : f.id }
    body["to"] = to.map{|t| t.is_a?(String) ? t : t.id }
    new_Document = { :body => body.to_json }

    if replace
      result = self.class.put("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{collection}", new_Document).parsed_response
    else
      result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/edge", new_Document).parsed_response
    end

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

  def replaceEdgeCollection(collection:, from:, to:)
    self.addEdgeCollection(collection: collection, from: from, to: to, replace: true)
  end

  def removeEdgeCollection(collection:)
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{collection}")
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
