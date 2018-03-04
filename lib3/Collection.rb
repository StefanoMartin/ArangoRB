# === COLLECTION ===

module Arango
  class Collection
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(name:, database:, graph: nil, body: {}, type: "Document",
      isSystem: nil)
      @name = name
      assign_database(database)
      assign_graph(graph)
      assign_type(type)
      body["type"]     ||= type == "Document" ? 2 : 3
      body["status"]   ||= nil
      body["isSystem"] ||= isSystem
      body["id"]       ||= nil
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :status, :isSystem, :id, :server, :database, :graph, :type,
     :countExport, :hasMoreExport, :idExport, :hasMoreSimple, :idSimple
    attr_accessor :name

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph, NilClass])
      if !graph.nil? && graph.database.name != @database.name
        raise Arango::Error.new message: "Database of graph is not the same as the class"
      end
      @graph = graph
    end
    alias assign_graph graph=

    def body=(result)
      @body     = result
      @name     = result["name"] || @name
      @type     = assign_type(result["type"])
      @status   = reference_status(result["status"])
      @id       = result["id"] || @id
      @isSystem = result["isSystem"] || @isSystem
    end
    alias assign_attributes body=

    def type=(type)
      type ||= @type
      satisfy_category?(type, ["Document", "Edge", 2, 3, nil])
      type = case type
      when 2, "Document", nil
        "Document"
      when 3, "Edge"
        "Edge"
      end
      @type = type
    end
    alias assign_type type=

    def reference_status(number)
      number ||= @number
      return nil if number.nil?
      hash = ["new born collection", "unloaded", "loaded",
        "in the process of being unloaded", "deleted", "loading"]
      return hash[number-1]
    end
    private :reference_status

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name"     => @name,
        "type"     => @type,
        "status"   => @status,
        "id"       => @id,
        "isSystem" => @isSystem,
        "body"     => @body
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === GET ===

    def retrieve
      result = @database.request(action: "GET", url: "_api/collection/#{@name}")
      return_element(result)
    end

    def properties
      @database.request(action: "GET", url: "_api/collection/#{@name}/properties")
    end

    def count
      @database.request(action: "GET", url: "_api/collection/#{@name}/count",
        key: "count")
    end

    def statistics
      @database.request(action: "GET", url: "_api/collection/#{@name}/figures",
        key: "figures")
    end

    def revision
      @database.request(action: "GET", url: "_api/collection/#{@name}/revision",
        key: "revision")
    end

    def checksum(withRevisions: nil, withData: nil)
      query = {
        "withRevisions": withRevisions,
        "withData": withData
      }
      @database.request(action: "GET", query: query,
        url: "_api/collection/#{@name}/checksum", key: "checksum")
    end

# == POST ==

    def create(journalSize: nil, replicationFactor: nil,
      allowUserKeys: nil, typeKeyGenerator: nil, incrementKeyGenerator: nil,
      offsetKeyGenerator: nil, waitForSync: nil, doCompact: nil,
      isVolatile: nil, shardKeys: nil, numberOfShards: nil,
      isSystem: @isSystem, type: @type, indexBuckets: nil, distributeShardsLike: nil)
      satisfy_category?(typeKeyGenerator, [nil, "traditional", "autoincrement"])
      satisfy_category?(type, ["Edge", "Document", 2, 3, nil])
      keyOptions = {
        "allowUserKeys" => allowUserKeys,
        "type"          => typeKeyGenerator,
        "increment"     => incrementKeyGenerator,
        "offsetKeyGenerator" => offsetKeyGenerator
      }.delete_if{|k,v| v.nil?}
      keyOptions = nil if keyOptions.empty?
      type = case type
      when 2, "Document", nil
        2
      when 3, "Edge"
        3
      end
      body = {
        "name" => @name,
        "type" => type,
        "replicationFactor" => replicationFactor,
        "journalSize"       => journalSize,
        "keyOptions"        => keyOptions,
        "waitForSync"       => waitForSync,
        "doCompact"         => doCompact,
        "isVolatile"        => isVolatile,
        "shardKeys"         => shardKeys,
        "numberOfShards"    => numberOfShards,
        "isSystem"          => isSystem,
        "indexBuckets"      => indexBuckets,
        "distributeShardsLike" => distributeShardsLike
      }
      body = @body.merge(body)
      result = @database.request(action: "POST", url: "_api/collection", body: body)
      return_element(result)
    end

# === DELETE ===

    def destroy
      @database.request(action: "DELETE", url: "_api/collection/#{@name}")
    end

    def truncate
      result = @database.request(action: "PUT", url: "_api/collection/#{@name}/truncate")
      return_element(result)
    end

# === MODIFY ===

    def load
      result = @database.request(action: "PUT", url: "_api/collection/#{@name}/load")
      return_element(result)
    end

    def unload
      result = @database.request(action: "PUT", url: "_api/collection/#{@name}/unload")
      return_element(result)
    end

    def loadIndexesIntoMemory
      @database.request(action: "PUT", url: "_api/collection/#{@name}/loadIndexesIntoMemory")
      return true
    end

    def change(waitForSync: nil, journalSize: nil)
      body = {
        "journalSize" => journalSize,
        "waitForSync" => waitForSync
      }
      result = @database.request(action: "PUT", url: "_api/collection/#{@name}/properties")
      return_element(result)
    end

    def rename(newName:)
      body = { "name" => newName }
      result = @database.request(action: "PUT", body: body,
        url: "_api/collection/#{@name}/rename")
      return_element(result)
    end

    def rotate
      @database.request(action: "PUT", url: "_api/collection/#{@name}/rotate")
      return true
    end

# == DOCUMENT ==

    def [](document_name)
      Arango::Document.new(name: document_name, collection: self)
    end

    def document(name: nil, body: {}, rev: nil, from: nil, to: nil)
      Arango::Document.new(name: name, collection: self, body: body, rev: rev,
        from: from, to: to)
    end

    def documents(type: "document") # "path", "id", "key"
      @returnDocument = false
      if type == "document"
        @returnDocument = true
        type = "key"
      end
      satisfy_category?(type, ["path", "id", "key", "document"])
      body = { "type" => type, "collection" => @name }
      result = @database.request(action: "PUT", body: body,
        url: "_api/simple/all-keys")
      @hasMoreSimple = result["hasMore"]
      @idSimple = result["id"]
      return result if return_directly?(result)
      return result["result"] unless @returnDocument
      if @returnDocument
        result["result"].map do |key|
          Arango::Document.new(name: key, collection: self)
        end
      end
    end

    def next
      if @hasMoreSimple
        result = @database.request(action: "PUT", url: "_api/cursor/#{@idSimple}")
        @hasMoreSimple = result["hasMore"]
        @idSimple = result["id"]
        return result if return_directly?(result)
        return result["result"] unless @returnDocument
        if @returnDocument
          result["result"].map do |key|
            Arango::Document.new(name: key, collection: self)
          end
        end
      else
        raise Arango::Error.new message: "No other results"
      end
    end

    def return_body(x, type="Document")
      satisfy_class?(x, [Hash, Arango::Document, Arango::Edge, Arango::Vertex])
      body = case x
      when Hash
        x
      when Arango::Document
        if (type == "Vertex"  && x.type == "Edge")  ||
           (type == "Document" && x.type == "Edge") ||
           (type == "Edge" && x.type == "Document") ||
           (type == "Edge" && x.type == "Vertex")
          raise Arango::Error.new message: "#{x.name} is not a #{type}"
        end
        x.body
      when Arango::Edge, Arango::Vertex
        if (x.is_a?(Arango::Edge) && type == "Vertex") ||
           (x.is_a?(Arango::Vertex) && type == "Edge")
          raise Arango::Error.new message: "#{x.name} is not a #{type}"
        end
        x.body
      end
      return body
    end
    private :return_body

    def return_id(x)
      satisfy_class?(x, [String, Arango::Document, Arango::Vertex])
      return x.is_a?(String) ? x : x.id
    end
    private :return_id

    def createDocuments(document: [], waitForSync: nil, returnNew: nil,
      silent: nil)
      document = [document] unless document.is_a? Array
      document = document.map{|x| return_body(x)}
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "silent"      => silent
      }
      results = @database.request(action: "POST", body: document,
        query: query, url: "_api/document/#{@name}" )
      return results if return_directly?(results) || silent
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result["_key"], collection: self,
          body: real_body)
      end
    end

    def createEdges(document: {}, from:, to:, waitForSync: nil, returnNew: nil)
      edges = []
      from = [from] unless from.is_a? Array
      to   = [to]   unless to.is_a? Array
      document = [document] unless document.is_a? Array
      document = document.map{|x| return_body(x, "Edge")}
      from = from.map{|x| return_id(x)}
      to   = to.map{|x| return_id(x)}
      document.each do |b|
        from.each do |f|
          to.each do |t|
            b["_from"] = f
            b["_to"] = t
            edges << b.clone
          end
        end
      end
      create_documents(body: document, waitForSync: waitForSync,
        returnNew: returnNew, silent: silent)
    end

    def replaceDocuments(document: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil)
      document = document.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "returnOld"   => returnOld,
        "ignoreRevs"  => ignoreRevs
      }
      result = @database.request(action: "PUT", body: document,
        query: query, url: "_api/document/#{@name}")
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew == true
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result["_key"], collection: self,
          body: real_body)
      end
    end

    def updateDocuments(document: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil, keepNull: nil,
      mergeObjects: nil)
      document = document.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "returnOld"   => returnOld,
        "ignoreRevs"  => ignoreRevs,
        "keepNull"    => keepNull,
        "mergeObject" => mergeObjects
      }
      result = @database.request(action: "PATCH", body: document,
        query: query, url: "_api/document/#{@name}", keepNull: keepNull)
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result["_key"], collection: self,
          body: real_body)
      end
    end

    def destroyDocuments(document: {}, waitForSync: nil, returnOld: nil,
      ignoreRevs: nil)
      document = document.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnOld"   => returnOld,
        "ignoreRevs"  => ignoreRevs
      }
      @database.request(action: "DELETE",
        url: "_api/document/#{@id}", query: query)
    end

# == SIMPLE ==

    def generic_document_search(url, body, single=false)
      result = @database.request(action: "PUT", url: url, body: body)
      @returnDocument = true
      @hasMoreSimple = result["hasMore"]
      @idSimple = result["id"]
      return result if return_directly?(result)

      if single
        Arango::Document.new(name: result["document"]["_key"], collection: self,
          body:  result["document"])
      else
        result["result"].map do |x|
          Arango::Document.new(name: x["_key"], collection: self, body: x)
        end
      end
    end
    private :generic_document_search

    def allDocuments(skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @name,
        "skip"       => skip,
        "limit"      => limit,
        "batchSize"  => batchSize
      }
      generic_document_search("_api/simple/all", body)
    end

    def documentsMatch(match:, skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @name,
        "example"    => match,
        "skip"       => skip,
        "limit"      => limit,
        "batchSize"  => batchSize
      }
      generic_document_search("_api/simple/by-example", body)
    end

    def documentMatch(match:)
      body = {
        "collection" => @name,
        "example"    => match
      }
      generic_document_search("_api/simple/first-example", body, true)
    end

    def documentByKeys(keys:)
      keys = [keys] unless keys.is_a?(Array)
      keys = keys.map do |x|
        x.is_a?(Arango::Document) ? x.name : x
      end
      body = { "collection" => @name, "keys" => keys }
      @database.request(action: "PUT", url: "_api/simple/lookup-by-keys",
        body: body)
      return result if return_directly?(result)
      result["documents"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

    def documentByName(names:)
      documentByKeys(keys: names)
    end

    def random
      body = { "collection" => @name }
      generic_document_search("_api/simple/any", body, true)
    end

    def removeByKeys(keys:, returnOld: nil, silent: nil, waitForSync: nil)
      options = {
        "returnOld"   => returnOld,
        "silent"      => silent,
        "waitForSync" => waitForSync
      }.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      if keys.is_a? Array
        keys = keys.map do |x|
          x.is_a?(String) ? x : x.key
        end
      end
      body = { "collection" => @name, "keys" => keys, "options" => options }
      result = @database.request(action: "PUT",
        url: "_api/simple/remove-by-keys", body: body)
      return result if return_directly?(result)
      if returnOld == true && silent != true
        result.each do |r|
          Arango::Document.new(name: r["_key"], collection: self, body: r)
        end
      else
        return result
      end
    end

    def documentByName(names:, returnOld: nil, silent: nil, waitForSync: nil)
      documentByKeys(keys: names, returnOld: returnOld, silent: silent,
        waitForSync: waitForSync)
    end

    def removeMatch(match:, limit: nil, waitForSync: nil)
      options = {
        "limit"       => limit,
        "waitForSync" => waitForSync
      }.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example"    => match,
        "options"    => options
      }
      @database.request(action: "PUT",
        url: "_api/simple/remove-by-example", body: body, key: "deleted")
    end

    def replaceMatch(match:, newValue:, limit: nil, waitForSync: nil)
      options = {
        "limit"       => limit,
        "waitForSync" => waitForSync
      }.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example"    => match,
        "options"    => options,
        "newValue"   => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/replace-by-example", body: body, key: "replaced")
    end

    def updateMatch(match:, newValue:, keepNull: nil, mergeObjects: nil,
      limit: nil, waitForSync: nil)
      options = {
        "keepNull"     => keepNull,
        "mergeObjects" => mergeObjects,
        "limit"        => limit,
        "waitForSync"  => waitForSync
      }.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example"    => match,
        "options"    => options,
        "newValue"   => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/update-by-example", body: body, key: "updated")
    end

# === SIMPLE DEPRECATED ===

    def range(right:, attribute:, limit: nil, closed: true, skip: nil, left:,
      warning: @server.warning)
      warning_deprecated(warning, "range")
      body = {
        "right"      => right,
        "attribute"  => attribute,
        "collection" => @name,
        "limit"  => limit,
        "closed" => closed,
        "skip"   => skip,
        "left"   => left
      }
      result = @database.request(action: "PUT", url: "_api/simple/range",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

    def near(distance: nil, longitude:, latitude:, geo: nil, limit: nil,
      skip: nil, warning: @server.warning)
      warning_deprecated(warning, "near")
      body = {
        "distance"   => distance,
        "longitude"  => longitude,
        "collection" => @name,
        "limit"    => limit,
        "latitude" => latitude,
        "skip" => skip,
        "geo"  => geo
      }
      result = @database.request(action: "PUT", url: "_api/simple/near",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

    def within(distance: nil, longitude:, latitude:, radius:, geo: nil,
      limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "within")
      body = {
        "distance"   => distance,
        "longitude"  => longitude,
        "collection" => @name,
        "limit"    => limit,
        "latitude" => latitude,
        "skip"   => skip,
        "geo"    => geo,
        "radius" => radius
      }
      result = @database.request(action: "PUT", url: "_api/simple/within",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

    def withinRectangle(longitude1:, latitude1:, longitude2:, latitude2:,
      geo: nil, limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "withinRectangle")
      body = {
        "longitude1" => longitude1,
        "latitude1"  => latitude1,
        "longitude2" => longitude2,
        "latitude2"  => latitude2,
        "collection" => @name,
        "limit"  => limit,
        "skip"   => skip,
        "geo"    => geo,
        "radius" => radius
      }
      result = @database.request(action: "PUT",
        url: "_api/simple/within-rectangle", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

    def fulltext(index:, attribute:, query:, limit: nil, skip: nil,
      warning: @server.warning)
      warning_deprecated(warning, "fulltext")
      body = {
        "index"     => index,
        "attribute" => attribute,
        "query" => query,
        "limit" => limit,
        "skip"  => skip
      }
      result = @database.request(action: "PUT",
        url: "_api/simple/fulltext", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(name: x["_key"], collection: self, body: x)
      end
    end

  # === IMPORT ===

    def import(attributes:, values:, fromPrefix: nil,
      toPrefix: nil, overwrite: nil, waitForSync: nil,
      onDuplicate: nil, complete: nil, details: nil)
      satisfy_category?(onDuplicate, [nil, "error", "update", "replace", "ignore"])
      satisfy_category?(overwrite, [nil, "yes", "true", true])
      satisfy_category?(complete, [nil, "yes", "true", true])
      satisfy_category?(details, [nil, "yes", "true", true])
      query = {
        "collection"  => @name,
        "fromPrefix"  => fromPrefix,
        "toPrefix"    => toPrefix,
        "overwrite"   => overwrite,
        "waitForSync" => waitForSync,
        "onDuplicate" => onDuplicate,
        "complete"    => complete,
        "details"     => details
      }
      body = "#{attributes}\n"
      values[0].is_a?(Array) ? values.each{|x| body += "#{x}\n"} : body += "#{values}\n"
      @database.request(action: "POST", url: "_api/import", query: query,
        body: body.to_json, skip_to_json: true)
    end

    def importJSON(body:, type: "auto", fromPrefix: nil,
      toPrefix: nil, overwrite: nil, waitForSync: nil,
      onDuplicate: nil, complete: nil, details: nil)
      satisfy_category?(type, ["auto", "list", "documents"])
      satisfy_category?(onDuplicate, [nil, "error", "update", "replace", "ignore"])
      satisfy_category?(overwrite, [nil, "yes", "true", true])
      satisfy_category?(complete, [nil, "yes", "true", true])
      satisfy_category?(details, [nil, "yes", "true", true])
      query = {
        "collection"  => @collection,
        "type"        => type,
        "fromPrefix"  => fromPrefix,
        "toPrefix"    => toPrefix,
        "overwrite"   => overwrite,
        "waitForSync" => waitForSync,
        "onDuplicate" => onDuplicate,
        "complete"    => complete,
        "details"     => details
      }
      @database.request(action: "POST", url: "_api/import", query: query,
        body: body.to_json, skip_to_json: true)
    end

  # === EXPORT ===

    def export(count: nil, restrict: nil, batchSize: nil,
      flush: nil, flushWait: nil, limit: nil, ttl: nil)
      query = { "collection" => @name }
      body = {
        "count"     => count,
        "restrict"  => restrict,
        "batchSize" => batchSize,
        "flush"     => flush,
        "flushWait" => flushWait,
        "limit"     => limit,
        "ttl"       => ttl
      }
      result = @database.request(action: "POST", url: "_api/export", body: body,
        query: query)
      return reuslt if @server.async != false
      @countExport   = result["count"]
      @hasMoreExport = result["hasMore"]
      @idExport      = result["id"]
      if return_directly?(result) || result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key")
        return result["result"]
      else
        return result["result"].map do |x|
          Arango::Document.new(name: x["_key"], collection: self, body: x)
        end
      end
    end

    def exportNext
      unless @hasMoreExport
        raise Arango::Error.new message: "No other results"
      else
        query = { "collection" => @name }
        result = @database.request(action: "PUT",
          url: "_api/export/#{@idExport}", query: query)
        return reuslt if @server.async != false
        @countExport   = result["count"]
        @hasMoreExport = result["hasMore"]
        @idExport      = result["id"]
        if return_directly?(result) || result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key")
          return result["result"]
        else
          return result["result"].map do |x|
            Arango::Document.new(name: x["_key"], collection: self, body: x)
          end
        end
      end
    end

# === INDEXES ===

    def index(body: {}, id: nil, type: "hash", unique: nil, fields:,
      sparse: nil, geoJson: nil, minLength: nil, deduplicate: nil)
      Arango::Index.new(collection: self, body: body, id: id, type: type,
        unique: unique, fields: fields, sparse: sparse, geoJson: geoJson,
        minLength: minLength, deduplicate: deduplicate)
    end

    def indexes
      query = { "collection" => @name }
      result = @database.request(action: "GET", url: "/_api/index",
        query: query)
      return result if return_directly?(result)
      result["indexes"].map do |x|
        Arango::Index.new(body: x, id: x["id"], collection: self,
          type: x["type"], unique: x["unique"], fields: x["fields"],
          sparse: x["sparse"])
      end
    end

# === REPLICATION ===

    def data(batchId: nil, from: nil, to: nil, chunkSize: nil,
      includeSystem: nil, failOnUnknown: nil, ticks: nil, flush: nil)
      query = {
        "collection" => @name,
        "batchId"    => batchId,
        "from"       => from,
        "to"         => to,
        "chunkSize"  => chunkSize,
        "includeSystem" => includeSystem,
        "failOnUnknown" => failOnUnknown,
        "ticks" => ticks,
        "flush" => flush
      }
      @database.request(action: "GET", url: "_api/replication/dump",
        query: query)
    end
    alias dump data

# === USER ACCESS ===

    def check_user(user)
      user = Arango::User.new(user: user) if user.is_a?(String)
      return user
    end
    private :check_user

    def addUserAccess(grant:, user:)
      user = check_user(user)
      user.add_collection_access(grant: grant, database: @database.name,
        collection: @name)
    end

    def revokeUserAccess(user:)
      user = check_user(user)
      user.clear_collection_access(database: @database.name, collection: @name)
    end

    def userAccess(user:)
      user = check_user(user)
      user.collection_access(database: @database.name, collection: @name)
    end

# === GRAPH ===

    def vertex(name: nil, body: {}, rev: nil, from: nil, to: nil)
      if @type == "Edge"
        raise Arango::Error.new message: "This class is an Edge class"
      end
      if @graph.nil?
        Arango::Document.new(name: name, body: body, rev: rev, collection: self)
      else
        Arango::Vertex.new(name: name, body: body, rev: rev, collection: self)
      end
    end

    def edge(name: nil, body: {}, rev: nil, from: nil, to: nil)
      if @type == "Document"
        raise Arango::Error.new message: "This class is a Document/Vertex class"
      end
      if @graph.nil?
        Arango::Document.new(name: name, body: body, rev: rev, collection: self)
      else
        Arango::Edge.new(name: name, body: body, rev: rev, from: from, to: to,
          collection: self)
      end
    end
  end
end
