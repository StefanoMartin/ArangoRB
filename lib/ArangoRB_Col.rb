# === COLLECTION ===

class ArangoCollection < ArangoServer
  def initialize(collection: @@collection, database: @@database, body: {}, type: nil) # TESTED
    if collection.is_a?(String)
      @collection = collection
    elsif collection.is_a?(ArangoCollection)
      @collection = collection.collection
    else
      raise "collection should be a String or an ArangoCollection instance, not a #{collection.class}"
    end

    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end

    if body.is_a?(Hash)
      @body = body
    else
      raise "body should be a Hash, not a #{body.class}"
    end

    if !@type.nil? && @type != "Document" && @type != "Edge"
      raise "type should be \"Document\" or \"Edge\""
    else
      @type = type
      if @type == "Document"
        @body["type"] = 2
      elsif @type == "Edge"
        @body["type"] = 3
      end
    end
    @idCache = "COL_#{@collection}"
  end

  attr_reader :collection, :body, :type, :idCache
  alias name collection

  # === RETRIEVE ===

  def [](document_name)
    ArangoDocument.new(key: document_name, collection: @collection, database: @database)
  end
  alias document []

  def database
    ArangoDatabase.new(database: @database)
  end

  # === GET ===

  def retrieve # TESTED
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}", @@request)
    self.return_result result: result, checkType: true
  end

  def properties # TESTED
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}/properties", @@request)
    result = self.return_result result: result
    return result.is_a?(ArangoCollection) ? result.body : result
  end

  def count # TESTED
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}/count", @@request)
    self.return_result result: result, key: "count"
  end

  def statistics # TESTED
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}/figures", @@request)
    self.return_result result: result, key: "figures"
  end

  def revision # TESTED
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}/revision", @@request)
    self.return_result result: result, key: "revision"
  end

  def checksum(withRevisions: nil, withData: nil) # TESTED
    query = {
      "withRevisions": withRevisions,
      "withData": withData
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/collection/#{@collection}/checksum", request)
    self.return_result result: result, key: "checksum"
  end

  # === POST ===

  def create(type: nil, journalSize: nil, keyOptions: nil, waitForSync: nil, doCompact: nil, isVolatile: nil, shardKeys: nil, numberOfShards: nil, isSystem: nil, indexBuckets: nil) # TESTED
    type = 3 if type == "Edge"
    type = nil if type == "Document"
    body = {
      "name" => collection,
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
    body = body.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_db/#{@database}/_api/collection", request)
    self.return_result result: result, checkType: true
  end
  alias create_collection create
  alias create_document_collection create
  alias create_vertex_collection create

  def create_edge_collection(journalSize: nil, keyOptions: nil, waitForSync: nil, doCompact: nil, isVolatile: nil, shardKeys: nil, numberOfShards: nil, isSystem: nil, indexBuckets: nil) # TESTED
    self.create type: 3, journalSize: journalSize, keyOptions: keyOptions, waitForSync: waitForSync, doCompact: doCompact, isVolatile: isVolatile, shardKeys: shardKeys, numberOfShards: numberOfShards, isSystem: isSystem, indexBuckets: indexBuckets
  end

  def create_document(document: {}, waitForSync: nil, returnNew: nil) # TESTED
    ArangoDocument.create(body: document, waitForSync: waitForSync, returnNew: returnNew, database: @database, collection: @collection)
  end
  alias create_vertex create_document

  def create_edge(document: {}, from:, to:, waitForSync: nil, returnNew: nil) # TESTED
    ArangoDocument.create_edge(body: document, from: from, to: to, waitForSync: waitForSync, returnNew: returnNew, database: @database, collection: @collection)
  end

  # === DELETE ===

  def destroy # TESTED
    result = self.class.delete("/_db/#{@database}/_api/collection/#{@collection}", @@request)
    self.return_result result: result, caseTrue: true
  end

  def truncate # TESTED
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/truncate", @@request)
    self.return_result result: result
  end

  # === MODIFY ===

  def load # TESTED
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/load", @@request)
    self.return_result result: result
  end

  def unload # TESTED
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/unload", @@request)
    self.return_result result: result
  end

  def change(waitForSync: nil, journalSize: nil) # TESTED
    body = {
      "journalSize" => journalSize,
      "waitForSync" => waitForSync
    }
    body = body.delete_if{|k,v| k.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/properties", request)
    self.return_result result: result
  end

  def rename(newName) # TESTED
    body = { "name" => newName }
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/rename", request)
    @collection = newName unless result.parsed_response["error"]
    self.return_result result: result
  end

  def rotate
    result = self.class.put("/_db/#{@database}/_api/collection/#{@collection}/rotate", @@request)
    self.return_result result: result, caseTrue: true
  end

  # === SIMPLE FUNCTIONS ===

  def documents(type: nil) # "path", "id", "key" # TESTED
    body = {
      "collection" => @collection,
      "type" => type
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/all-keys", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if type.nil?
      @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| value = self.class.get(x).parsed_response; ArangoDocument.new(key: value["_key"], collection: @collection, body: value)}
    else
      @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
    end
  end

  def allDocuments(skip: nil, limit: nil, batchSize: nil) # TESTED
    body = {
      "collection" => @collection,
      "skip" => skip,
      "limit" => limit,
      "batchSize" => batchSize
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/all", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, body: x)}
  end

  def documentsMatch(match:, skip: nil, limit: nil, batchSize: nil) # TESTED
    body = {
      "collection" => @collection,
      "example" => match,
      "skip" => skip,
      "limit" => limit,
      "batchSize" => batchSize
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/by-example", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, body: x)}
  end

  def documentMatch(match:) # TESTED
    body = {
      "collection" => @collection,
      "example" => match
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/first-example", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["document"]["_key"], collection: @collection, body: result["document"])
  end

  def documentByKeys(keys:) # TESTED
    keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(ArangoDocument) ? x.key : nil} if keys.is_a? Array
    keys = [keys] if keys.is_a? String
    body = { "collection" => @collection, "keys" => keys }
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/simple/lookup-by-keys", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["documents"].map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, body: x)}
  end

  def random # TESTED
    body = { "collection" => @collection }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/any", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDocument.new(key: result["document"]["_key"], collection: @collection, body: result["document"])
  end

  def removeByKeys(keys:, options: nil) # TESTED
    keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(ArangoDocument) ? x.key : nil}
    body = { "collection" => @collection, "keys" => keys, "options" => options }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/remove-by-keys", request)
    self.return_result result: result, key: "removed"
  end

  def removeMatch(match:, options: nil) # TESTED
    body = {
      "collection" => @collection,
      "example" => match,
      "options" => options
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/remove-by-example", request)
    self.return_result result: result, key: "deleted"
  end

  def replaceMatch(match:, newValue:, options: nil) # TESTED
    body = {
      "collection" => @collection,
      "example" => match,
      "options" => options,
      "newValue" => newValue
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/replace-by-example", request)
    self.return_result result: result, key: "replaced"
  end

  def updateMatch(match:, newValue:, options: nil) # TESTED
    body = {
      "collection" => @collection,
      "example" => match,
      "options" => options,
      "newValue" => newValue
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.put("/_db/#{@database}/_api/simple/update-by-example", request)
    self.return_result result: result, key: "updated"
  end

# === IMPORT ===

  def import(attributes:, values:, from: nil, to: nil, overwrite: nil, waitForSync: nil, onDuplicate: nil, complete: nil, details: nil)  # TESTED
    query = {
      "collection": @collection,
      "fromPrefix": from,
      "toPrefix": to,
      "overwrite": overwrite,
      "waitForSync": waitForSync,
      "onDuplicate": onDuplicate,
      "complete": complete,
      "details": details
    }.delete_if{|k,v| v.nil?}
    body = "#{attributes}\n"
    values[0].is_a?(Array) ? values.each{|x| body += "#{x}\n"} : body += "#{values}\n"
    request = @@request.merge({ :body => body, :query => query })
    result = self.class.post("/_db/#{@database}/_api/import", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result.delete_if{|k,v| k == "error" || k == "code"}
  end

  def importJSON(body:, type: "auto", from: nil, to: nil, overwrite: nil, waitForSync: nil, onDuplicate: nil, complete: nil, details: nil)  # TESTED
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
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/import", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result.delete_if{|k,v| k == "error" || k == "code"}
  end

# === EXPORT ===

  def export(count: nil, restrict: nil, batchSize: nil, flush: nil, limit: nil, ttl: nil)  # TESTED
    query = { "collection": @collection }
    body = {
      "count" => count,
      "restrict" => restrict,
      "batchSize" => batchSize,
      "flush" => flush,
      "limit" => limit,
      "ttl" => ttl
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/export", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    return @@verbose ? result : result["errorMessage"] if result["error"]
    @countExport = result["count"]
    @hasMoreExport = result["hasMore"]
    @idExport = result["id"]
    if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
      result = result["result"]
    else
      result = result["result"].map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, database: @database, body: x)}
    end
    result
  end

  def exportNext  # TESTED
    unless @hasMoreExport
      print "No other results"
    else
      query = { "collection": @collection }
      request = @@request.merge({ :query => query })
      result = self.class.put("/_db/#{@database}/_api/cursor/#{@idExport}", request)
      return result.headers["x-arango-async-id"] if @@async == "store"
      return true if @@async
      result = result.parsed_response
      return @@verbose ? result : result["errorMessage"] if result["error"]
      @countExport = result["count"]
      @hasMoreExport = result["hasMore"]
      @idExport = result["id"]
      if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        result = result["result"]
      else
        result = result["result"].map{|x| ArangoDocument.new(key: x["_key"], collection: @collection, database: @database, body: x)}
      end
      result
    end
  end

# === INDEXES ===

  # def retrieveIndex(id:)  # TESTED
  #   result = self.class.get("/_db/#{@database}/_api/index/#{@collection}/#{id}", @@request)
  #   if @@async == "store"
  #     result.headers["x-arango-async-id"]
  #   else
  #     result = result.parsed_response
  #     if @@verbose
  #       result
  #     else
  #       if result["error"]
  #         result["errorMessage"]
  #       else
  #         ArangoIndex.new(body: result, id: result["id"], database: @database, collection: @collection, type: result["type"], unique: result["unique"], fields: result["fields"])
  #       end
  #     end
  #   end
  # end

  def indexes  # TESTED
    query = { "collection": @collection }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/index", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    return result if @@verbose
    return result["errorMessage"] if result["error"]
    result.delete_if{|k,v| k == "error" || k == "code"}
    result["indexes"] = result["indexes"].map{|x| ArangoIndex.new(body: x, id: x["id"], database: @database, collection: @collection, type: x["type"], unique: x["unique"], fields: x["fields"])}
    result
  end

  def createIndex(body: {}, unique: nil, type:, fields:, id: nil) # TESTED
    body["fields"] = fields.is_a?(Array) ? fields : [fields]
    body["unique"] = unique unless unique.nil?
    body["type"] = type unless type.nil?
    body["id"] = id unless type.nil?
    query = { "collection": @collection }
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = self.class.post("/_db/#{@database}/_api/index", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoIndex.new(body: result, id: result["id"], database: @database, collection: @collection, type: result["type"], unique: result["unique"], fields: result["fields"])
  end
  #
  # def deleteIndex(id:) # TESTED
  #   result = self.class.delete("/_db/#{@database}/_api/index/#{@collection}/#{id}", @@request)
  #   if @@async == "store"
  #     result.headers["x-arango-async-id"]
  #   else
  #     result = result.parsed_response
  #     if @@verbose
  #       result
  #     else
  #       if result["error"]
  #         result["errorMessage"]
  #       else
  #         true
  #       end
  #     end
  #   end
  # end

# === REPLICATION ===

  def data(from: nil, to: nil, chunkSize: nil, includeSystem: false, failOnUnknown: nil, ticks: nil, flush: nil) # TESTED
    query = {
      "collection": @collection,
      "from": from,
      "to": to,
      "chunkSize": chunkSize,
      "includeSystem": includeSystem,
      "failOnUnknown": failOnUnknown,
      "ticks": ticks,
      "flush": flush
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/dump", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result
  end

# === UTILITY ===

  def return_result(result:, caseTrue: false, key: nil, checkType: false)
    return result.headers["x-arango-async-id"] if @@async == "store"
    return true if @@async
    result = result.parsed_response
    if @@verbose || !result.is_a?(Hash)
      resultTemp = result
      unless result["errorMessage"]
        result.delete_if{|k,v| k == "error" || k == "code"}
        @body = result
        @type = result["type"] == 2 ? "Document" : "Edge" if(checkType)
      end
      resultTemp
    else
      return result["errorMessage"] if result["error"]
      return true if caseTrue
      result.delete_if{|k,v| k == "error" || k == "code"}
      @body = result
      @type = result["type"] == 2 ? "Document" : "Edge" if(checkType)
      key.nil? ? self : result[key]
    end
  end
end
