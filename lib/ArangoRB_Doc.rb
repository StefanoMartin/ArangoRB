# ==== DOCUMENT ====

class ArangoDocument < ArangoServer
  def initialize(key: nil, collection: @@collection, database: @@database, body: {}, from: nil, to: nil) # TESTED
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoCollection)
      @collection = collection.collection
    else
      raise "collection should be a String or an ArangoCollection instance, not a #{collection.class}"
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

    @idCache = "DOC_#{@id}"
  end

  attr_reader :key, :id, :body, :idCache
  alias name key

  # === RETRIEVE ===

  def collection
    ArangoCollection.new(collection: @collection, database: @database)
  end

  def database
    ArangoDatabase.new(database: @database)
  end

  # === GET ===

  def retrieve  # TESTED
    result = self.class.get("/_db/#{@database}/_api/document/#{@id}", @@request)
    self.return_result result: result
  end

  def retrieve_edges(collection: , direction: nil)  # TESTED
    query = {"vertex" => @id, "direction" => direction }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    collection = collection.is_a?(String) ? collection : collection.collection
    result = self.class.get("/_db/#{@database}/_api/edges/#{collection}", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["edges"].map{|edge| ArangoDocument.new(key: edge["_key"], collection: collection, database: @database, body: edge)}
  end

  def in(edgeCollection)  # TESTED
    self.retrieve_edges collection: edgeCollection, direction: "in"
  end

  def out(edgeCollection)  # TESTED
    self.retrieve_edges collection: edgeCollection, direction: "out"
  end

  def any(edgeCollection)  # TESTED
    self.retrieve_edges collection: edgeCollection
  end

  def from  # TESTED
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_from"]}", @@request)
    collection = result["_id"].split("/")[0]
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  def to  # TESTED
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_to"]}", @@request)
    collection = result["_id"].split("/")[0]
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  # def header
  #   result = self.class.head("/_db/#{@database}/_api/document/#{@id}", follow_redirects: true, maintain_method_across_redirects: true)
  #   @@verbose ? result : result["error"] ? result["errorMessage"] : result
  # end

# === POST ====

  def create(body: {}, waitForSync: nil, returnNew: nil)  # TESTED
    body = @body.merge(body)
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}.delete_if{|k,v| v.nil?}
    body["_key"] = @key if body["_key"].nil? && !key.nil?
    request = @@request.merge({ :body => @body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/document/#{@collection}", request)
    return_result result: result, body: @body
  end
  alias create_document create
  alias create_vertex create

  def self.create(body: {}, waitForSync: nil, returnNew: nil, database: @@database, collection: @@collection)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    database = database.is_a?(String) ? database : database.database
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}.delete_if{|k,v| v.nil?}
    unless body.is_a? Array
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = post("/_db/#{database}/_api/document/#{collection}", request)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["_key"], collection: result["_id"].split("/")[0], body: body)
    else
      body = body.map{|x| x.is_a?(Hash) ? x : x.is_a?(ArangoDocument) ? x.body : nil}
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = post("/_db/#{database}/_api/document/#{collection}", request)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      i = -1
      @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDocument.new(key: x["_key"], collection: collection, database: database, body: body[i+=1])}
    end
  end

  def create_edge(body: {}, from:, to:, waitForSync: nil, returnNew: nil, database: @database, collection: @collection)  # TESTED
    body = @body.merge(body)
    edges = []
    from = [from] unless from.is_a? Array
    to = [to] unless to.is_a? Array
    from.each do |f|
      body["_from"] = f.is_a?(String) ? f : f.id
      to.each do |t|
        body["_to"] = t.is_a?(String) ? t : t.id
        edges << body.clone
      end
    end
    edges = edges[0]
    ArangoDocument.create(body: edges, waitForSync: waitForSync, returnNew: returnNew, database: database, collection: collection)
  end

  def self.create_edge(body: {}, from:, to:, waitForSync: nil, returnNew: nil, database: @@database, collection: @@collection)  # TESTED
    edges = []
    from = [from] unless from.is_a? Array
    to = [to] unless to.is_a? Array
    body = [body] unless body.is_a? Array
    body = body.map{|x| x.is_a?(Hash) ? x : x.is_a?(ArangoDocument) ? x.body : nil}
    body.each do |b|
      from.each do |f|
        b["_from"] = f.is_a?(String) ? f : f.id
        to.each do |t|
          b["_to"] = t.is_a?(String) ? t : t.id
          edges << b.clone
        end
      end
    end
    edges = edges[0] if edges.length == 1
    ArangoDocument.create(body: edges, waitForSync: waitForSync, returnNew: returnNew, database: database, collection: collection)
  end

# === MODIFY ===

  def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil) # TESTED
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })

    unless body.is_a? Array
      result = self.class.put("/_db/#{@database}/_api/document/#{@id}", request)
      self.return_result result: result, body: body
    else
      result = self.class.put("/_db/#{@database}/_api/document/#{@collection}", request)
      i = -1
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, database: @database, body: body[i+=1])}
    end
  end

  def update(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil, keepNull: nil, mergeObjects: nil)  # TESTED
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs,
      "keepNull" => keepNull,
      "mergeObjects" => mergeObjects
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })

    unless body.is_a? Array
      result = self.class.patch("/_db/#{@database}/_api/document/#{@id}", request)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
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
        @key = result["_key"]
        @id = "#{@collection}/#{@key}"
        @body = @body.merge(body)
        return self
      end
    else
      result = self.class.patch("/_db/#{@database}/_api/document/#{@collection}", request)
      i = -1
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, database: @database, body: body[i+=1])}
    end
  end

# === DELETE ===

  def destroy(body: nil, waitForSync: nil, ignoreRevs: nil, returnOld: nil)  # TESTED
    query = {
      "waitForSync" => waitForSync,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })

    unless body.is_a? Array
      result = self.class.delete("/_db/#{@database}/_api/document/#{@id}", request)
      return_result result: result, caseTrue: true
    else
      result = self.class.delete("/_db/#{@database}/_api/document/#{@collection}", request)
      return_result result: result, caseTrue: true
    end
  end

# === UTILITY ===

  def return_result(result:, body: {}, caseTrue: false, key: nil)
    return  result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose || !result.is_a?(Hash)
      resultTemp = result
      unless result["errorMessage"]
        result.delete_if{|k,v| k == "error" || k == "code"}
        @key = result["_key"]
        @collection = result["_id"].split("/")[0]
        @body = result.merge(body)
      end
      return resultTemp
    else
      return result["errorMessage"] if result["error"]
      return true if caseTrue
      result.delete_if{|k,v| k == "error" || k == "code"}
      @key = result["_key"]
      @collection = result["_id"].split("/")[0]
      @id = "#{@collection}/#{@key}"
      @body = result.merge(body)
      key.nil? ? self : result[key]
    end
  end
end
