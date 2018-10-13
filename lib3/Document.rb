# ==== DOCUMENT ====

module Arango
  class Document
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Collection_Return

    def initialize(name: nil, collection:, body: {}, rev: nil, from: nil,
      to: nil)
      assign_collection(collection)
      body[:_key]  ||= name
      body[:_rev]  ||= rev
      body[:_to]   ||= to
      body[:_from] ||= from
      body[:_id]   ||= "#{@collection.name}/#{name}" unless name.nil?
      assign_attributes(body)
      # DEFINE
      ["name", "rev", "from", "to", "key"].each do |attribute|
        define_singleton_method(:"#{attribute}=") do |attrs|
          temp_attrs = attribute
          temp_attrs = "key" if attribute == "name"
          @body[:"_#{temp_attrs}"] = attrs
          assign_attributes(@body)
        end
      end
    end

# === DEFINE ==

    attr_reader :name, :collection, :graph, :database, :server, :id, :rev,
      :body, :from, :to
    alias_method :key, :name

    def body=(result)
      result.compact!
      hash = {
        "_key":  @name,
        "_id":   @id,
        "_rev":  @rev,
        "_from": @from,
        "_to":   @to
      }
      @body = hash.merge(result)
      @name = result[:_key]
      @id   = result[:_id]
      if @id.nil? && !@name.nil?
        @id = "#{@collection.name}/#{@name}"
      end
      @rev  = result[:_rev]
      set_up_from_or_to("from", result[:_from])
      set_up_from_or_to("to", result[:_to])
    end
    alias assign_attributes body=

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "name": @name,
        "id":   @id,
        "rev":  @rev,
        "body": @body
      }
      hash[:collection] = level > 0 ? @collection.to_h(level-1) : @collection.name
      hash[:from] = level > 0 ? @from&.to_h(level-1) : @from&.id
      hash[:to] = level > 0 ? @to&.to_h(level-1) : @to&.id
      hash.compact!
      hash
    end

    def set_up_from_or_to(attrs, var)
      if var.is_a?(NilClass)
        instance = nil
      elsif var.is_a?(String)
        if !var.is_a?(String) || !var.include?("/")
          raise Arango::Error.new err: :attribute_is_not_valid, data: {"attribute" attrs, "wrong_value" var}
        end
        collection_name, document_name = var.split("/")
        collection = Arango::Collection.new name: collection_name,
          database: @database
        if @graph.nil?
          instance = Arango::Document.new name: document_name, collection: collection
        else
          collection.graph = @graph
          instance = Arango::Vertex.new name: document_name, collection: collection
        end
      elsif var.is_a?(Arango::Document)
        instance = var
      else
        raise Arango::Error.new err: :attribute_is_not_valid, data: {"attribute" attrs, "wrong_value" var}
      end
      instance_variable_set("@#{attrs}", instance)
      @body[:"_#{attrs}"] = instance&.id unless instance&.id.nil?
    end
    private :set_up_from_or_to

# == GET ==

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @rev if if_none_match
      headers[:"If-Match"]      = @rev if if_match
      result = @database.request("GET",  "_api/document/#{@id}", headers: headers)
      return_element(result)
    end

# == HEAD ==

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers[:"If-None-Match"] = @rev if if_none_match
      headers[:"If-Match"]      = @rev if if_match
      @database.request("HEAD", "_api/document/#{@id}", headers: headers)
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
      headers[:"If-Match"] = @rev if if_match
      result = @database.request("PUT", "_api/document/#{@id}", body: body,
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
      headers[:"If-Match"] = @rev if if_match
      result = @database.request("PATCH", "_api/document/#{@id}", body: body,
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
      headers[:"If-Match"] = @rev if if_match
      result = @database.request("DELETE", "_api/document/#{@id}", query: query,
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

    def edges(collection, direction=nil)
      satisfy_class?(collection, [Arango::Collection, String])
      collection = collection.is_a?(Arango::Collection) ? collection.name : collection
      query = {
        "vertex":    @id,
        "direction": direction
      }
      result = @database.request("GET",
        url: "_api/edges/#{collection}", query: query)
      return result if return_directly?(result)
      result[:edges].map do |edge|
        collection_name, key = edge[:_id].split("/")
        collection = Arango::Collection.new(name: collection_name,
          database: @database, type: :edge)
        Arango::Document.new(name: key, body: edge, collection: collection)
      end
    end

    def out(collection)
      edges(collection, "out")
    end

    def in(collection)
      edges(collection, "in")
    end

# === TRAVERSAL ===

    def traversal(body: {}, sort: nil, direction: nil, minDepth: nil,
      visitor: nil, itemOrder: nil, strategy: nil,
      filter: nil, init: nil, maxIterations: nil, maxDepth: nil,
      uniqueness: nil, order: nil, expander: nil,
      edgeCollection: nil)
      Arango::Traversal.new(body: body, database: @database,
        sort: sort, direction: direction, minDepth: minDepth,
        startVertex: self, visitor: visitor,itemOrder: itemOrder,
        strategy: strategy, filter: filter, init: init,
        maxIterations: maxIterations, maxDepth: maxDepth,
        uniqueness: uniqueness, order: order, graph: @graph,
        expander: expander, edgeCollection: edgeCollection)
    end
  end
end
