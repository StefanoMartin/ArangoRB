# ==== DOCUMENT ====

module Arango
  class Document
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Collection_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      collection = hash[:collection]
      if collection.is_a?(Arango::Collection) &&
        collection.database.server.active_cache && !hash[:name].nil?
        cache_name = "#{collection.database.name}/#{collection.name}/#{hash[:name]}"
        cached = collection.database.server.cache.cache.dig(:document, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = hash[:body] || {}
          [:rev, :from, :to].each{|k| body[:"_#{k}"] ||= hash[k]}
          body[:"_key"] ||= hash[:name]
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(name: nil, collection:, body: {}, rev: nil, from: nil,
      to: nil, cache_name: nil)
      assign_collection(collection)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:document, cache_name, self)
      end
      body[:_key]  ||= name
      body[:_rev]  ||= rev
      body[:_to]   ||= to
      body[:_from] ||= from
      body[:_id]   ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
    end

    def name
      return @body[:_key]
    end
    alias key name

    def rev
      return @body[:_rev]
    end

    def id
      return @body[:_id]
    end

    def name=(att)
      assign_attributes({_key: att})
    end
    alias key= name=

    def rev=(att)
      assign_attributes({_rev: att})
    end

    def id=(att)
      assign_attributes({_id: id})
    end

    def from=(att)
      att = att.id if att.is_a?(Arango::Document)
      assign_attributes({_from: att})
    end

    def to=(att)
      att = att.id if att.is_a?(Arango::Document)
      assign_attributes({_to: att})
    end

# === DEFINE ==

    attr_reader :collection, :graph, :database, :server, :body, :cache_name

    def body=(result)
      result.delete_if{|k,v| v.nil?}
      @body ||= {}
      # binding.pry if @body[:_key] == "Second_Key"
      hash = {
        "_key":  @body[:_key],
        "_id":   @body[:_id],
        "_rev":  @body[:_rev],
        "_from": @body[:_from],
        "_to":   @body[:_to]
      }
      @body = hash.merge(result)
      if @body[:_id].nil? && !@body[:_key].nil?
        @body[:_id] = "#{@collection.name}/#{@body[:_key]}"
      end
      set_up_from_or_to("from", result[:_from])
      set_up_from_or_to("to", result[:_to])
      if @server.active_cache && @cache_name.nil? && !@body[:_id].nil?
        @cache_name = "#{@database.name}/#{@body[:_id]}"
        @server.cache.save(:document, @cache_name, self)
      end
    end
    alias assign_attributes body=

# === TO HASH ===

    def to_h
      {
        "name":  @body[:_key],
        "id":    @body[:_id],
        "rev":   @body[:_rev],
        "from":  @body[:_from],
        "to":    @body[:_to],
        "body":  @body,
        "cache_name":  @cache_name,
        "collection": @collection.name,
        "graph": @graph&.name
      }.delete_if{|k,v| v.nil?}
    end

    def set_up_from_or_to(attrs, var)
      case var
      when NilClass
        @body[:"_#{attrs}"] = nil
      when String
        unless var.include?("/")
          raise Arango::Error.new err: :attribute_is_not_valid, data:
            {"attribute": attrs, "wrong_value": var}
        end
        @body[:"_#{attrs}"] = var
      when Arango::Document
        @body[:"_#{attrs}"] = var.id
      else
        raise Arango::Error.new err: :attribute_is_not_valid, data:
          {"attribute": attrs, "wrong_value": var}
      end
    end
    private :set_up_from_or_to

    def from(string: false)
      return @body[:_from] if string
      retrieve_instance_from_and_to(@body[:_from])
    end

    def to(string: false)
      return @body[:_to] if string
      retrieve_instance_from_and_to(@body[:_to])
    end

    def retrieve_instance_from_and_to(var)
      case var
      when NilClass
        return nil
      when String
        collection_name, document_name = var.split("/")
        collection = Arango::Collection.new name: collection_name, database: @database
        if @graph.nil?
          return Arango::Document.new(name: document_name, collection: collection)
        else
          collection.graph = @graph
          return Arango::Vertex.new(name: document_name, collection: collection)
        end
      end
    end
    private :retrieve_instance_from_and_to

# == GET ==

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      result = @database.request("GET",  "_api/document/#{@body[:_id]}", headers: headers)
      return_element(result)
    end

# == HEAD ==

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @body[:_rev] if if_none_match
      headers[:"If-Match"]      = @body[:_rev] if if_match
      @database.request("HEAD", "_api/document/#{@body[:_id]}", headers: headers)
    end

# == POST ==

    def create(body: {}, waitForSync: nil, returnNew: nil, silent: nil)
      body = @body.merge(body)
      query = {
        "waitForSync": waitForSync,
        "returnNew":   returnNew,
        "silent":      silent
      }
      result = @database.request("POST", "_api/document/#{@collection.name}", body: body,
        query: query)
      return result if @server.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil,
      returnNew: nil, silent: nil, if_match: false)
      query = {
        "waitForSync": waitForSync,
        "returnNew":   returnNew,
        "returnOld":   returnOld,
        "ignoreRevs":  ignoreRevs,
        "silent":      silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("PUT", "_api/document/#{@body[:_id]}", body: body,
        query: query, headers: headers)
      return result if @server.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil, keepNull: nil,
      mergeObjects: nil, silent: nil, if_match: false)
      query = {
        "waitForSync":  waitForSync,
        "returnNew":    returnNew,
        "returnOld":    returnOld,
        "ignoreRevs":   ignoreRevs,
        "keepNull":     keepNull,
        "mergeObjects": mergeObjects,
        "silent":       silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("PATCH", "_api/document/#{@body[:_id]}", body: body,
        query: query, headers: headers, keepNull: keepNull)
      return result if @server.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete(:new)
        body2 = body2.merge(result[:new])
      end
      body = body.merge(body2)
      if mergeObjects
        @body = @body.merge(body)
      else
        body.each{|key, value| @body[key] = value}
      end
      assign_attributes(@body)
      return return_directly?(result) ? result : self
    end

  # === DELETE ===

    def destroy(waitForSync: nil, silent: nil, returnOld: nil, if_match: false)
      query = {
        "waitForSync": waitForSync,
        "returnOld":   returnOld,
        "silent":      silent
      }
      headers = {}
      headers[:"If-Match"] = @body[:_rev] if if_match
      result = @database.request("DELETE", "_api/document/#{@body[:_id]}", query: query,
        headers: headers)
      return result if @server.async != false || silent
      body2 = result.clone
      if returnOld
        body2.delete(:old)
        body2 = body2.merge(result[:old])
      else
        body2 = body2.merge(@body)
      end
      return_element(body2)
      return true
    end

  # === EDGE ===

    def edges(collection:, direction=nil)
      satisfy_class?(collection, [Arango::Collection, String])
      collection = collection.is_a?(Arango::Collection) ? collection.name : collection
      query = {
        "vertex":    @body[:_id],
        "direction": direction
      }
      result = @database.request("GET", "_api/edges/#{collection}", query: query)
      return result if return_directly?(result)
      result[:edges].map do |edge|
        collection_name, key = edge[:_id].split("/")
        collection = Arango::Collection.new(name: collection_name,
          database: @database, type: :edge)
        Arango::Document.new(name: key, body: edge, collection: collection)
      end
    end

    def any(collection)
      edges(collection: collection)
    end

    def out(collection)
      edges(collection: collection, "out")
    end

    def in(collection: collection)
      edges(collection, "in")
    end

# === TRAVERSAL ===

    def traversal(body: {}, sort: nil, direction: nil, minDepth: nil,
      visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, expander: nil,
      edgeCollection: nil)
      Arango::Traversal.new(body: body,
        sort: sort, direction: direction, minDepth: minDepth,
        vertex: self, visitor: visitor,itemOrder: itemOrder,
        strategy: strategy, filter: filter, init: init,
        maxIterations: maxIterations, maxDepth: maxDepth,
        uniqueness: uniqueness, order: order,
        expander: expander, edgeCollection: edgeCollection)
    end
  end
end
