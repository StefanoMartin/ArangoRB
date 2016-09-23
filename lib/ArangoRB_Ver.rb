# === GRAPH VERTEX ===

# ==== DOCUMENT ====

class ArangoVertex < ArangoDocument
  def initialize(key: nil, collection: @@collection, graph: @@graph, database: @@database,  body: {}) # TESTED
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
    else
      raise "database should be a String, not a #{database.class}"
    end

    if key.is_a?(String) || key.nil?
      @key = key
      unless key.nil?
        body["_key"] = @key
        @id = "#{@collection}/#{@key}"
      end
    elsif key.is_a?(ArangoDocument)
      @key = key.key
      @id = key.id
    else
      raise "key should be a String, not a #{key.class}"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash, not a #{body.class}"
    end
    @idCache = "VER_#{@id}"
  end

  attr_reader :key, :id, :body, :idCache

  # === RETRIEVE ===

  def graph
    ArangoGraph.new(graph: @graph, database: @database)
  end

  # === GET ===

  def retrieve # TESTED
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{@id}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      @body = result["vertex"] unless result["error"]
      result
    else
      return result["errorMessage"] if result["error"]
      @body = result["vertex"]
      self
    end
  end

# === POST ====

  def create(body: @body, waitForSync: nil) # TESTED
    query = {"waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
    body["_key"] = @key if body["_key"].nil? && !@key.nil?
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{@collection}", request)
    return_result result: result, body: body
  end
  alias create_vertex create

# === MODIFY ===

  def replace(body: {}, waitForSync: nil) # TESTED
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.put("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{@id}", request)
    return_result result: result, body: body
  end

  def update(body: {}, waitForSync: nil, keepNull: nil) # TESTED
    query = {"waitForSync" => waitForSync, "keepNull" => keepNull}.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.patch("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{@id}", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @key = result["_key"]
        @id = "#{@collection}/#{@key}"
        @body = result["vertex"].body
      end
      result
    else
      return result["errorMessage"] if result["error"]
      @key = result["vertex"]["_key"]
      @id = "#{@collection}/#{@key}"
      @body = @body.merge(body)
      @body = @body.merge(result["vertex"])
      self
    end
  end

# === DELETE ===

  def destroy(waitForSync: nil) # TESTED
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/vertex/#{@id}", request)
    return_result result: result, caseTrue: true
  end

# === UTILITY ===

  def return_result(result:, body: {}, caseTrue: false)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose
      unless result["error"]
        @key = result["vertex"]["_key"]
        @id = "#{@collection}/#{@key}"
        @body = result["vertex"].merge(body)
      end
      result
    else
      return result["errorMessage"] if result["error"]
      return true if caseTrue
      @key = result["vertex"]["_key"]
      @id = "#{@collection}/#{@key}"
      @body = result["vertex"].merge(body)
      self
    end
  end
end
