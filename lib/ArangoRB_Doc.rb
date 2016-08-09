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

  attr_reader :key, :id, :body, :collection, :database

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
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["edges"].map{|edge|
      ArangoDocument.new(key: edge["_key"], collection: collection, database: @database, body: edge)
    }
  end

  def in(collection)  # TESTED
    self.retrieve_edges collection: collection, direction: "in"
  end

  def out(collection)  # TESTED
    self.retrieve_edges collection: collection, direction: "out"
  end

  def any(collection)  # TESTED
    self.retrieve_edges collection: collection
  end

  def from  # TESTED
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_from"]}", @@request)
    collection = result["_id"].split("/")[0]
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  def to  # TESTED
    result = self.class.get("/_db/#{@database}/_api/document/#{self.body["_to"]}", @@request)
    collection = result["_id"].split("/")[0]
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["_key"], collection: collection, database: @database, body: result)
  end

  # def header
  #   result = self.class.head("/_db/#{@database}/_api/document/#{@id}", follow_redirects: true, maintain_method_across_redirects: true)
  #   @@verbose ? result : result["error"] ? result["errorMessage"] : result
  # end

# === POST ====

  def create(body: @body, waitForSync: nil, returnNew: nil, database: @database, collection: @collection)  # TESTED
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}.delete_if{|k,v| v.nil?}
    unless body.is_a? Array
      body["_key"] = @key if body["_key"].nil? && !@key.nil?
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = self.class.post("/_db/#{database}/_api/document/#{collection}", request)
      return_result result: result, body: body
    else
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = self.class.post("/_db/#{database}/_api/document/#{collection}", request)
      i = -1
      return result.headers["x-arango-async-id"] if @@async == "store"
      result = result.parsed_response
      @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDocument.new(key: x["_key"], collection: collection, database: database, body: body[i+=1])}
    end
  end
  alias create_document create
  alias create_vertex create

  def self.create(body: {}, waitForSync: nil, returnNew: nil, database: @@database, collection: @@collection)  # TESTED
    collection = collection.is_a?(String) ? collection : collection.collection
    database = database.is_a?(String) ? database : database.database
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}.delete_if{|k,v| v.nil?}
    unless body.is_a? Array
      body["_key"] = @key if body["_key"].nil? && !@key.nil?
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = post("/_db/#{database}/_api/document/#{collection}", request)
      ArangoDocument.new.return_result result: result, body: body, newo: true
    else
      request = @@request.merge({ :body => body.to_json, :query => query })
      result = post("/_db/#{database}/_api/document/#{collection}", request)
      i = -1
      return result.headers["x-arango-async-id"] if @@async == "store"
      result = result.parsed_response
      @@verbose ? result : !result.is_a?(Array) ? result["errorMessage"] : result.map{|x| ArangoDocument.new(key: x["_key"], collection: collection, database: database, body: body[i+=1])}
    end
  end

  def create_edge(body: [{}], from:, to:, waitForSync: nil, returnNew: nil, database: @database, collection: @collection)  # TESTED
    edges = []
    from = [from] unless from.is_a? Array
    to = [to] unless to.is_a? Array
    body = [body] unless body.is_a? Array
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
    create(body: edges, waitForSync: waitForSync, returnNew: returnNew, database: database, collection: collection)
  end

  def self.create_edge(body: {}, from:, to:, waitForSync: nil, returnNew: nil, database: @@database, collection: @@collection)  # TESTED
    edges = []
    from = [from] unless from.is_a? Array
    to = [to] unless to.is_a? Array
    body = [body] unless body.is_a? Array
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
    self.create(body: edges, waitForSync: waitForSync, returnNew: returnNew, database: database, collection: collection)
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
      result = result.parsed_response
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
          @body = @body.merge(body)
          self
        end
      end
    else
      result = self.class.patch("/_db/#{@database}/_api/document/#{@collection}", request)
      i = -1
      return result.headers["x-arango-async-id"] if @@async == "store"
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

  def return_result(result:, body: {}, caseTrue: false, key: nil, newo: false)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose || !result.is_a?(Hash)
        resultTemp = result
        unless result["errorMessage"]
          result.delete("error")
          result.delete("code")
          @key = result["_key"]
          @collection = result["_id"].split("/")[0]
          @body = result.merge(body)
        end
        resultTemp
      else
        if result["error"]
          result["errorMessage"]
        else
          if newo
            ArangoDocument.new key: result["_key"], collection: result["_id"].split("/")[0], body: body
          else
            return true if caseTrue
            result.delete("error")
            result.delete("code")
            @key = result["_key"]
            @collection = result["_id"].split("/")[0]
            @body = result.merge(body)
            if key.nil?
              self
            else
              result[key]
            end
          end
        end
      end
    end
  end
end
