  # === INDEXES ===

module Arango
  class Index
    def initialize(collection:, body: {}, id: nil, type: "hash", unique: nil, fields:, sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil)
      satisfy_class?(collection, [Arango::Collection])
      satisfy_category?(type, "type", ["hash", "skiplist", "persistent", "geo", "fulltext"])
      @collection = collection
      @database = collection.database
      @client = collection.client
      body["type"] ||= type
      body["id"] ||= id
      body["sparse"] ||= sparse
      body["unique"] ||= unique
      body["fields"] ||= fields.is_a?(String) ? [fields] : fields
      body["deduplicate"] ||= deduplicate
      body["geoJson"]     ||= geoJson
      body["minLength"]   ||= minLength

      assign_attributes(body)
    end

    attr_accessor :id, :unique, :fields, :key, :sparse, :geoJson, :minLenght, :deduplicate
    attr_reader :type, :database, :collection, :client

    def type=(type)
      satisfy_category?(type, "type", ["hash", "skiplist", "persistent", "geo", "fulltext"])
      @type = type
    end

    def collection=(collection)
      satisfy_class?(collection, [Arango::Collection])
      @collection = collection
      @database = collection.database
      @client = collection.client
    end

    ### RETRIEVE ###

    def to_h
      {
        "key" => @key,
        "id" => @id,
        "collection" => @collection,
        "database" => @database,
        "body" => @body,
        "type" => @type,
        "sparse" => @sparse,
        "unique" => @unique,
        "fields" => @fields,
        "idCache" => @idCache,
        "geoJson" => @geoJson,
        "minLength" => @minLength,
        "deduplicate" => @deduplicate
      }.delete_if{|k,v| v.nil?}
    end

# == PRIVATE ==

    def assign_attributes(result)
      @body        = result
      @id          = result["id"]
      @key         = @id.split("/")[1]
      @type        = result["type"]
      @unique      = result["unique"]
      @fields      = result["fields"]
      @sparse      = result["sparse"]
      @geoJson     = result["geoJson"]
      @minLength   = result["minLength"]
      @deduplicate = result["deduplicate"]
    end

# === COMMANDS ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/index/#{@id}")
      return result.headers["x-arango-async-id"] if @@async == "store"
      return_element(result)
    end

    def create
      body = {
        "fields" => @fields,
        "unique" => @unique,
        "type" => @type,
        "id" => @id,
        "geoJson" => @geoJson,
        "minLength" => @minLength,
        "deduplicate" => @deduplicate
      }
      query = { "collection": @collection.name }
      result = @database.request(action: "POST", url: "_api/index",
        body: body, query: query)
      return_element(result)
    end

    def destroy
      @database.request(action: "DELETE", url: "/_api/index/#{id}")
    end
  end
end
