# === GRAPH ===

module Arango
  class Graph
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache
        cache_name = "#{database.name}/#{hash[:name]}"
        cached = database.server.cache.cache.dig(:graph, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:isSmart, :edgeDefinitions, :orphanCollections, :numberOfShards,
            :replicationFactor, :smartGraphAttribute].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(name:, database:, edgeDefinitions: [],
      orphanCollections: [], body: {}, numberOfShards: nil, isSmart: nil,
      smartGraphAtttribute: nil, replicationFactor: nil, cache_name: nil)
      assign_database(database)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:graph, cache_name, self)
      end
      body[:_key]    ||= name
      body[:_id]     ||= "_graphs/#{name}"
      body[:isSmart] ||= isSmart
      body[:edgeDefinitions]     ||= edgeDefinitions
      body[:orphanCollections]   ||= orphanCollections
      body[:numberOfShards]      ||= numberOfShards
      body[:replicationFactor]   ||= replicationFactor
      body[:smartGraphAttribute] ||= smartGraphAttribute
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :name, :database, :server, :id, :body, :rev, :isSmart, :cache_name
    attr_accessor :numberOfShards, :replicationFactor, :smartGraphAttribute
    alias key name

    def body=(result)
      @body = result
      assign_edgeDefinitions(result[:edgeDefinitions] || @edgeDefinitions)
      assign_orphanCollections(result[:orphanCollections] || @orphanCollections)
      @name    = result[:_key]    || @name
      @id      = result[:_id]     || @id
      @id      = "_graphs/#{@name}" if @id.nil? && !@name.nil?
      @rev     = result[:_rev]    || @rev
      @isSmart = result[:isSmart] || @isSmart
      @numberOfShards = result[:numberOfShards] || @numberOfShards
      @replicationFactor = result[:replicationFactor] || @replicationFactor
      @smartGraphAttribute = result[:smartGraphAttribute] || @smartGraphAttribute
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@name}"
        @server.cache.save(:graph, @cache_name, self)
      end
    end
    alias assign_attributes body=

    def name=(name)
      @name = name
      @id = "_graphs/#{@name}"
    end

    def return_collection(collection, type=nil)
      satisfy_class?(collection, [Arango::Collection, String])
      if collection.is_a?(Arango::Collection)
        return collection
      elsif collection.is_a?(String)
        return Arango::Collection.new(name: collection,
          database: @database, type: type, graph: self)
      end
    end

    def edgeDefinitionsRaw
      @edgeDefinitions ||= []
      @edgeDefinitions.map do |edgedef|
        {
          "collection": edgedef[:collection].name,
          "from": edgedef[:from].map{|t| t.name},
          "to": edgedef[:to].map{|t| t.name}
        }
      end
    end
    private :edgeDefinitionsRaw

    def edgeDefinitions(raw=false)
      return edgeDefinitionsRaw if raw
      return @edgeDefinitions
    end

    def edgeDefinitions=(edgeDefinitions)
      @edgeDefinitions = []
      edgeDefinitions ||= []
      edgeDefinitions = [edgeDefinitions] unless edgeDefinitions.is_a?(Array)
      edgeDefinitions.each do |edgeDefinition|
        hash = {}
        hash[:collection] = return_collection(edgeDefinition[:collection], :edge)
        edgeDefinition[:from] ||= []
        edgeDefinition[:to]   ||= []
        hash[:from] = edgeDefinition[:from].map{|t| return_collection(t)}
        hash[:to]   = edgeDefinition[:to].map{|t| return_collection(t)}
        setup_orphaCollection_after_adding_edge_definitions(hash)
        @edgeDefinitions << hash
      end
    end
    alias assign_edgeDefinitions edgeDefinitions=

    def orphanCollections=(orphanCollections)
      orphanCollections ||= []
      orphanCollections = [orphanCollections] unless orphanCollections.is_a?(Array)
      @orphanCollections = orphanCollections.map{|oc| add_orphan_collection(oc)}
    end
    alias assign_orphanCollections orphanCollections=

    def orphanCollectionsRaw
      @orphanCollections ||= []
      @orphanCollections.map{|oc| oc.name}
    end
    private :orphanCollectionsRaw

    def orphanCollections(raw=false)
      return orphanCollectionsRaw if raw
      return @orphanCollections
    end

# === HANDLE ORPHAN COLLECTION ===

    def add_orphan_collection(orphanCollection)
      orphanCollection = return_collection(orphanCollection)
      if @edgeDefinitions.any? do |ed|
          names = []
          names |= ed[:from].map{|f| f&.name}
          names |= ed[:to].map{|t| t&.name}
          names.include?(orphanCollection.name)
        end
        raise Arango::Error.new err: :orphan_collection_used_by_edge_definition, data: {"collection": orphanCollection.name}
      end
      return orphanCollection
    end
    private :add_orphan_collection

    def setup_orphaCollection_after_adding_edge_definitions(edgeDefinition)
      collection = []
      collection |= edgeDefinition[:from]
      collection |= edgeDefinition[:to]
      @orphanCollections.delete_if{|c| collection.include?(c.name)}
    end
    private :setup_orphaCollection_after_adding_edge_definitions

    def setup_orphaCollection_after_removing_edge_definitions(edgeDefinition)
      edgeCollection = edgeDefinition[:collection].name
      collections |= []
      collections |= edgeDefinition[:from]
      collections |= edgeDefinition[:to]
      collections.each do |collection|
        unless @edgeDefinitions.any? do |ed|
            if ed[:collection].name != edgeCollection
              names = []
              names |= ed[:from].map{|f| f&.name}
              names |= ed[:to].map{|t| t&.name}
              names.include?(collection.name)
            else
              false
            end
          end
          unless @orphanCollections.map{|oc| oc.name}.include?(collection.name)
            @orphanCollections << collection
          end
        end
      end
    end
    private :setup_orphaCollection_after_removing_edge_definitions

# === REQUEST ===

    def request(action, url, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false, skip_to_json: false)
      url = "_api/gharial/#{@name}/#{url}"
      @database.request(action, url, body: body, headers: headers,
        query: query, key: key, return_direct_result: return_direct_result,
        skip_to_json: skip_to_json)
    end

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name": @name,
        "id": @id,
        "rev": @rev,
        "isSmart": @isSmart,
        "numberOfShards": @numberOfShards,
        "replicationFactor": @replicationFactor,
        "smartGraphAttribute": @smartGraphAttribute,
        "edgeDefinitions": edgeDefinitionsRaw,
        "orphanCollections": orphanCollectionsRaw,
        "cache_name": @cache_name
      }
      hash.delete_if{|k,v| v.nil?}
      hash[:database] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === GET ===

    def retrieve
      result = @database.request("GET", "_api/gharial/#{@name}", key: :graph)
      return_element(result)
    end

# === POST ===

    def create(isSmart: @isSmart, smartGraphAttribute: @smartGraphAttribute,
      numberOfShards: @numberOfShards)
      body = {
        "name": @name,
        "edgeDefinitions":   edgeDefinitionsRaw,
        "orphanCollections": orphanCollectionsRaw,
        "isSmart": isSmart,
        "options": {
          "smartGraphAttribute": smartGraphAttribute,
          "numberOfShards": numberOfShards
        }
      }
      body[:options].delete_if{|k,v| v.nil?}
      body.delete(:options) if body[:options].empty?
      result = @database.request("POST", "_api/gharial", body: body, key: :graph)
      return_element(result)
    end

# === DELETE ===

    def destroy(dropCollections: nil)
      query = { "dropCollections": dropCollections }
      result = @database.request("DELETE", "_api/gharial/#{@name}", query: query,
        key: :removed)
      return_delete(result)
    end

# === VERTEX COLLECTION  ===

    def getVertexCollections
      result = request("GET", "vertex", key: :collections)
      return result if return_directly?(result)
      result.map do |x|
        Arango::Collection.new(name: x, database: @database, graph: self)
      end
    end
    alias vertexCollections getVertexCollections

    def addVertexCollection(collection:)
      satisfy_class?(collection, [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      body = { "collection": collection }
      result = request("POST", "vertex", body: body, key: :graph)
      return_element(result)
    end

    def removeVertexCollection(collection:, dropCollection: nil)
      query = {"dropCollection": dropCollection}
      satisfy_class?(collection, [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      result = request("DELETE", "vertex/#{collection}", query: query, key: :graph)
      return_element(result)
    end

  # === EDGE COLLECTION ===

    def getEdgeCollections
      result = request("GET", "edge", key: :collections)
      return result if @database.server.async != false
      return result if return_directly?(result)
      result.map{|r| Arango::Collection.new(database: @database, name: r, type: :edge)}
    end

    def addEdgeDefinition(collection:, from:, to:)
      satisfy_class?(collection, [String, Arango::Collection])
      satisfy_class?(from, [String, Arango::Collection], true)
      satisfy_class?(to, [String, Arango::Collection], true)
      from = [from] unless from.is_a?(Array)
      to = [to] unless to.is_a?(Array)
      body = {}
      body[:collection] = collection.is_a?(String) ? collection : collection.name
      body[:from] = from.map{|f| f.is_a?(String) ? f : f.name }
      body[:to] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = request("POST", "edge", body: body, key: :graph)
      return_element(result)
    end

    def replaceEdgeDefinition(collection:, from:, to:)
      satisfy_class?(collection, [String, Arango::Collection])
      satisfy_class?(from, [String, Arango::Collection], true)
      satisfy_class?(to, [String, Arango::Collection], true)
      from = [from] unless from.is_a?(Array)
      to = [to] unless to.is_a?(Array)
      body = {}
      body[:collection] = collection.is_a?(String) ? collection : collection.name
      body[:from] = from.map{|f| f.is_a?(String) ? f : f.name }
      body[:to] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = request("PUT", "edge/#{body[:collection]}", body: body, key: :graph)
      return_element(result)
    end

    def removeEdgeDefinition(collection:, dropCollection: nil)
      satisfy_class?(collection, [String, Arango::Collection])
      query = {"dropCollection": dropCollection}
      collection = collection.is_a?(String) ? collection : collection.name
      result = request("DELETE", "edge/#{collection}", query: query, key: :graph)
      return_element(result)
    end
  end
end
