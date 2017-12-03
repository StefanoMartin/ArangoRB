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
  end
end
