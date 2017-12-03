# === COLLECTION ===

module Arango
  class Collection
    def initialize(collection:, database:, body: {}, type: nil, from: nil, to: nil)
      satisfy_class?(collection, "collection", [Arango::Collection, String])
      satisfy_class?(database, "database", [Arango::Database])
      satisfy_class?(client, "client", [Arango::Client])
      satisfy_class?(body, "body", [Hash])
      satisfy_category?(type, , "type", ["Document", "Edge"])
      satisfy_class?(from, "from", [Arango::Collection, String, NilClass])
      satisfy_class?(to, "to", [Arango::Collection, String, NilClass])
      @collection = collection.is_a?(String) ? collection : collection.collection
      @database = database
      @client = @database.client
      @body = body
      @type = type
      if from.is_a?(String)
        from = Arango::Collection.new(collection: from, database: @database)
      end
      @from = from
      if to.is_a?(String)
        to = Arango::Collection.new(collection: to, database: @database)
      end
      @to = to

      if @type == "Document"
        @body["type"] = 2
      elsif @type == "Edge"
        @body["type"] = 3
      end
    end

    attr_reader :collection, :body, :type, :client, :database
    alias name collection

    # === RETRIEVE ===

    def to_hash
      {
        "collection" => @collection,
        "database" => @database.name,
        "type" => @type,
        "body" => @body
      }.delete_if{|k,v| v.nil?}
    end
    alias to_h to_hash

    def [](document_name)
      ArangoDocument.new(key: document_name, collection: self, database: @database, client: @client)
    end
    alias document []

    # === GET ===

    def retrieve
      result = @client.request(action: "GET", url: "/_db/#{@database.name}/_api/collection/#{@collection}")
      return result if @client.async != false
      @body = result
      @type = result["type"] == 2 ? "Document" : "Edge"
      return @body
    end

    def properties
      @client.request(action: "GET", url: "/_db/#{@database.name}/_api/collection/#{@collection}/properties")
    end

    def count
      @client.request(action: "GET", url: "/_db/#{@database.name}/_api/collection/#{@collection}/count", key: "count")
    end

    def statistics
      @client.request(action: "GET", url: "/_db/#{@database.name}/_api/collection/#{@collection}/figures", key: "figures")
    end

    def revision
      @client.request(action: "GET", url:"/_db/#{@database.name}/_api/collection/#{@collection}/revision", key: "revision")
    end

    def checksum(withRevisions: nil, withData: nil)
      query = {
        "withRevisions": withRevisions,
        "withData": withData
      }
      @client.request(action: "GET", url: "/_db/#{@database.name}/_api/collection/#{@collection}/checksum", key: "checksum")
    end

    # === POST ===

    def create(type: nil, journalSize: nil, keyOptions: nil, waitForSync: nil,
      doCompact: nil, isVolatile: nil, shardKeys: nil, numberOfShards: nil,
      isSystem: nil, indexBuckets: nil)
      type = 3   if type == "Edge"
      type = nil if type == "Document"
      body = {
        "name" => @collection,
        "type" => type,
        "journalSize" => journalSize,
        "keyOptions" => keyOptions,
        "waitForSync" => waitForSync,
        "doCompact" => doCompact,
        "isVolatile" => isVolatile,
        "shardKeys" => shardKeys,
        "numberOfShards" => numberOfShards,
        "isSystem" => isSystem,
        "indexBuckets" => indexBuckets
      }
      request = @@request.merge({ :body => body })
      result = @client.request(action: "POST", url: "/_db/#{@database.name}/_api/collection")
      return result if @client.async != false
      @body = result
      @type = result["type"] == 2 ? "Document" : "Edge"
    end
    alias create_collection create
    alias create_document_collection create
    alias create_vertex_collection create

    def create_edge_collection(journalSize: nil, keyOptions: nil,
      waitForSync: nil, doCompact: nil, isVolatile: nil, shardKeys: nil,
      numberOfShards: nil, isSystem: nil, indexBuckets: nil)
      create(type: 3, journalSize: journalSize, keyOptions: keyOptions,
        waitForSync: waitForSync, doCompact: doCompact,
        isVolatile: isVolatile, shardKeys: shardKeys,
        numberOfShards: numberOfShards, isSystem: isSystem,
        indexBuckets: indexBuckets)
    end

    def create_document(document: {}, waitForSync: nil, returnNew: nil) #
      Arango::Document.create(body: document, waitForSync: waitForSync, returnNew: returnNew, database: @database, collection: self, client: @client)
    end
    alias create_vertex create_document

    def create_edge(document: {}, from:, to:, waitForSync: nil, returnNew: nil)
      Arango::Document.create_edge(body: document, from: from, to: to,
        waitForSync: waitForSync, returnNew: returnNew, database: @database,
        collection: self, client: @client)
    end

# === DELETE ===

    def destroy
      @client.request(action: "DELETE", url: "/_db/#{@database.name}/_api/collection/#{@collection}")
    end

    def truncate
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/truncate")
    end

    # === MODIFY ===

    def load
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/load")
    end

    def unload
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/unload")
    end

    def change(waitForSync: nil, journalSize: nil)
      body = {
        "journalSize" => journalSize,
        "waitForSync" => waitForSync
      }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/properties")
    end

    def rename(newName)
      body = { "name" => newName }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/rename", body: body)
      @collection = newName
    end

    def rotate
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/collection/#{@collection}/rotate", caseTrue: true)
    end

    # === SIMPLE FUNCTIONS ===

    def documents(type: nil) # "path", "id", "key"
      body = {
        "collection" => @collection,
        "type" => type
      }
      result = @client.request(action: "PUT", url: "/_db/#{@database}/_api/simple/all-keys", body: body)
      return result if @client.async != false
      if type.nil?
        result["result"].map do |x|
          Arango::Document.new(key: value["_key"], collection: self,
            database: @database, client: @client, body: x)
        end
      else
        result["result"]
      end
    end

    def generic_document_search(url, body, single=false)
      result = @client.request(action: "PUT", url: url, body: body)
      return result if @client.async != false
      if single
        Arango::Document.new(key: result["document"]["_key"], collection: self, database: @database, client: @client, body:  result["document"])
      else
        result["result"].map do |x|
          Arango::Document.new(key: x["_key"], collection: self,
            database: @database, client: @client, body: x)
        end
      end
    end
    private :generic_document_search

    def allDocuments(skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @collection,
        "skip" => skip,
        "limit" => limit,
        "batchSize" => batchSize
      }
      generic_document_search("/_db/#{@database.name}/_api/simple/all", body)
    end

    def documentsMatch(match:, skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @collection,
        "example" => match,
        "skip" => skip,
        "limit" => limit,
        "batchSize" => batchSize
      }
      generic_document_search("/_db/#{@database.name}/_api/simple/by-example", body)
    end

    def documentMatch(match:)
      body = {
        "collection" => @collection,
        "example" => match
      }
      generic_document_search("/_db/#{@database.name}/_api/simple/first-example",
        body, true)
    end

    def documentByKeys(keys:)
      keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(Arango::Document) ? x.key : nil} if keys.is_a? Array
      keys = [keys] if keys.is_a? String
      body = { "collection" => @collection, "keys" => keys }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/simple/lookup-by-keys", body: body)
      return result if @client.async != false
      result["documents"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x,
          database: @database, client: @client)}
    end

    def random
      body = { "collection" => @collection }
      generic_document_search("/_db/#{@database.name}/_api/simple/any",
        body, true)
    end

    def removeByKeys(keys:, options: nil)
      keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(ArangoDocument) ? x.key : nil}
      body = { "collection" => @collection, "keys" => keys, "options" => options }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/simple/remove-by-keys", body: body, key: "removed")
    end

    def removeMatch(match:, options: nil)
      body = {
        "collection" => @collection,
        "example" => match,
        "options" => options
      }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/simple/remove-by-example", body: body, key: "deleted")
    end

    def replaceMatch(match:, newValue:, options: nil)
      body = {
        "collection" => @collection,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/simple/replace-by-example", body: body, key: "replaced")
    end

    def updateMatch(match:, newValue:, options: nil)
      body = {
        "collection" => @collection,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/simple/update-by-example", body: body, key: "updated")
    end

    # === IMPORT ===

    def import(attributes:, values:, from: nil, to: nil, overwrite: nil, waitForSync: nil, onDuplicate: nil, complete: nil, details: nil)
      query = {
        "collection": @collection,
        "fromPrefix": from,
        "toPrefix": to,
        "overwrite": overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete": complete,
        "details": details
      }
      body = "#{attributes}\n"
      values[0].is_a?(Array) ? values.each{|x| body += "#{x}\n"} : body += "#{values}\n"
      @client.request(action: "POST", url: "/_db/#{@database.name}/_api/import", body: body, query: query, skip_to_json: true)
    end

    def importJSON(body:, type: "auto", from: nil, to: nil, overwrite: nil, waitForSync: nil, onDuplicate: nil, complete: nil, details: nil)
      query = {
        "collection": @collection,
        "type": type,
        "fromPrefix": from,
        "toPrefix": to,
        "overwrite": overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete": complete,
        "details": details
      }
      @client.request(action: "POST", url: "/_db/#{@database.name}/_api/import", query: query, body: body)
    end

  # === EXPORT ===

    def export(count: nil, restrict: nil, batchSize: nil, flush: nil, limit: nil, ttl: nil)  # TESTED
      query = { "collection" => @collection }
      body = {
        "count" => count,
        "restrict" => restrict,
        "batchSize" => batchSize,
        "flush" => flush,
        "limit" => limit,
        "ttl" => ttl
      }
      result = @client.request(action: "POST", url: "/_db/#{@database.name}/_api/export", query: query, body: body)
      return result if @client.async != false
      @countExport = result["count"]
      @hasMoreExport = result["hasMore"]
      @idExport = result["id"]
      if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        result["result"]
      else
        result["result"].map do |x|
          Arango::Document.new(key: x["_key"], collection: self, database: @database, client: @client, body: x)}
      end
    end

    def exportNext  # TESTED
      unless @hasMoreExport
        Arango::Error message: "No other results"
      else
        query = { "collection": @collection }
        result = @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/export/#{@idExport}", query: query)
        return result if @client.async != false
        @countExport = result["count"]
        @hasMoreExport = result["hasMore"]
        @idExport = result["id"]
        if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
          result["result"]
        else
          result["result"].map do |x|
            Arango::Document.new(key: x["_key"], collection: self, database: @database, client: @client, body: x)}
        end
      end
    end

# === INDEXES ===

    def index(body: {}, id: nil, type: nil, unique: nil, fields:, sparse: nil)
      Arango::Index.new(collection: self, database: @database, client: @client, body: {}, id: nil, type: nil, unique: nil, fields:, sparse: nil)
    end

    def indexes  # TESTED
      query = { "collection": @collection }
      result = @client.request(action: "GET", url: "/_db/#{@database.name}/_api/index", query: query)
      return result if @client.async != false
      result["indexes"].map do |x|
        Arango::Index.new(body: x, id: x["id"], database: @database, collection: self, client: @client, type: x["type"], unique: x["unique"], fields: x["fields"])}
      end
    end

# === REPLICATION ===

    def data(from: nil, to: nil, chunkSize: nil, includeSystem: false, failOnUnknown: nil, ticks: nil, flush: nil)
      query = {
        "collection": @collection,
        "from": from,
        "to": to,
        "chunkSize": chunkSize,
        "includeSystem": includeSystem,
        "failOnUnknown": failOnUnknown,
        "ticks": ticks,
        "flush": flush
      }
      @client.request(action: "GET", url: "/_db/#{@database.name}/_api/replication/dump", query: query)
    end
    alias dump data

  end
end
