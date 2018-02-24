# ==== DOCUMENT ====

module Arango
  class Document
    include Helper_Error
    include Meta_prog
    include Helper_Return

    def initialize(name:, collection:, body: {}, rev: nil, from: nil, to: nil)
      satisfy_class?(collection, "collection", [Arango::Collection])
      @collection = collection
      @database = @collection.database
      @client = @database.client
      body["_key"] ||= name
      body["_rev"] ||= rev
      body["_to"] ||= to
      body["_from"] || from
      body["_id"] ||= "#{@collection.name}/#{name}"
      assign_attributes(body)
      ["name", "rev", "from", "to", "key"].each do |attribute|
        define_method(:"#{attribute}=") do |attrs|
          temp_attrs = attribute
          temp_attrs = "key" if attribute == "name"
          body["_#{temp_attrs}"] = attrs
          assign_attributes(body)
        end
      end
    end

    attr_reader :name, :collection, :database, :client, :id, :rev, :body,
      :from, :to
    alias_method :key, :name

    def collection=(collection)
      satisfy_class?(collection, [Arango::Collection])
      @collection = collection
      @database = @collection.database
      @client = @database.client
    end

    def body=(body)
      assign_attributes(body)
    end

    def to_h(level=0)
      hash = {
        "name" => @name,
        "id" => @id,
        "rev" => @rev,
        "body" => @body
      }
      hash["collection"] = level > 0 ? @collection.to_h(level-1) : @collection.name
      hash["from"] = level > 0 ? @from.to_h(level-1) : @from&.name
      hash["to"] = level > 0 ? @to.to_h(level-1) : @too&.name
      hash.delete_if{|k,v| v.nil?}
      hash
    end

    def set_up_from_or_to(attrs, var)
      if var.is_a?(NilClass)
        instance = nil
      elsif var.is_a?(String)
        if !var.is_a?(String) || !var.include?("/")
          Arango::Error message: "#{attrs} is not a valid document id or an Arango::Document"
        end
        collection_name, document_name = var.split("/")
        collection = Arango::Collection name: collection_name, database: @database
        instance = Arango::Document name: document_name
      elsif var.is_a?(Arango::Document)
        instance = var
      else
        Arango::Error message: "#{attrs} is not a valid document id or an Arango::Document"
      end
      instance_variable_set("@#{attrs}", instance)
      @body["_#{attrs}"] = string unless string.nil?
    end

# == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @name = result["_key"] || @name
      @id   = result["_id"]  || @id
      @rev  = result["_rev"] || @rev
      set_up_from_or_to("from", result["_from"])
      set_up_from_or_to("to", result["_to"])
    end

# == GET ==

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers["If-None-Match"] = @rev if if_none_match
      headers["If-Match"]      = @rev if if_none_match
      result = @database.request(action: "GET", headers: headers,
        url: "_api/document/#{@id}")
      return_element(result)
    end

# == HEAD ==

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers["If-None-Match"] = @rev if if_none_match
      headers["If-Match"]      = @rev if if_none_match
      @database.request(action: "HEAD", headers: headers,
        url: "_api/document/#{@id}")
    end

# == POST ==

    def create(body: {}, waitForSync: nil, returnNew: nil, silent: nil)
      body = @body.merge(body)
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "silent"      => silent
      }
      result = @database.request(action: "POST", body: body,
        query: query, url: "_api/document/#{@collection.name}" )
      return result if @database.client.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete("new")
        body2 = body2.merge(result["new"])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

# == PUT ==

    def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil,
      returnNew: nil, silent: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "returnOld"   => returnOld,
        "ignoreRevs"  => ignoreRevs,
        "silent"      => silent
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @database.request(action: "PUT", body: body,
        query: query, headers: headers, url: "_api/document/#{@id}")
      return result if @database.client.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete("new")
        body2 = body2.merge(result["new"])
      end
      body = body.merge(body2)
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

    def update(body: {}, waitForSync: nil, ignoreRevs: nil,
      returnOld: nil, returnNew: nil, keepNull: nil,
      mergeObjects: nil, silent: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "returnNew"   => returnNew,
        "returnOld"   => returnOld,
        "ignoreRevs"  => ignoreRevs,
        "keepNull"    => keepNull,
        "mergeObjects" => mergeObjects,
        "silent"      => silent
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @database.request(action: "PATCH", body: body,
        query: query, headers: headers, url: "_api/document/#{@id}")
      return result if @database.client.async != false || silent
      body2 = result.clone
      if returnNew
        body2.delete("new")
        body2 = body2.merge(result["new"])
      end
      body = body.merge(body2)
      if mergeObjects
        body = @body.merge(body)
      else
        body.each do |key, value|
          @body[key] = value
        end
      end
      assign_attributes(body)
      return return_directly?(result) ? result : self
    end

  # === DELETE ===

    def destroy(body: nil, waitForSync: nil, silent: nil, returnOld: nil,
      if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "returnOld"   => returnOld,
        "silent"      => silent
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @document.request(action: "DELETE",
        url: "_api/document/#{@id}", query: query, headers: headers)
      return_element(result)
    end

  # === EDGE ===

    def edges(direction: nil)
      query = {
        "vertex" => @name,
        "direction" => direction
      }
      result = @document.request(action: "GET",
        url: "_api/edges/#{@collection.name}", query: query)
      return result if return_directly?(result)
      result["edges"].map do |edge|
        collection_name, key = edge["_id"].split("/")
        collection = Arango::Collection.new(name: collection_name,
          database: @database, type: "Edge")
        Arango::Document.new(name: key, body: body, collection: collection)
      end
    end

    def out
      edges(direction: "out")
    end

    def in
      edges(direction: "in")
    end
  end
end
