# === COLLECTION ===

module Arango
  class Collection
    def initialize(name:, database:, body: {}, type: "Document")
      satisfy_class?(name, "name")
      satisfy_class?(database, "database", [Arango::Database])
      satisfy_class?(body, "body", [Hash])
      satisfy_category?(type, , "type", ["Document", "Edge"])
      @name = name
      @database = database
      @client = @database.client
      body["type"] ||= type == "Document" ? 2 : 3
      body["status"] ||= nil
      body["isSystem"] ||= nil
      body["id"] ||= nil
      assign_attributes(body)
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :name, :database, :body, :type, :status,
      :isSystem, :id, :client

    def to_h
      {
        "name" => @name,
        "database" => @database.name,
        "type" => @type,
        "body" => @body,
        "status" => @status,
        "id" => @id,
        "isSystem" => @isSystem
      }.delete_if{|k,v| v.nil?}
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

    def return_collection(result)
      return result if @database.client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end

# === GET ===

    def retrieve
      result = @database.request(action: "GET",
        url: "_api/collection/#{@name}")
      return_collection(result)
    end

    def properties
      @database.request(action: "GET",
        url: "_api/collection/#{@name}/properties")
    end

    def count
      @database.request(action: "GET",
        url: "_api/collection/#{@name}/count", key: "count")
    end

    def statistics
      @database.request(action: "GET",
        url: "_api/collection/#{@name}/figures", key: "figures")
    end

    def revision
      @database.request(action: "GET",
        url: "_api/collection/#{@name}/revision", key: "revision")
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
      keyOptions: nil, waitForSync: nil, doCompact: nil,
      isVolatile: nil, shardKeys: nil, numberOfShards: nil,
      isSystem: nil, type: @type, indexBuckets: nil)
      type = 3   if type == "Edge"
      type = nil if type == "Document"
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
        "indexBuckets" => indexBuckets
      }
      body = @body.merge(body)
      result = @database.request(action: "POST", url: "_api/collection", body: body)
      return_collection(result)
    end

# === DELETE ===

    def destroy
      @database.request(action: "DELETE",
        url: "_api/collection/#{@name}")
    end

    def truncate
      result = @database.request(action: "PUT",
        url: "_api/collection/#{@name}/truncate")
      return_collection(result)
    end

# === MODIFY ===

    def load
      result = @database.request(action: "PUT",
        url: "_api/collection/#{@name}/load")
      return_collection(result)
    end

    def unload
      result = @database.request(action: "PUT",
        url: "_api/collection/#{@name}/unload")
      return_collection(result)
    end

    def load_indexes_into_memory
      @database.request(action: "PUT", caseTrue: true,
        url: "_api/collection/#{@name}/loadIndexesIntoMemory")
    end

    def change(waitForSync: nil, journalSize: nil)
      body = {
        "journalSize" => journalSize,
        "waitForSync" => waitForSync
      }
      result = @database.request(action: "PUT",
        url: "_api/collection/#{@name}/properties")
      return_collection(result)
    end

    def rename(newName)
      body = { "name" => newName }
      result = @database.request(action: "PUT", body: body,
        url: "_api/collection/#{@name}/rename")
      return_collection(result)
    end

    def rotate
      @database.request(action: "PUT",
        url: "_api/collection/#{@name}/rotate", caseTrue: true)
    end

# == DOCUMENT ==

    def [](document_name)
      Arango::Document.new(key: document_name, collection: self)
    end

    def document(key:, body: {}, rev: nil)
      Arango::Document.new(key: key, collection: self, body: body, rev: rev)
    end

    def documents(type: nil) # "path", "id", "key"
      val = type.nil?
      type ||= "key"
      satisfy_category?(type, ["path", "id" "key", nil], "type")
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

    def create_documents(body: [], waitForSync: nil, returnNew: nil, silent: nil)
      satisfy_class?(body, "body", [Hash, Arango::Document], true)
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

    def replace_documents(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil)
      satisfy_class?(body, "body", [Hash, Arango::Document], true)
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
      satisfy_class?(body, "body", [Hash, Arango::Document], true)
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
      satisfy_class?(body, "body", [Hash, Arango::Document], true)
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
        Arango::Document.new(key: result["document"]["_key"], collection: self, body:  result["document"])
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
      generic_document_search("_api/simple/first-example",
        body, true)
    end

    def documentByKeys(keys:)
      keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(Arango::Document) ? x.key : nil} if keys.is_a? Array
      keys = [keys] if keys.is_a? String
      body = { "collection" => @name, "keys" => keys }
      @database.request(action: "PUT", url: "_api/simple/lookup-by-keys", body: body)
      return result if return_directly?(result)
      result["documents"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def random
      body = { "collection" => @name }
      generic_document_search("_api/simple/any",
        body, true)
    end

    def removeByKeys(keys:, options: nil)
      keys = keys.map{|x| x.is_a?(String) ? x : x.is_a?(ArangoDocument) ? x.key : nil}
      body = { "collection" => @name, "keys" => keys, "options" => options }
      @database.request(action: "PUT", url: "_api/simple/remove-by-keys",
        body: body, key: "removed")
    end

    def removeMatch(match:, options: nil)
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options
      }
      @database.request(action: "PUT",
        url: "_api/simple/remove-by-example", body: body, key: "deleted")
    end

    def replaceMatch(match:, newValue:, options: nil)
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/replace-by-example", body: body, key: "replaced")
    end

    def updateMatch(match:, keepNull:, newValue:, options: nil)
      body = {
        "collection" => @name,
        "example" => match,
        "options" => options,
        "newValue" => newValue
      }
      @database.request(action: "PUT", url: "_api/simple/update-by-example", body: body, key: "updated")
    end

# === SIMPLE DEPRECATED ===

    def range(right:, attribute:, limit: nil, closed:, skip: nil, left:, warning: true)
      puts "ARANGORB WARNING: range function is deprecated" if warning
      body = {
        "right" => right,
        "attribute" => attribute,
        "collection" => @name,
        "limit" => limit,
        "closed" => closed,
        "skip" => skip,
        "left" => left
      }
      result = @database.request(action: "PUT", url: "/_api/simple/range",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def near(distance: nil, longitude:, latitude:, geo: nil, limit: nil, skip: nil, warning: true)
      puts "ARANGORB WARNING: near function is deprecated" if warning
      body = {
        "distance" => distance,
        "longitude" => longitude,
        "collection" => @name,
        "limit" => limit,
        "latitude" => latitude,
        "skip" => skip,
        "geo" => geo
      }
      result = @database.request(action: "PUT", url: "/_api/simple/near",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def within(distance: nil, longitude:, latitude:, radius:, geo: nil, limit: nil, skip: nil, warning: true)
      puts "ARANGORB WARNING: within function is deprecated" if warning
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
      result = @database.request(action: "PUT", url: "/_api/simple/within",
        body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def withinRectangle(longitude1:, latitude1:, longitude2:, latitude2:, geo: nil, limit: nil, skip: nil, warning: true)
      puts "ARANGORB WARNING: withinRectangle function is deprecated" if warning
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
        url: "/_api/simple/within-rectangle", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end

    def fulltext(index:, attribute:, query:, limit: nil, skip: nil, warning: true)
      puts "ARANGORB WARNING: fulltext function is deprecated" if warning
      body = {
        "index" => index,
        "attribute" => attribute,
        "query" => query,
        "limit" => limit,
        "skip" => skip
      }
      result = @database.request(action: "PUT",
        url: "/_api/simple/fulltext", body: body)
      return result if return_directly?(result)
      result["result"].map do |x|
        Arango::Document.new(key: x["_key"], collection: self, body: x)
      end
    end
  end
end
