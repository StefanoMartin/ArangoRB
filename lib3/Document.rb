# ==== DOCUMENT ====

module Arango
  class Document
    def initialize(key:, collection:, body: {}, rev: nil, from: nil, to: nil)
      satisfy_class?(key, "key")
      satisfy_class?(collection, "collection", [Arango::Collection])
      @collection = collection
      @database = @collection.database
      @client = @database.client
      body["_key"] ||= key
      body["_rev"] ||= rev
      body["_to"] ||= to
      body["_from"] || from
      body["_id"] ||= "#{@collection.name}/#{@key}"
      assign_attributes(body)
      ignore_exception(retrieve) if @client.initialize_retrieve
    end

    attr_reader :key, :collection, :database, :client, :id, :rev

    def to_h
      {
        "key" => @key,
        "id" => @id,
        "rev" => @rev,
        "collection" => @collection.name,
        "body" => @body,
        "from" => @from,
        "to" => @to
      }.delete_if{|k,v| v.nil?}
    end

# == PRIVATE ==

    def assign_attributes(result)
      @body = result.delete_if{|k,v| v.nil?}
      @key = result["_key"]
      @id = result["_id"]
      @rev = result["_rev"]
      @from = result["_from"]
      @to = result["_to"]
    end

    def return_document(result)
      return result if @database.client.async != false
      assign_attributes(result)
      return return_directly?(result) ? result : self
    end


# == GET ==

    def retrieve(if_none_match: false, if_match: false)
      headers = {}
      headers["If-None-Match"] = @rev if if_none_match
      headers["If-Match"] = @rev if if_none_match
      result = @database.request(action: "GET", headers: headers,
        url: "_api/document/#{@id}")
      return_document(result)
    end

# == HEAD ==

    def head(if_none_match: false, if_match: false)
      headers = {}
      headers["If-None-Match"] = @rev if if_none_match
      headers["If-Match"] = @rev if if_none_match
      @database.request(action: "HEAD", headers: headers,
        url: "_api/document/#{@id}")
    end

# == POST ==

    def create(body: {}, waitForSync: nil, returnNew: nil, silent: nil)
      body = @body.merge(body)
      query = {
        "waitForSync" => waitForSync,
        "returnNew" => returnNew,
        "silent" => silent
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

    def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil, silent: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "returnNew" => returnNew,
        "returnOld" => returnOld,
        "ignoreRevs" => ignoreRevs,
        "silent" => silent
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
        "returnNew" => returnNew,
        "returnOld" => returnOld,
        "ignoreRevs" => ignoreRevs,
        "keepNull" => keepNull,
        "mergeObjects" => mergeObjects,
        "silent" => silent
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

    def destroy(body: nil, waitForSync: nil, silent: nil, returnOld: nil, if_match: false)
      query = {
        "waitForSync" => waitForSync,
        "returnOld" => returnOld,
        "silent" => silent
      }
      headers = {}
      headers["If-Match"] = @rev if if_match
      result = @document.request(action: "DELETE",
        url: "_api/document/#{@id}", query: query, headers: headers)
      return_document(result)
    end

  # === EDGE ===

    def create_edge(id, body={})
      collection_name, key = id.split("/")
      collection = Arango::Collection.new(name: collection_name, database: @database, type: "Edge")
      Arango::Document.new(key: key, body: body, collection: collection)
    end

    def edges(direction: nil)
      query = {
        "vertex" => @name,
        "direction" => direction
      }
      result = @document.request(action: "GET",
        url: "_api/edges/#{@collection.name}", query: query)
      return result if return_directly?(result)
      result["edges"].map do |edge|
        create_edge(edge["_id"], edge)
      end
    end
    alias edges any

    def out
      edges(direction: "out")
    end

    def in
      edges(direction: "in")
    end

    def from
      create_edge(@from)
    end

    def to
      create_edge(@to)
    end
  end
end
