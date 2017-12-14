  # === INDEXES ===

module Arango
  class Index
    def initialize(collection: , body: {}, id: nil, type: "hash",
      unique: nil, fields:, sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil)
      satisfy_class?(collection, "collection", [Arango::Collection])
      satisfy_class?(body, "body", [Hash])
      satisfy_class?(fields, "fields", [String, Array])
      satisfy_category?(type, "type", ["hash", "skiplist", "persistent", "geo", "fulltext"])
      @collection = collection
      @database = collection.database
      @client = collection.client
      body["type"] ||= type
      body["id"] ||= id
      body["sparse"] ||= sparse
      body["unique"] ||= unique
      body["fields"] ||= fields.is_a?(String) ? [fields] : fields
      assign_attributes(body)
    end

    attr_reader :body, :type, :id, :unique, :fields, :key, :sparse, :idCache, :database, :collection, :client

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
      @body = result
      @id = result["id"]
      @key = @id.split("/")[1]
      @type = result["type"]
      @unique = result["unique"]
      @fields = result["fields"]
      @sparse = result["sparse"]
      @geoJson = result["geoJson"]
      @minLength = result["minLength"]
      @deduplicate = result["deduplicate"]
    end

    def return_index(result)
      return result if @database.client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end

# === COMMANDS ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/index/#{@id}")
      return result.headers["x-arango-async-id"] if @@async == "store"
      return_index(result)
    end

    def self.indexes(collection:)
      satisfy_class?(collection, "collection", [Arango::Collection])
      query = { "collection": collection.name }
      result = collection.database.request(action: "GET",
        url: "/_api/index", query: query)
      return result if return_directly?(result)
      result["indexes"].map do |x|
        Arango::Index.new(body: x, id: x["id"], collection: collection,
          type: x["type"], unique: x["unique"], fields: x["fields"], sparse: x["sparse"])
      end
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
      return_index(result)
    end

    def destroy
      @database.request(action: "DELETE", url: "/_api/index/#{id}")
    end
  end
end
