# ==== DOCUMENT ====

class ArangoDoc < ArangoS
  def initialize(key: nil, collection:, database: @@database, body: {})
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoC)
      @collection = collection.collection
    else
      raise "Collection should be a String or an ArangoC instance."
    end

    if database.is_a?(String)
      @database = database
    else
      raise "Database should be a String"
    end

    if key.is_a?(String) || key.nil?
      @key = key
      @id = "#{@collection}/#{@key}" unless key.nil?
    else
      raise "Key should be a String"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "Body should be a String"
    end
  end

  attr_reader :key, :id, :body

  # === GET ===

  def retrieve
    result = self.class.get("/_db/#{@database}/_api/document/#{@id}").parsed_response
    if @@verbose
      @body = result unless result["error"]
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        @body = result
        self
      end
    end
  end

  def retrieve_edges(collection: , direction: nil)
    query = {"vertex" => @id, "direction" => direction }.delete_if{|k,v| v.nil?}
    new_Document = { :query => query }
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.get("/_db/#{@database}/_api/edges/#{collection}", new_Document).parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["edges"].map{|edge|
      ArangoDoc.new(key: edge["_key"], collection: collection, database: @database, body: edge)
    }
  end

  def in(collection)
    self.retrieve_edges collection: collection, direction: "in"
  end

  def out(collection)
    self.retrieve_edges collection: collection, direction: "out"
  end

  def from
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_from"]}").parsed_response
    collection = result["_id"].split("/")[0]
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDoc.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  def to
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_to"]}").parsed_response
    collection = result["_id"].split("/")[0]
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDoc.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  # def header
  #   result = self.class.head("/_db/#{@database}/_api/document/#{@id}", follow_redirects: true, maintain_method_across_redirects: true)
  #   @@verbose ? result : result["error"] ? result["errorMessage"] : result
  # end

# === POST ====

  def create(body: {}, waitForSync: nil, returnNew: nil)
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}.delete_if{|k,v| v.nil?}
    unless body.is_a? Array
      body["_key"] = @key if body["_key"].nil? && !@key.nil?
      new_Document = { :body => body.to_json, :query => query }
      result = self.class.post("/_db/#{@database}/_api/document/#{@collection}", new_Document).parsed_response
      self.return_result(result, body)
    else
      new_Document = { :body => body.to_json, :query => query }
      result = self.class.post("/_db/#{@database}/_api/document/#{@collection}", new_Document).parsed_response
      i = -1
      return @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDoc.new(key: x["_key"], collection: @collection, database: @database, body: body[i+=1])}
    end
  end
  alias create_document create
  alias create_vertex create

  def create_edge(body: {}, from:, to:)
    edges = []
    from = [from] unless from.is_a? Array
    to = [to] unless to.is_a? Array
    from.each do |f|
      body["_from"] = f.is_a?(String) ? f : f.id
      to.each do |t|
        body["_to"] = t.is_a?(String) ? t : t.id
        edges << body
      end
    end
    edges = edges[0] if edges.length == 1
    self.create(body: edges)
  end

# === MODIFY ===

  def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil)
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json, :query => query }

    unless body.is_a? Array
      result = self.class.put("/_db/#{@database}/_api/document/#{@id}", new_Document).parsed_response
      self.return_result(result, body)
    else
      result = self.class.put("/_db/#{@database}/_api/document/#{@collection}", new_Document).parsed_response
      i = -1
      return @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDoc.new(key: x["_key"], collection: @collection, database: @database, body: body[i+=1])}
    end
  end

  def update(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil, keepNull: nil, mergeObjects: nil)
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs,
      "keepNull" => keepNull,
      "mergeObjects" => mergeObjects
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json, :query => query }

    unless body.is_a? Array
      result = self.class.patch("/_db/#{@database}/_api/document/#{@id}", new_Document).parsed_response
      self.return_result(result, body)
    else
      result = self.class.patch("/_db/#{@database}/_api/document/#{@collection}", new_Document).parsed_response
      i = -1
      return @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDoc.new(key: x["_key"], collection: @collection, database: @database, body: body[i+=1])}
    end
  end

# === DELETE ===

  def destroy(body: nil, waitForSync: nil, ignoreRevs: nil, returnOld: nil)
    query = {
      "waitForSync" => waitForSync,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }.delete_if{|k,v| v.nil?}
    new_Document = { :query => query }

    unless body.is_a? Array
      result = self.class.delete("/_db/#{@database}/_api/document/#{@id}", new_Document).parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : result
    else
      new_Document = { :body => body.to_json, :query => query }
      result = self.class.delete("/_db/#{@database}/_api/document/#{@collection}", new_Document).parsed_response
      return result
    end
  end

# === UTILITY ===

  def return_result(result, body)
    if @@verbose
      unless result["error"]
        @key = result["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
      end
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        @key = result["_key"]
        @id = "#{@collection}/#{@key}"
        @body = body
        self
      end
    end
  end
end
