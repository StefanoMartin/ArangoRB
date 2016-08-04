# === INDEXES ===

class ArangoI < ArangoS
  def initialize(collection: @@collection, database: @@database, body: {}, id: nil, type: nil, unique: nil, fields:, sparse: nil)
    if collection.is_a?(String)
      @collection = collection
    else
      raise "collection should be a String, not a #{collection.class}"
    end

    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String, not a #{database.class}"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash, not a #{body.class}"
    end

    @key = id.split("/")[1]
    @id = id
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

  attr_reader :database, :collection, :body, :type, :id, :unique, :fields, :key, :sparse

  def retrieve
    result = self.class.get("/_db/#{@database}/_api/index/#{@id}", @@request)
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
          result.delete("error")
          result.delete("code")
          @body = result
          @type = result["type"]
          @unique = result["unique"]
          @fields = result["fields"]
          @sparse = result["sparse"]
          self
        end
      end
    end
  end

  def self.indexes
    query = { "collection": @collection }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/index", request)
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
          result.delete("error")
          result.delete("code")
          result["indexes"] = result["indexes"].map{|x| ArangoI.new(body: x, id: x["id"], database: @database, collection: @collection, type: x["type"], unique: x["unique"], fields: x["fields"], sparse: x["sparse"])}
          result
        end
      end
    end
  end

  def create
    body = @body.merge({
      "fields" => @fields,
      "unique" => @unique,
      "type" => @type,
    }.delete_if{|k,v| v.nil?})
    query = { "collection": @collection }
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/index", request)
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
          result.delete("error")
          result.delete("code")
          @id = result["id"]
          @key = @id.split("/")[1]
          self
        end
      end
    end
  end

  def delete
    result = self.class.delete("/_db/#{@database}/_api/index/#{@collection}/#{id}", @@request)
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
          true
        end
      end
    end
  end
end
