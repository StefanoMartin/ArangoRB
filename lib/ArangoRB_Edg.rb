# === GRAPH EDGE ===

class ArangoEdge < ArangoDocument
  def initialize(key: nil, collection: @@collection, graph: @@graph, database: @@database, body: {}, from: nil, to: nil) # TESTED
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoCollection)
      @collection = collection.collection
    else
      raise "collection should be a String or an ArangoCollection instance, not a #{collection.class}"
    end

    if graph.is_a?(String)
      @graph = graph
    elsif graph.is_a?(ArangoGraph)
      @graph = graph.graph
    else
      raise "graph should be a String or an ArangoGraph instance, not a #{graph.class}"
    end

    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end

    if key.is_a?(String) || key.nil?
      @key = key
      unless key.nil?
        body["_key"] = @key
        @id = "#{@collection}/#{@key}"
      end
    else
      raise "key should be a String, not a #{key.class}"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash, not a #{body.class}"
    end

    if from.is_a?(String)
      @body["_from"] = from
    elsif from.is_a?(ArangoDocument)
      @body["_from"] = from.id
    elsif from.nil?
    else
      raise "from should be a String or an ArangoDocument instance, not a #{from.class}"
    end

    if to.is_a?(String)
      @body["_to"] = to
    elsif to.is_a?(ArangoDocument)
      @body["_to"] = to.id
    elsif to.nil?
    else
      raise "to should be a String or an ArangoDocument instance, not a #{to.class}"
    end
  end

  attr_reader :key, :id, :body

  # === RETRIEVE ===

  def graph
    ArangoGraph.new(graph: @graph, database: @database)
  end

  # === GET ===

  def retrieve # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose
      @body = result["edge"] unless result["error"]
      result
    else
      return result["errorMessage"] if result["error"]
      @body = result["edge"]
      self
    end
  end

# === POST ====

  def create(body: {}, from: @body["_from"], to: @body["_to"], waitForSync: nil) # TESTED
    query = {"waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
    body["_key"] = @key if body["_key"].nil? && !@key.nil?
    body["_from"] = from.is_a?(String) ? from : from.id
    body["_to"] = to.is_a?(String) ? to : to.id
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@collection}", request)
    return_result result: result, body: body
  end
  alias create_document create
  alias create_vertex create

# === MODIFY ===

  def replace(body: {}, waitForSync: nil) # TESTED
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.put("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", request)
    return_result result: result, body: body
  end

  def update(body: {}, waitForSync: nil, keepNull: nil) # TESTED
    query = {"waitForSync" => waitForSync, "keepNull" => keepNull}.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.patch("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @key = result["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @key = result["edge"]["_key"]
      @id = "#{@collection}/#{@key}"
      @body = @body.merge(body)
      @body = @body.merge(result["edge"])
      self
    end
  end

# === DELETE ===

  def destroy(body: nil, waitForSync: nil) # TESTED
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", request)
    return_result result: result, caseTrue: true
  end

# === UTILITY ===

  def return_result(result:, body: {}, caseTrue: false)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @key = result["edge"]["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
      end
      result
    else
      return result["errorMessage"] if result["error"]
      return true if caseTrue
      @key = result["edge"]["_key"]
      @id = "#{@collection}/#{@key}"
      @body = body
      self
    end
  end
end
