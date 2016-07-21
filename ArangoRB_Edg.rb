# === GRAPH EDGE ===

# ==== DOCUMENT ====

class ArangoE < ArangoDoc
  def initialize(key: nil, collection: @@collection, graph: @@graph, database: @@database, body: {})
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoC)
      @collection = collection.collection
    else
      raise "collection should be a String or an ArangoC instance."
    end

    if graph.is_a?(String)
      @graph = graph
    elsif graph.is_a?(ArangoG)
      @graph = graph.graph
    else
      raise "graph should be a String or an ArangoG instance."
    end

    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String"
    end

    if key.is_a?(String) || key.nil?
      @key = key
      @id = "#{@collection}/#{@key}" unless key.nil?
    else
      raise "key should be a String"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash"
    end
  end

  attr_reader :key, :id, :body, :database, :graph, :collection

  # === GET ===

  def retrieve #DONE
    result = self.class.get("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}").parsed_response
    if @@verbose
      @body = result["edge"] unless result["error"]
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        @body = result["edge"]
        self
      end
    end
  end

# === POST ====

  def create(body: {}, from:, to:, waitForSync: nil) #DONE
    query = {"waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
    body["_key"] = @key if body["_key"].nil? && !@key.nil?
    body["_from"] = from.is_a?(String) ? from : from.id
    body["_to"] = to.is_a?(String) ? to : to.id
    new_Document = { :body => body.to_json, :query => query }
    result = self.class.post("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@collection}", new_Document).parsed_response
    self.return_result(result, body)
  end
  alias create_document create
  alias create_vertex create

# === MODIFY ===

  def replace(body: {}, waitForSync: nil)
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json, :query => query }
    result = self.class.put("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", new_Document).parsed_response
    self.return_result(result, body)
  end

  def update(body: {}, waitForSync: nil, keepNull: nil) #DONE
    query = {"waitForSync" => waitForSync, "keepNull" => keepNull}.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json, :query => query }
    result = self.class.patch("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}", new_Document).parsed_response
    self.return_result(result, body)
  end

# === DELETE ===

  def destroy(body: nil, waitForSync: nil) #OONE
    query = { "waitForSync" => waitForSync }.delete_if{|k,v| v.nil?}
    new_Document = { :query => query }
    result = self.class.delete("/_db/#{@database}/_api/gharial/#{@graph}/edge/#{@id}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["removed"]
  end

# === UTILITY ===

  def return_result(result, body)
    if @@verbose
      unless result["error"]
        @key = result["edge"]["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
      end
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        @key = result["edge"]["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
        self
      end
    end
  end
end
