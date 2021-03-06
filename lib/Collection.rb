# === COLLECTION ===

module Arango
  class Collection
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache
        cache_name = "#{database.name}/#{hash[:name]}"
        cached = database.server.cache.cache.dig(:database, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:type, :isSystem].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(name:, database:, graph: nil, body: {}, type: :document,
      isSystem: nil, cache_name: nil)
      @name = name
      assign_database(database)
      assign_graph(graph)
      assign_type(type)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:collection, cache_name, self)
      end
      body[:type]     ||= type == :document ? 2 : 3
      body[:status]   ||= nil
      body[:isSystem] ||= isSystem
      body[:id]       ||= nil
      assign_attributes(body)
    end

# === DEFINE ===

    attr_reader :status, :isSystem, :id, :server, :database, :graph, :type,
     :countExport, :hasMoreExport, :idExport, :hasMoreSimple, :idSimple, :body,
     :cache_name
    attr_accessor :name

    def graph=(graph)
      satisfy_class?(graph, [Arango::Graph, NilClass])
      if !graph.nil? && graph.database.name != @database.name
        raise Arango::Error.new err: :database_graph_no_same_as_collection_database,
        data: {"graph_database_name": graph.database.name,
          "collection_database_name":  @database.name}
      end
      @graph = graph
    end
    alias assign_graph graph=

    def body=(result)
      @body     = result
      @name     = result[:name] || @name
      @type     = assign_type(result[:type])
      @status   = reference_status(result[:status])
      @id       = result[:id] || @id
      @isSystem = result[:isSystem] || @isSystem
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@name}"
        @server.cache.save(:database, @cache_name, self)
      end
    end
    alias assign_attributes body=

    def type=(type)
      type ||= @type
      satisfy_category?(type, ["Document", "Edge", 2, 3, nil, :document, :edge])
      @type = case type
      when 2, "Document", nil
        :document
      when 3, "Edge"
        :edge
      end
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

    def to_h
      {
        "name":     @name,
        "type":     @type,
        "status":   @status,
        "id":       @id,
        "isSystem": @isSystem,
        "body":     @body,
        "cache_name": @cache_name,
        "database": @database.name
      }.delete_if{|k,v| v.nil?}
    end

# === GET ===

    def retrieve
      result = @database.request("GET", "_api/collection/#{@name}")
      return_element(result)
    end

    def properties
      @database.request("GET", "_api/collection/#{@name}/properties")
    end

    def count
      @database.request("GET", "_api/collection/#{@name}/count", key: :count)
    end

    def statistics
      @database.request("GET", "_api/collection/#{@name}/figures", key: :figures)
    end

    def revision
      @database.request("GET", "_api/collection/#{@name}/revision", key: :revision)
    end

    def checksum(withRevisions: nil, withData: nil)
      query = {
        "withRevisions": withRevisions,
        "withData": withData
      }
      @database.request("GET", "_api/collection/#{@name}/checksum",  query: query,
        key: :checksum)
    end

# == POST ==

    def create(journalSize: nil, replicationFactor: nil,
      allowUserKeys: nil, typeKeyGenerator: nil, incrementKeyGenerator: nil,
      offsetKeyGenerator: nil, waitForSync: nil, doCompact: nil,
      isVolatile: nil, shardKeys: nil, numberOfShards: nil,
      isSystem: @isSystem, type: @type, indexBuckets: nil, distributeShardsLike: nil, shardingStrategy: nil)
      satisfy_category?(typeKeyGenerator, [nil, "traditional", "autoincrement"])
      satisfy_category?(type, ["Edge", "Document", 2, 3, nil, :edge, :document])
      satisfy_category?(shardingStrategy, [nil, "community-compat", "enterprise-compat", "enterprise-smart-edge-compat", "hash", "enterprise-hash-smart-edge"])
      keyOptions = {
        "allowUserKeys":      allowUserKeys,
        "type":               typeKeyGenerator,
        "increment":          incrementKeyGenerator,
        "offset":             offsetKeyGenerator
      }
      keyOptions.delete_if{|k,v| v.nil?}
      keyOptions = nil if keyOptions.empty?
      type = case type
      when 2, "Document", nil, :document
        2
      when 3, "Edge", :edge
        3
      end
      body = {
        "name": @name,
        "type": type,
        "replicationFactor": replicationFactor,
        "journalSize":       journalSize,
        "keyOptions":        keyOptions,
        "waitForSync":       waitForSync,
        "doCompact":         doCompact,
        "isVolatile":        isVolatile,
        "shardKeys":         shardKeys,
        "numberOfShards":    numberOfShards,
        "isSystem":          isSystem,
        "indexBuckets":      indexBuckets,
        "distributeShardsLike": distributeShardsLike,
        "shardingStrategy":  shardingStrategy
      }
      body = @body.merge(body)
      result = @database.request("POST", "_api/collection", body: body)
      return_element(result)
    end

# === DELETE ===

    def destroy
      result = @database.request("DELETE", "_api/collection/#{@name}")
      return return_delete(result)
    end

    def truncate
      result = @database.request("PUT", "_api/collection/#{@name}/truncate")
      return_element(result)
    end

# === MODIFY ===

    def load
      result = @database.request("PUT", "_api/collection/#{@name}/load")
      return_element(result)
    end

    def unload
      result = @database.request("PUT", "_api/collection/#{@name}/unload")
      return_element(result)
    end

    def loadIndexesIntoMemory
      @database.request("PUT", "_api/collection/#{@name}/loadIndexesIntoMemory")
      return true
    end

    def change(waitForSync: nil, journalSize: nil)
      body = {
        "journalSize": journalSize,
        "waitForSync": waitForSync
      }
      result = @database.request("PUT", "_api/collection/#{@name}/properties", body: body)
      return_element(result)
    end

    def rename(newName:)
      body = { "name": newName }
      result = @database.request("PUT", "_api/collection/#{@name}/rename", body: body)
      return_element(result)
    end

    def rotate
      @database.request("PUT", "_api/collection/#{@name}/rotate")
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
      body = { "type": type, "collection": @name }
      result = @database.request("PUT", "_api/simple/all-keys", body: body)
      @hasMoreSimple = result[:hasMore]
      @idSimple = result[:id]
      return result if return_directly?(result)
      return result[:result] unless @returnDocument
      if @returnDocument
        result[:result].map{|key| Arango::Document.new(name: key, collection: self)}
      end
    end

    def next
      if @hasMoreSimple
        result = @database.request("PUT", "_api/cursor/#{@idSimple}")
        @hasMoreSimple = result[:hasMore]
        @idSimple = result[:id]
        return result if return_directly?(result)
        return result[:result] unless @returnDocument
        if @returnDocument
          result[:result].map{|key| Arango::Document.new(name: key, collection: self)}
        end
      else
        raise Arango::Error.new err: :no_other_simple_next, data: {"hasMoreSimple": @hasMoreSimple}
      end
    end

    def return_body(x, type=:document)
      satisfy_class?(x, [Hash, Arango::Document, Arango::Edge, Arango::Vertex])
      body = case x
      when Hash
        x
      when Arango::Edge
        if type == :vertex
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            {"expected_value":  type, "received_value": x.type, "wrong_object":  x}
        end
        x.body
      when Arango::Vertex
        if type == :edge
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            {"expected_value":  type, "received_value": x.type, "wrong_object":  x}
        end
        x.body
      when Arango::Document
        if (type == :vertex && x.collection.type == :edge)  ||
           (type == :edge && x.collection.type == :document) ||
           (type == :edge && x.collection.type == :vertex)
          raise Arango::Error.new err: :wrong_type_instead_of_expected_one, data:
            {"expected_value":  type, "received_value":  x.collection.type, "wrong_object":  x}
        end
        x.body
      end
      return body.delete_if{|k,v| v.nil?}
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
        "waitForSync": waitForSync,
        "returnNew":   returnNew,
        "silent":      silent
      }
      results = @database.request("POST", "_api/document/#{@name}", body: document,
        query: query)
      return results if return_directly?(results) || silent
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew
          body2.delete(:new)
          body2 = body2.merge(result[:new])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result[:_key], collection: self, body: real_body)
      end
    end

    def createEdges(document: {}, from:, to:, waitForSync: nil, returnNew: nil, silent: nil)
      edges = []
      from = [from] unless from.is_a? Array
      to   = [to]   unless to.is_a? Array
      document = [document] unless document.is_a? Array
      document = document.map{|x| return_body(x, :edge)}
      from = from.map{|x| return_id(x)}
      to   = to.map{|x| return_id(x)}
      document.each do |b|
        from.each do |f|
          to.each do |t|
            b[:_from] = f
            b[:_to] = t
            edges << b.clone
          end
        end
      end
      createDocuments(document: edges, waitForSync: waitForSync,
        returnNew: returnNew, silent: silent)
    end

    def replaceDocuments(document: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil)
      document.each{|x| x = x.body if x.is_a?(Arango::Document)}
      query = {
        "waitForSync": waitForSync,
        "returnNew":   returnNew,
        "returnOld":   returnOld,
        "ignoreRevs":  ignoreRevs
      }
      result = @database.request("PUT", "_api/document/#{@name}", body: document,
        query: query)
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew == true
          body2.delete(:new)
          body2 = body2.merge(result[:new])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result[:_key], collection: self, body: real_body)
      end
    end

    def updateDocuments(document: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil, keepNull: nil, mergeObjects: nil)
      document.each{|x| x = x.body if x.is_a?(Arango::Document)}
      query = {
        "waitForSync": waitForSync,
        "returnNew":   returnNew,
        "returnOld":   returnOld,
        "ignoreRevs":  ignoreRevs,
        "keepNull":    keepNull,
        "mergeObject": mergeObjects
      }
      result = @database.request("PATCH", "_api/document/#{@name}", body: document,
        query: query, keepNull: keepNull)
      return results if return_directly?(result)
      results.map.with_index do |result, index|
        body2 = result.clone
        if returnNew
          body2.delete(:new)
          body2 = body2.merge(result[:new])
        end
        real_body = document[index]
        real_body = real_body.merge(body2)
        Arango::Document.new(name: result[:_key], collection: self,
          body: real_body)
      end
    end

    def destroyDocuments(document: {}, waitForSync: nil, returnOld: nil,
      ignoreRevs: nil)
      document.each{|x| x = x.body if x.is_a?(Arango::Document)}
      query = {
        "waitForSync": waitForSync,
        "returnOld":   returnOld,
        "ignoreRevs":  ignoreRevs
      }
      @database.request("DELETE", "_api/document/#{@id}", query: query, body: document)
    end

# == SIMPLE ==

    def generic_document_search(url, body, single=false)
      result = @database.request("PUT", url, body: body)
      @returnDocument = true
      @hasMoreSimple = result[:hasMore]
      @idSimple = result[:id]
      return result if return_directly?(result)

      if single
        Arango::Document.new(name: result[:document][:_key], collection: self,
          body: result[:document])
      else
        result[:result].map{|x| Arango::Document.new(name: x[:_key], collection: self, body: x)}
      end
    end
    private :generic_document_search

    def allDocuments(skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection": @name,
        "skip":       skip,
        "limit":      limit,
        "batchSize":  batchSize
      }
      generic_document_search("_api/simple/all", body)
    end

    def documentsMatch(match:, skip: nil, limit: nil, batchSize: nil)
      body = {
        "collection": @name,
        "example":    match,
        "skip":       skip,
        "limit":      limit,
        "batchSize":  batchSize
      }
      generic_document_search("_api/simple/by-example", body)
    end

    def documentMatch(match:)
      body = {
        "collection": @name,
        "example":    match
      }
      generic_document_search("_api/simple/first-example", body, true)
    end

    def documentByKeys(keys:)
      keys = [keys] unless keys.is_a?(Array)
      keys = keys.map{|x| x.is_a?(Arango::Document) ? x.name : x}
      body = { "collection":  @name, "keys":  keys }
      result = @database.request("PUT", "_api/simple/lookup-by-keys", body: body)
      return result if return_directly?(result)
      result[:documents].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def documentByName(names:)
      documentByKeys(keys: names)
    end

    def random
      body = { "collection":  @name }
      generic_document_search("_api/simple/any", body, true)
    end

    def removeByKeys(keys:, returnOld: nil, silent: nil, waitForSync: nil)
      options = {
        "returnOld":   returnOld,
        "silent":      silent,
        "waitForSync": waitForSync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      if keys.is_a? Array
        keys = keys.map{|x| x.is_a?(String) ? x : x.key}
      end
      body = { "collection": @name, "keys": keys, "options": options}
      result = @database.request("PUT", "_api/simple/remove-by-keys", body: body)
      return result if return_directly?(result)
      if returnOld == true && silent != true
        result.each do |r|
          Arango::Document.new(name: r[:_key], collection: self, body: r)
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
        "limit":        limit,
        "waitForSync":  waitForSync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection":  @name,
        "example"    => match,
        "options"    => options
      }
      @database.request("PUT", "_api/simple/remove-by-example", body: body, key: :deleted)
    end

    def replaceMatch(match:, newValue:, limit: nil, waitForSync: nil)
      options = {
        "limit":        limit,
        "waitForSync":  waitForSync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection": @name,
        "example":    match,
        "options":    options,
        "newValue":   newValue
      }
      @database.request("PUT", "_api/simple/replace-by-example", body: body, key: :replaced)
    end

    def updateMatch(match:, newValue:, keepNull: nil, mergeObjects: nil,
      limit: nil, waitForSync: nil)
      options = {
        "keepNull":     keepNull,
        "mergeObjects": mergeObjects,
        "limit":        limit,
        "waitForSync":  waitForSync
      }
      options.delete_if{|k,v| v.nil?}
      options = nil if options.empty?
      body = {
        "collection": @name,
        "example":    match,
        "options":    options,
        "newValue":   newValue
      }
      @database.request("PUT", "_api/simple/update-by-example", body: body, key: :updated)
    end

# === SIMPLE DEPRECATED ===

    def range(right:, attribute:, limit: nil, closed: true, skip: nil, left:,
      warning: @server.warning)
      warning_deprecated(warning, "range")
      body = {
        "right":      right,
        "attribute":  attribute,
        "collection": @name,
        "limit":  limit,
        "closed": closed,
        "skip":   skip,
        "left":   left
      }
      result = @database.request("PUT", "_api/simple/range", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def near(distance: nil, longitude:, latitude:, geo: nil, limit: nil,
      skip: nil, warning: @server.warning)
      warning_deprecated(warning, "near")
      body = {
        "distance":   distance,
        "longitude":  longitude,
        "collection": @name,
        "limit":      limit,
        "latitude":   latitude,
        "skip":       skip,
        "geo":        geo
      }
      result = @database.request("PUT", "_api/simple/near", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def within(distance: nil, longitude:, latitude:, radius:, geo: nil,
      limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "within")
      body = {
        "distance":   distance,
        "longitude":  longitude,
        "collection": @name,
        "limit":      limit,
        "latitude":   latitude,
        "skip":       skip,
        "geo":        geo,
        "radius":     radius
      }
      result = @database.request("PUT", "_api/simple/within", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def withinRectangle(longitude1:, latitude1:, longitude2:, latitude2:,
      geo: nil, limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "withinRectangle")
      body = {
        "longitude1": longitude1,
        "latitude1":  latitude1,
        "longitude2": longitude2,
        "latitude2":  latitude2,
        "collection": @name,
        "limit":      limit,
        "skip":       skip,
        "geo":        geo,
        "radius":     radius
      }
      result = @database.request("PUT", "_api/simple/within-rectangle", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
      end
    end

    def fulltext(index:, attribute:, query:, limit: nil, skip: nil, warning: @server.warning)
      warning_deprecated(warning, "fulltext")
      body = {
        "index":     index,
        "attribute": attribute,
        "query":     query,
        "limit":     limit,
        "skip":      skip
      }
      result = @database.request("PUT", "_api/simple/fulltext", body: body)
      return result if return_directly?(result)
      result[:result].map do |x|
        Arango::Document.new(name: x[:_key], collection: self, body: x)
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
        "collection":  @name,
        "fromPrefix":  fromPrefix,
        "toPrefix":    toPrefix,
        "overwrite":   overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete":    complete,
        "details":     details
      }
      body = "#{attributes}\n"
      values[0].is_a?(Array) ? values.each{|x| body += "#{x}\n"} : body += "#{values}\n"
      @database.request("POST", "_api/import", query: query,
        body: body, skip_to_json: true)
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
        "collection":  @name,
        "type":        type,
        "fromPrefix":  fromPrefix,
        "toPrefix":    toPrefix,
        "overwrite":   overwrite,
        "waitForSync": waitForSync,
        "onDuplicate": onDuplicate,
        "complete":    complete,
        "details":     details
      }
      @database.request("POST", "_api/import", query: query,
        body: body)
    end

  # === EXPORT ===

    def export(count: nil, restrict: nil, batchSize: nil,
      flush: nil, flushWait: nil, limit: nil, ttl: nil)
      query = { "collection":  @name }
      body = {
        "count":     count,
        "restrict":  restrict,
        "batchSize": batchSize,
        "flush":     flush,
        "flushWait": flushWait,
        "limit":     limit,
        "ttl":       ttl
      }
      result = @database.request("POST", "_api/export", body: body, query: query)
      return reuslt if @server.async != false
      @countExport   = result[:count]
      @hasMoreExport = result[:hasMore]
      @idExport      = result[:id]
      if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
        return result[:result]
      else
        return result[:result].map do |x|
          Arango::Document.new(name: x[:_key], collection: self, body: x)
        end
      end
    end

    def exportNext
      unless @hasMoreExport
        raise Arango::Error.new err: :no_other_export_next, data: {"hasMoreExport":  @hasMoreExport}
      else
        query = { "collection":  @name }
        result = @database.request("PUT", "_api/export/#{@idExport}", query: query)
        return result if @server.async != false
        @countExport   = result[:count]
        @hasMoreExport = result[:hasMore]
        @idExport      = result[:id]
        if return_directly?(result) || result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key)
          return result[:result]
        else
          return result[:result].map do |x|
            Arango::Document.new(name: x[:_key], collection: self, body: x)
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
      query = { "collection":  @name }
      result = @database.request("GET", "_api/index", query: query)
      return result if return_directly?(result)
      result[:indexes].map do |x|
        Arango::Index.new(body: x, id: x[:id], collection: self,
          type: x[:type], unique: x[:unique], fields: x[:fields],
          sparse: x[:sparse])
      end
    end

# === REPLICATION ===

    def data(batchId:, from: nil, to: nil, chunkSize: nil,
      includeSystem: nil, failOnUnknown: nil, ticks: nil, flush: nil)
      query = {
        "collection": @name,
        "batchId":    batchId,
        "from":       from,
        "to":         to,
        "chunkSize":  chunkSize,
        "includeSystem":  includeSystem,
        "failOnUnknown":  failOnUnknown,
        "ticks": ticks,
        "flush": flush
      }
      @database.request("GET", "_api/replication/dump", query: query)
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
      user.add_collection_access(grant: grant, database: @database.name, collection: @name)
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
      if @type == :edge
        raise Arango::Error.new err: :is_a_edge_collection, data: {"type":  @type}
      end
      if @graph.nil?
        Arango::Document.new(name: name, body: body, rev: rev, collection: self)
      else
        Arango::Vertex.new(name: name, body: body, rev: rev, collection: self)
      end
    end

    def edge(name: nil, body: {}, rev: nil, from: nil, to: nil)
      if @type == :document
        raise Arango::Error.new err: :is_a_document_collection, data: {"type":  @type}
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
