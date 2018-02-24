# === GRAPH ===

module Arango
  class Graph
    include Helper_Error
    include Meta_prog
    include Helper_Return
    
    def initialize(name:, database:, edgeDefinitions: [],
      orphanCollections: [], body: {}, numberOfShards: nil, isSmart: nil, smartGraphAtttribute: nil, replicationFactor: nil)
      satisfy_class?(database, Arango::Database])

      @database = database
      @client = @database.client
      body["_key"] ||= name
      body["_id"] ||= "_graphs/#{name}"
      body["edgeDefinitions"] ||= edgeDefinitions
      body["orphanCollections"] ||= orphanCollections
      body["isSmart"] ||= isSmart
      body["numberOfShards"] = numberOfShards
      body["replicationFactor"] = replicationFactor
      body["smartGraphAttribute"] = smartGraphAttribute
      assign_attributes(body)
    end

    attr_reader :name, :database, :client, :id, :body, :rev, :isSmart
    attr_accessor :numberOfShards, :replicationFactor, :smartGraphAttribute
    alias key name

    def name=(name)
      @name = name
      @id = "_graphs/#{@name}"
    end

    def return_collection(collection, type=nil)
      if collection.is_a?(Arango::Collection)
        return collection
      elsif collection.is_a?(String)
        collection_instance = Arango::Collection.new(name: edgedef["collection"],
          database: @database, type: type, graph: self)
        return collection_instance
      else
        raise Arango::Error.new message: "#{collection} should be an Arango::Collection or
        a name of a class"
      end
    end

    def edgeDefinitionsRaw
      @edgeDefinitions ||= []
      @edgeDefinitions.map do |edgedef|
        {
          "collection" => edgedef["collection"].name,
          "from" => edgedef["from"].map{|t| t.name},
          "to"   => edgedef["to"].map{|t| t.name}
        }
      end
    end

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
        hash["from"] = edgeDefinition["from"].map do |t|
          return_collection(t)
        end
        edgeDefinition["to"] ||= []
        hash["to"] = edgeDefinition["to"].map do |t|
          return_collection(t)
        end
        @edgeDefinitions << hash
      end
    end
    alias assign_edgeDefinitions edgeDefinitions=

    def database=(database)
      satisfy_class?(database, [Arango::Database])
      @database = database
      @client = @database.client
    end

    def orphanCollections=(orphanCollections)
      orphanCollections ||= []
      @orphanCollections = orphanCollections.map do |oc|
        return_collection(oc)
      end
    end
    alias assign_orphanCollections edgeDefinitions=

    def orphanCollectionsRaw
      @orphanCollections ||= []
      @orphanCollections.map{|oc| oc.name}
    end

    def orphanCollections(raw=false)
      return orphanCollectionsRaw if raw
      return @orphanCollections
    end

    def assign_attributes(result)
      result.delete_if{|k,v| v.nil?}
      @name = result["name"]
      assign_edgeDefinitions(result["edgeDefinitions"])
      assign_orphanCollections(result["orphanCollections"])
      @id = result["_id"]
      @rev = result["_rev"]
      @isSmart = result["isSmart"]
      @numberOfShards = result["numberOfShards"]
      @replicationFactor = result["replicationFactor"]
      @smartGraphAttribute = result["smartGraphAttribute"]
    end

    def request(action:, url:, body: {}, headers: {}, query: {}, key: nil, return_direct_result: false, skip_to_json: false)
      url = "_api/gharial/#{@key}/#{url}"
      @database.request(action: action, url: url, body: body, headers: headers,
        query: query, key: key, return_direct_result: return_direct_result,
        skip_to_json: skip_to_json)
    end

    def to_h(level=0)
      hash = {
        "name" => @name,
        "id" => @id,
        "rev" => @rev,
        "isSmart" => @isSmart,
        "numberOfShards" => @numberOfShards,
        "replicationFactor" @replicationFactor,
        "smartGraphAttribute" => @smartGraphAttribute,
        "edgeDefinitions" => edgeDefinitionsRaw,
        "orphanCollections" => orphanCollectionsRaw
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name

      hash
    end

# === GET ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/gharial/#{@key}")
      return_element(result)
    end

# === POST ===

    def create(isSmart: @isSmart, smartGraphAttribute: @smartGraphAttribute, numberOfShards: @numberOfShards)
      body = {
        "name" => @key, "edgeDefinitions" => edgeDefinitionsRaw,
        "orphanCollections" => orphanCollectionsRaw, "isSmart" => isSmart,
        "options" => {
          "smartGraphAttribute" => smartGraphAttribute,
          "numberOfShards" => numberOfShards
        }
      }
      body["options"].delete_if{|key, val| val.nil?}
      body.delete("options") if body["options"].empty?
      result = @database.request(action: "POST", url: "_api/gharial", body: body)
      return_element(result)
    end

# === DELETE ===

    def destroy(dropCollections: nil)
      query = { "dropCollections" => dropCollections }
      result = @database.request(action: "DELETE", url: "_api/gharial/#{@key}",
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
