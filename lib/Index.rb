  # === INDEXES ===

module Arango
  class Index
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Collection_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      collection = hash[:collection]
      if collection.is_a?(Arango::Collection) && collection.database.server.active_cache && !hash[:id].nil?
        cache_name = "#{collection.database.name}/#{collection.name}/#{hash[:id]}"
        cached = collection.database.server.cache.cache.dig(:index, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:type, :sparse, :unique, :fields, :deduplicate, :geoJson,
            :minLength].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(collection:, body: {}, id: nil, type: "hash", unique: nil,
      fields:, sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil,
      cache_name: nil)
      assign_collection(collection)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:index, cache_name, self)
      end
      body[:type]        ||= type
      body[:id]          ||= id
      body[:sparse]      ||= sparse
      body[:unique]      ||= unique
      body[:fields]      ||= fields.is_a?(String) ? [fields] : fields
      body[:deduplicate] ||= deduplicate
      body[:geoJson]     ||= geoJson
      body[:minLength]   ||= minLength

      assign_attributes(body)
    end

# === DEFINE ===

    attr_accessor :id, :unique, :fields, :key, :sparse, :geoJson, :minLenght,
      :deduplicate, :cache_name
    attr_reader :type, :database, :collection, :server

    def type=(type)
      satisfy_category?(type, ["hash", "skiplist", "persistent", "geo", "fulltext", "primary"])
      @type = type
    end
    alias assign_type type=

    def body=(result)
      @body        = result
      @id          = result[:id] || @id
      @key         = @id&.split("/")&.dig(1)
      @type        = assign_type(result[:type] || @type)
      @unique      = result[:unique]      || @unique
      @fields      = result[:fields]      || @fields
      @sparse      = result[:sparse]      || @sparse
      @geoJson     = result[:geoJson]     || @geoJson
      @minLength   = result[:minLength]   || @minLength
      @deduplicate = result[:deduplicate] || @deduplicate
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@collection.name}/#{@id}"
        @server.cache.save(:index, @cache_name, self)
      end
    end
    alias assign_attributes body=

# === DEFINE ===

    def to_h
      {
        "key": @key,
        "id": @id,
        "body": @body,
        "type": @type,
        "sparse": @sparse,
        "unique": @unique,
        "fields": @fields,
        "idCache": @idCache,
        "geoJson": @geoJson,
        "minLength": @minLength,
        "deduplicate": @deduplicate,
        "collection": @collection.name
      }.delete_if{|k,v| v.nil?}
    end

# === COMMANDS ===

    def retrieve
      result = @database.request("GET", "_api/index/#{@id}")
      return_element(result)
    end

    def create
      body = {
        "fields":      @fields,
        "unique":      @unique,
        "type":        @type,
        "id":          @id,
        "geoJson":     @geoJson,
        "minLength":   @minLength,
        "deduplicate": @deduplicate
      }
      query = { "collection": @collection.name }
      result = @database.request("POST", "_api/index", body: body, query: query)
      return_element(result)
    end

    def destroy
      result = @database.request("DELETE", "_api/index/#{@id}")
      return_delete(result)
    end
  end
end
