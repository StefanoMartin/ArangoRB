# === INDEXES ===

class ArangoIndex < ArangoServer
  def initialize(collection: @@collection, database: @@database, body: {}, id: nil, type: nil, unique: nil, fields:, sparse: nil) # TESTED
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoCollection)
      @collection = collection.collection
    else
      raise "collection should be a String or a ArangoCollection instance, not a #{collection.class}"
    end

    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or a ArangoDatabase instance, not a #{database.class}"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash, not a #{body.class}"
    end

    unless id.nil?
      @key = id.split("/")[1]
      @id = id
    end
    @type = type
    @sparse = sparse
    @unique = unique unless unique.nil?

    if fields.is_a?(String)
      @fields = [fields]
    elsif fields.is_a?(Array)
      @fields = fields
    else
      raise "fields should be a String or an Array, not a #{database.class}"
    end
  end

  attr_reader :body, :type, :id, :unique, :fields, :key, :sparse

  ### RETRIEVE ###

  def database
    ArangoDatabase.new(database: @database)
  end

  def collection
    ArangoCollection.new(collection: @collection, database: @database)
  end

  def retrieve # TESTED
    result = self.class.get("/_db/#{@database}/_api/index/#{@id}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    return result if @@verbose
    return result["errorMessage"] if result["error"]
    result.delete_if{|k,v| k == "error" || k == "code"}
    @body = result
    @type = result["type"]
    @unique = result["unique"]
    @fields = result["fields"]
    @sparse = result["sparse"]
    self
  end

  def self.indexes(database: @@database, collection: @@collection) # TESTED
    database = database.database if database.is_a?(ArangoDatabase)
    collection = collection.collection if collection.is_a?(ArangoCollection)
    query = { "collection": collection }
    request = @@request.merge({ :query => query })
    result = get("/_db/#{database}/_api/index", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    return result if @@verbose
    return result["errorMessage"] if result["error"]
    result.delete_if{|k,v| k == "error" || k == "code"}
    result["indexes"] = result["indexes"].map{|x| ArangoIndex.new(body: x, id: x["id"], database: database, collection: collection, type: x["type"], unique: x["unique"], fields: x["fields"], sparse: x["sparse"])}
    result
  end

  def create # TESTED
    body = @body.merge({
      "fields" => @fields,
      "unique" => @unique,
      "type" => @type,
      "id" => @id
    }.delete_if{|k,v| v.nil?})
    query = { "collection": @collection }
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/index", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    return result if @@verbose
    return result["errorMessage"] if result["error"]
    result.delete_if{|k,v| k == "error" || k == "code"}
    @body = result
    @id = result["id"]
    @key = @id.split("/")[1]
    self
  end

  def destroy # TESTED
    result = self.class.delete("/_db/#{@database}/_api/index/#{id}", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end
end
