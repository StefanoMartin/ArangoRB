# === GRAPH ===

module Arango
  class Graph
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(name:, database:, edgeDefinitions: [],
      orphanCollections: [], body: {}, numberOfShards: nil, isSmart: nil, smartGraphAtttribute: nil, replicationFactor: nil)
      assign_database(database)
      body["_key"]    ||= name
      body["_id"]     ||= "_graphs/#{name}"
      body["isSmart"] ||= isSmart
      body["edgeDefinitions"]     ||= edgeDefinitions
      body["orphanCollections"]   ||= orphanCollections
      body["numberOfShards"]      ||= numberOfShards
      body["replicationFactor"]   ||= replicationFactor
      body["smartGraphAttribute"] ||= smartGraphAttribute
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :name, :database, :client, :id, :body, :rev, :isSmart
    attr_accessor :numberOfShards, :replicationFactor, :smartGraphAttribute
    alias key name

    def body=(result)
      @body = result
      assign_edgeDefinitions(result["edgeDefinitions"] || @edgeDefinitions)
      assign_orphanCollections(result["orphanCollections"] || @orphanCollections)
      @name    = result["name"]    || @name
      @id      = result["_id"]     || @id
      @rev     = result["_rev"]    || @rev
      @isSmart = result["isSmart"] || @isSmart
      @numberOfShards = result["numberOfShards"] || @numberOfShards
      @replicationFactor = result["replicationFactor"] || @replicationFactor
      @smartGraphAttribute = result["smartGraphAttribute"] || @smartGraphAttribute
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
          "collection" => edgedef["collection"].name,
          "from"       => edgedef["from"].map{|t| t.name},
          "to"         => edgedef["to"].map{|t| t.name}
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
      edgeDefinitions.each do |edgeDefinition|
        hash["collection"] = return_collection(edgeDefinition["collection"], "Edge")
        edgeDefinition["from"] ||= []
        edgeDefinition["to"]   ||= []
        hash["from"] = edgeDefinition["from"].map{|t| return_collection(t)}
        hash["to"]   = edgeDefinition["to"].map{|t| return_collection(t)}
        @edgeDefinitions << hash
      end
    end
    alias assign_edgeDefinitions edgeDefinitions=

    def orphanCollections=(orphanCollections)
      orphanCollections ||= []
      @orphanCollections = orphanCollections.map{|oc| return_collection(oc)}
    end
    alias assign_orphanCollections edgeDefinitions=

    def orphanCollectionsRaw
      @orphanCollections ||= []
      @orphanCollections.map{|oc| oc.name}
    end
    private :orphanCollectionsRaw

    def orphanCollections(raw=false)
      return orphanCollectionsRaw if raw
      return @orphanCollections
    end

# === REQUEST ===

    def request(action:, url:, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false, skip_to_json: false)
      url = "_api/gharial/#{@name}/#{url}"
      @database.request(action: action, url: url, body: body, headers: headers,
        query: query, key: key, return_direct_result: return_direct_result,
        skip_to_json: skip_to_json)
    end

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name"    => @name,
        "id"      => @id,
        "rev"     => @rev,
        "isSmart" => @isSmart,
        "numberOfShards"      => @numberOfShards,
        "replicationFactor"   => @replicationFactor,
        "smartGraphAttribute" => @smartGraphAttribute,
        "edgeDefinitions"     => edgeDefinitionsRaw,
        "orphanCollections"   => orphanCollectionsRaw
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === GET ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/gharial/#{@name}")
      return_element(result)
    end

# === POST ===

    def create(isSmart: @isSmart, smartGraphAttribute: @smartGraphAttribute,
      numberOfShards: @numberOfShards)
      body = {
        "name" => @name,
        "edgeDefinitions"   => edgeDefinitionsRaw,
        "orphanCollections" => orphanCollectionsRaw,
        "isSmart"           => isSmart,
        "options" => {
          "smartGraphAttribute" => smartGraphAttribute,
          "numberOfShards"      => numberOfShards
        }
      }
      body["options"].delete_if{|key, val| val.nil?}
      body.delete("options") if body["options"].empty?
      result = @database.request(action: "POST", url: "_api/gharial",
        body: body)
      return_element(result)
    end

# === DELETE ===

    def destroy(dropCollections: nil)
      query = { "dropCollections" => dropCollections }
      result = @database.request(action: "DELETE", url: "_api/gharial/#{@name}",
        query: query)
      return_element(result)
    end

# === VERTEX COLLECTION  ===

    def getVertexCollections
      result = request(action: "GET", url: "vertex")
      return result if return_directly?(result)
      result["collections"].map do |x|
        Arango::Collection.new(name: x, database: @database, graph: self)
      end
    end
    alias vertexCollections getVertexCollections

    def addVertexCollection(collection:)
      satisfy_class?(collection, [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      body = { "collection" => collection }
      result = request(action: "POST", url: "vertex", body: body)
      return result if @database.client.async != false
      @orphanCollections |= [collection]
      return return_directly?(result) ? result : self
    end

    def removeVertexCollection(collection:, dropCollection: nil)
      query = {"dropCollection" => dropCollection}
      satisfy_class?(collection, [String, Arango::Collection])
      collection = collection.is_a?(String) ? collection : collection.name
      result = request(action: "DELETE", url: "vertex/#{collection}", query: query)
      return_element(result)
    end

  # === EDGE COLLECTION ===

    def getEdgeDefinitions
      result = request(action: "GET", url: "edge")
      return result if @database.client.async != false
      assign_edgeDefinitions(result["collections"])
      @edgeDefinitions = result["collections"]
      return result if return_directly?(result)
      @edgeDefinitions
    end

    def addEdgeDefinition(collection:, from:, to:)
      satisfy_class?(collection, [String, Arango::Collection])
      satisfy_class?(from, [String, Arango::Collection], true)
      satisfy_class?(to, [String, Arango::Collection], true)
      body = {}
      body["collection"] = collection.is_a?(String) ? collection : collection.name
      body["from"] = from.map{|f| f.is_a?(String) ? f : f.name }
      body["to"] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = request(action: "POST", url: "edge", body: body)
      return_element(result)
    end

    def replaceEdgeCollection(collection:, from:, to:)
      satisfy_class?(collection, [String, Arango::Collection])
      satisfy_class?(from, [String, Arango::Collection], true)
      satisfy_class?(to, [String, Arango::Collection], true)
      body = {}
      body["collection"] = collection.is_a?(String) ? collection : collection.name
      body["from"] = from.map{|f| f.is_a?(String) ? f : f.name }
      body["to"] = to.map{|t| t.is_a?(String) ? t : t.name }
      result = request(action: "PUT", url: "edge", body: body)
      return_element(result)
    end

    def removeEdgeCollection(collection:, dropCollection: nil)
      satisfy_class?(collection, [String, Arango::Collection])
      query = {"dropCollection" => dropCollection}
      collection = collection.is_a?(String) ? collection : collection.collection
      result = request(action: "DELETE", url: "edge/#{collection}", query: query)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return_element(result)
    end
  end
end
