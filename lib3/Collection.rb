# === COLLECTION ===

module Arango
  class Collection
    include Helper_Error
    include Meta_prog
    include Helper_Return

    def initialize(name:, database:, graph: nil, body: {}, type: "Document")
      satisfy_class?(database, [Arango::Database])
      satisfy_class?(graph, [Arango::Graph, Arango::NilClass])
      satisfy_category?(type, ["Document", "Edge"])
      @name = name
      @database = database
      @client = @database.client
      if !graph.nil? && @graph.database.name != @database.name
        raise Arango::Error.new message: "Database of graph is not the same as the class"
      end
      @graph = graph
      body["type"] ||= type == "Document" ? 2 : 3
      body["status"] ||= nil
      body["isSystem"] ||= nil
      body["id"] ||= nil
      assign_attributes(body)
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :status, :isSystem, :id, :client, :body, :database, :graph
    attr_accessor :name

    def database=(database)
      satisfy_class?(database, [Arango::Database])
      @database = database
      @client = @database.client
    end

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph, Arango::NilClass])
      if !graph.nil? && @graph.database.name != @database.name
        raise Arango::Error.new message: "Database of graph is not the same as the class"
      end
      @graph = graph
    end

    def body=(body)
      assign_attributes(body)
    end

    def type=(type)
      satisfy_category?(type, ["Document", "Edge"])
      @type = type
      @body["type"] = type == "Document" ? 2 : 3
    end

    def to_h(level=0)
      hash = {
        "name" => @name,
        "type" => @type,
        "body" => @body,
        "status" => @status,
        "id" => @id,
        "isSystem" => @isSystem
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === PRIVATE ===

    def reference_status(number)
      return nil if number.nil?
      hash = ["new born collection", "unloaded", "loaded",
        "in the process of being unloaded", "deleted", "loading"]
      return hash[number-1]
    end

    def assign_attributes(result)
      @body = result
      @name = result["name"]
      @type = result["type"] == 2 ? "Document" : "Edge"
      @status = reference_status(result["status"])
      @id = result["id"]
      @name = result["name"]
      @isSystem = result["isSystem"]
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
      allowUserKeys: nil, typeKeyGenerator: nil,
      incrementKeyGenerator: nil, offsetKeyGenerator: nil,
      waitForSync: nil, doCompact: nil,
      isVolatile: nil, shardKeys: nil, numberOfShards: nil,
      isSystem: nil, type: @type, indexBuckets: nil, distributeShardsLike: nil)
      satisfy_category?(typeKeyGenerator, [nil, "traditional", "autoincrement"])
      satisfy_category?(type, ["Edge", "Document", 2, 3, nil])
      keyOptions = {
        "allowUserKeys" => allowUserKeys,
        "type" => typeKeyGenerator,
        "increment" => incrementKeyGenerator,
        "offsetKeyGenerator" => offsetKeyGenerator
      }.delete_if{|k,v| v.nil?}
      keyOptions = nil if keyOptions.empty?
      satisfy_class?()
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
        "journalSize" => journalSize,
        "keyOptions" => keyOptions,
        "waitForSync" => waitForSync,
        "doCompact" => doCompact,
        "isVolatile" => isVolatile,
        "shardKeys" => shardKeys,
        "numberOfShards" => numberOfShards,
        "isSystem" => isSystem,
        "indexBuckets" => indexBuckets,
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

    def load_indexes_into_memory
      @database.request(action: "PUT", url: "_api/collection/#{@name}/loadIndexesIntoMemory")
    return true
    end

    def change(waitForSync: nil, journalSize: nil)
      body = {
        "journalSize" => journalSize,
        "waitForSync" => waitForSync
      }
      result = @database.request(action: "PUT",
        url: "_api/collection/#{@name}/properties")
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
      Arango::Document.new(key: document_name, collection: self)
    end

    def document(key:, body: {}, rev: nil)
      Arango::Document.new(key: key, collection: self, body: body, rev: rev, from: nil, to: nil)
    end

    def documents(type: nil) # "path", "id", "key"
      val = type.nil?
      type ||= "key"
      satisfy_category?(type, ["path", "id", "key", nil], "type")
      body = { "type" => type }
      result = @database.request(action: "PUT", body: body, url: "_api/collection/#{@name}/simple/all-keys")
      return result if return_directly?(result)
      if val
        result["result"].map do |key|
          Arango::Document.new(key: key, collection: self)
        end
      else
        result
      end
    end

    def create_documents(body: [], waitForSync: nil, returnNew: nil,
      silent: nil)
      body = body.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnNew" => returnNew,
        "silent" => silent
      }
      results = @database.request(action: "POST", body: body,
        query: query, url: "_api/document/#{@name}" )
      return results if return_directly?(result) || silent
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew == true
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = body[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(key: result["_key"], collection: self,
          body: real_body)
      end
    end

    def replace_documents(body: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil)
      body = body.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnNew" => returnNew,
        "returnOld" => returnOld,
        "ignoreRevs" => ignoreRevs
      }
      result = @database.request(action: "PUT", body: body,
        query: query, url: "_api/document/#{@name}")
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew == true
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = body[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(key: result["_key"], collection: self,
          body: real_body)
      end
    end

    def update_documents(body: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil, keepNull: nil,
      mergeObjects: nil)
      body = body.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnNew" => returnNew,
        "returnOld" => returnOld,
        "ignoreRevs" => ignoreRevs,
        "keepNull" => keepNull,
        "mergeObject" => mergeObjects
      }
      result = @database.request(action: "PATCH", body: body,
        query: query, url: "_api/document/#{@name}")
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew == true
          body2.delete("new")
          body2 = body2.merge(result["new"])
        end
        real_body = body[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(key: result["_key"], collection: self,
          body: real_body)
      end
    end

    def destroy_documents(body: {}, waitForSync: nil, returnOld: nil, ignoreRevs: nil)
      body = body.each do |x|
        x = x.body if x.is_a?(Arango::Document)
      end
      query = {
        "waitForSync" => waitForSync,
        "returnOld" => returnOld,
        "ignoreRevs" => ignoreRevs
      }
      @database.request(action: "DELETE",
        url: "_api/document/#{@id}", query: query)
    end

# == SIMPLE ==

    def generic_document_search(url, body, single=false)
      result = @database.request(action: "PUT", url: url, body: body)
      return result if return_directly?(result)
      if single
        Arango::Document.new(key: result["document"]["_key"], collection: self,
          body:  result["document"])
      else
        result["result"].map do |x|
          Arango::Document.new(key: x["_key"], collection: self, body: x)
        end
      end
    end
    private :generic_document_search

    def allDocuments(skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @name,
        "skip" => skip,
        "limit" => limit,
        "batchSize" => batchSize
      }
      generic_document_search("_api/simple/all", body)
    end

    def documentsMatch(match:, skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection" => @name,
        "example" => match,
        "skip" => skip,
        "limit" => limit,
        "batchSize" => batchSize
      }
      generic_document_search("_api/simple/by-example", body)
    end

    def documentMatch(match:)
      body = {
        "collection" => @name,
        "example" => match
      }
      generic_document_search("_api/simple/first-example", body, true)
    end

    def documentByKeys(keys:)
      if keys.is_a? Array
        keys = keys.map do |x|
          x.is_a?(Arango::Document) ? x.key : x
        end
      end
      keys = [keys] if keys.is_a? String
      body = { "collection" => @name, "keys" => keys }
      @database.request(action: "PUT", url: "_api/simple/lookup-by-keys",
        body: body)
      return result if return_directly?(result)
      result["documents"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def random
      body = { "collection" => @name }
      generic_document_search("_api/simple/any", body, true)
    end

    def removeByKeys(keys:, returnOld: nil, silent: nil, waitForSync: nil)
      options = {"returnOld" => returnOld, "silent" => silent,
        "waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
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
          Arango::Document.new(key: r["_key"], collection: self, body: r)
        end
      else
        return result
      end
    end

    def removeMatch(match:, limit: nil, waitForSync: nil)
      options = {"limit" => limit,
        "waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options
      }
      @database.request(action: "PUT",
        url: "_api/simple/remove-by-example", body: body, key: "deleted")
    end

    def replaceMatch(match:, newValue:, limit: nil, waitForSync: nil)
      options = {"limit" => limit,
        "waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/replace-by-example", body: body, key: "replaced")
    end

    def updateMatch(match:, newValue:, keepNull: nil, mergeObjects: nil, limit: nil,
      waitForSync: nil)
      options = {"keepNull" => keepNull,
        "mergeObjects" => mergeObjects, "limit" => limit,
        "waitForSync" => waitForSync}.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/update-by-example", body: body, key: "updated")
    end

# === SIMPLE DEPRECATED ===

    def range(right:, attribute:, limit: nil, closed: true, skip: nil, left:,
      warning: @client.warning)
      warning_deprecated(warning, "range")
      body = {
        "right" => right,
        "attribute" => attribute,
        "collection" => @name,
        "limit" => limit,
        "closed" => closed,
        "skip" => skip,
        "left" => left
      }
      result = @database.request(action: "PUT", url: "_api/simple/range",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def near(distance: nil, longitude:, latitude:, geo: nil, limit: nil, skip: nil,
      warning: @client.warning)
      warning_deprecated(warning, "near")
      body = {
        "distance" => distance,
        "longitude" => longitude,
        "collection" => @name,
        "limit" => limit,
        "latitude" => latitude,
        "skip" => skip,
        "geo" => geo
      }
      result = @database.request(action: "PUT", url: "_api/simple/near",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def within(distance: nil, longitude:, latitude:, radius:, geo: nil, limit: nil,
      skip: nil, warning: @client.warning)
      warning_deprecated(warning, "within")
      body = {
        "distance" => distance,
        "longitude" => longitude,
        "collection" => @name,
        "limit" => limit,
        "latitude" => latitude,
        "skip" => skip,
        "geo" => geo,
        "radius" => radius
      }
      result = @database.request(action: "PUT", url: "_api/simple/within",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def withinRectangle(longitude1:, latitude1:, longitude2:, latitude2:,
      geo: nil, limit: nil, skip: nil, warning: @client.warning)
      warning_deprecated(warning, "withinRectangle")
      body = {
        "longitude1" => longitude1,
        "latitude1" => latitude1,
        "longitude2" => longitude2,
        "latitude2" => latitude2,
        "collection" => @name,
        "limit" => limit,
        "skip" => skip,
        "geo" => geo,
        "radius" => radius
      }
      result = @database.request(action: "PUT",
        url: "_api/simple/within-rectangle", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def fulltext(index:, attribute:, query:, limit: nil, skip: nil,
      warning: @client.warning)
      warning_deprecated(warning, "fulltext")
      body = {
        "index" => index,
        "attribute" => attribute,
        "query" => query,
        "limit" => limit,
        "skip" => skip
      }
      result = @database.request(action: "PUT",
        url: "_api/simple/fulltext", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
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
        "collection": @name,
        "fromPrefix": fromPrefix,
        "toPrefix": toPrefix,
        "overwrite": overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete": complete,
        "details": details
      }
      body = "#{attributes}\n"
      values[0].is_a?(Array) ? values.each{|x| body += "#{x}\n"} : body += "#{values}\n"
      @database.request(action: "POST", url: "_api/import", query: query, body: body.to_json, skip_to_json: true)
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
        "collection": @collection,
        "type": type,
        "fromPrefix": fromPrefix,
        "toPrefix": toPrefix,
        "overwrite": overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete": complete,
        "details": details
      }
      @database.request(action: "POST", url: "_api/import", query: query, body: body.to_json, skip_to_json: true)
    end

  # === EXPORT ===

    def export(count: nil, restrict: nil, batchSize: nil,
      flush: nil, flushWait: nil, limit: nil, ttl: nil)
      query = { "collection" => @name }
      body = {
        "count" => count,
        "restrict" => restrict,
        "batchSize" => batchSize,
        "flush" => flush,
        "flushWait" => flushWait,
        "limit" => limit,
        "ttl" => ttl
      }
      result = @database.request(action: "POST", url: "_api/export", body: body,
        query: query)
      return reuslt if @client.async != false
      @countExport = result["count"]
      @hasMoreExport = result["hasMore"]
      @idExport = result["id"]
      if return_directly?(result) || result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key")
        return result["result"]
      else
        return result["result"].map do |x|
          Arango::Document.new(key: x["_key"], collection: self, body: x)
        end
      end
    end

    def exportNext
      unless @hasMoreExport
        Arango::Error message: "No other results"
      else
        query = { "collection": @name }
        result = @database.request(action: "PUT", url: "_api/export/#{@idExport}",
          query: query)
        return reuslt if @client.async != false
        @countExport = result["count"]
        @hasMoreExport = result["hasMore"]
        @idExport = result["id"]
        if return_directly?(result) || result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key")
          return result["result"]
        else
          return result["result"].map do |x|
            Arango::Document.new(key: x["_key"], collection: self, body: x)
          end
        end
      end
    end

# === INDEXES ===

    def indexes
      Arango::Index.indexes(collection: self)
    end

# === REPLICATION ===

    def data(batchId: nil, from: nil, to: nil, chunkSize: nil,
      includeSystem: nil, failOnUnknown: nil, ticks: nil, flush: nil)
      query = {
        "collection": @name,
        "batchId": batchId,
        "from": from,
        "to": to,
        "chunkSize": chunkSize,
        "includeSystem": includeSystem,
        "failOnUnknown": failOnUnknown,
        "ticks": ticks,
        "flush": flush
      }
      @database.request(action: "GET", url: "_api/replication/dump", query: query)
    end
    alias dump data

# === USER ACCESS ===

    def check_user(user)
      if user.is_a?(String)
        user = Arango::User.new(user: user)
      end
      return user
    end

    def add_user_access(grant:, user:)
      user = check_user(user)
      user.add_collection_access(grant: grant, database: @database.name,
        collection: @name)
    end

    def clear_user_access(user:)
      user = check_user(user)
      user.clear_collection_access(database: @database.name, collection: @name)
    end

    def user_access(user:)
      user = check_user(user)
      user.collection_access(database: @database.name, collection: @name)
    end

# === GRAPH ===

    def vertex(name:, body: {}, rev: nil, from: nil, to: nil)
      if @graph.nil?
        raise Arango::Error.new message: "This class does not have any Graph assigned"
      end
      Arango::Vertex.new(name: name, body: body, rev: rev, collection: self, graph: @graph)
    end

    def vertex(name:, body: {}, rev: nil, from: nil, to: nil)
      if @graph.nil?
        raise Arango::Error.new message: "This class does not have any Graph assigned"
      end
      Arango::Edge.new(name: name, body: body, rev: rev, from: from, to: to, collection: self, graph: @graph)
    end
  end
end
