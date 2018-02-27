  # === INDEXES ===

module Arango
  class Index
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Collection_Return
    
    def initialize(collection:, body: {}, id: nil, type: "hash", unique: nil, fields:, sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil)
      assign_collection(collection)
      satisfy_category?(type, "type", ["hash", "skiplist", "persistent",
        "geo", "fulltext"])
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

# === DEFINE ===

    attr_accessor :id, :unique, :fields, :key, :sparse, :geoJson, :minLenght,
      :deduplicate
    attr_reader :type, :database, :collection, :client

    def type=(type)
      satisfy_category?(type, "type", ["hash", "skiplist", "persistent", "geo", "fulltext"])
      @type = type
    end

    def body=(result)
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
    alias assign_attributes body=

# === DEFINE ===

    def to_h(level=0)
      hash = {
        "key"    => @key,
        "id"     => @id,
        "body"   => @body,
        "type"   => @type,
        "sparse" => @sparse,
        "unique" => @unique,
        "fields" => @fields,
        "idCache" => @idCache,
        "geoJson" => @geoJson,
        "minLength"   => @minLength,
        "deduplicate" => @deduplicate
      }.delete_if{|k,v| v.nil?}
      hash["collection"] = level > 0 ? @collection.to_h(level-1) : @collection.name
    end

# === COMMANDS ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/index/#{@id}")
      return result.headers["x-arango-async-id"] if @@async == "store"
      return_element(result)
    end

    def create
      body = {
        "fields"      => @fields,
        "unique"      => @unique,
        "type"        => @type,
        "id"          => @id,
        "geoJson"     => @geoJson,
        "minLength"   => @minLength,
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
