# ==== DOCUMENT ====

class Arango::Document
  def initialize(collection:, document: nil, body: {}, from: nil, to: nil)
    satisfy_class?(collection, "collection", [Arango::Collection])
    satisfy_class?(document, "document", [Arango::Document, String])
    satisfy_class?(from, "from", [Arango::Document, String, NilClass])
    satisfy_class?(from, "to", [Arango::Document, String, NilClass])
    satisfy_class?(body, "body", [Hash])

    @collection = collection
    @database = @collection.database
    @client = @database.client

    if document.is_a?(String) || document.nil?
      @document = document
      unless document.nil?
        body["_key"] = @document
        @id = "#{@collection.name}/#{@document}"
      end
    elsif document.is_a?(Arango::Document)
      @document = document.name
      @id = document.id
    end

    @body = body
    @from = from
    if from.is_a?(String)
      @body["_from"] = from
    elsif from.is_a?(Arango::Document)
      @body["_from"] = from.id
    end

    @to = to
    if to.is_a?(String)
      @body["_to"] = to
    elsif to.is_a?(Arango::Document)
      @body["_to"] = to.id
    end
  end

  attr_reader :collection, :database, :client, :document, :id, :body
  alias name document

  # === RETRIEVE ===

  def to_hash
    {
      "key" => @document,
      "id" => @id,
      "collection" => @collection.name,
      "database" => @database.name,
      "body" => @body
    }.delete_if{|k,v| v.nil?}
  end
  alias to_h to_hash

  def request(action:, url:, body: {}, query: {}, headers: {})
    result = @client.request(action: action, url: url, query: query)
    if @client.async != false || !result.is_a?(Hash)
      return result
    end
    @document = result["_key"]
    @collection = result["_id"].split("/")[0]
    @body = result.merge(body)
    @id = "#{@collection.name}/#{@document}"
    return key.nil? ? self : result[key]
  end
  private :request

  # === GET ===

  def retrieve  # TESTED
    request(action: "GET", url: "/_db/#{@database.name}/_api/document/#{@id}")
  end

  def retrieve_edges(collection: , direction: nil)
    satisfy_class?(collection, "collection", [Arango::Collection])
    query = {"vertex" => @id, "direction" => direction }
    result = @client.request(action: "GET", url: "/_db/#{collection.database.name}/_api/edges/#{collection.name}", query: query)
    return result if @client.async != false
    result["edges"].map do |edge|
      Arango::Document.new(document: edge["_key"], collection: collection, body: edge)
    end
  end

  def in(edgeCollection)
    satisfy_class?(edgeCollection, "edgeCollection", [Arango::Collection])
    retrieve_edges collection: edgeCollection, direction: "in"
  end

  def out(edgeCollection)
    satisfy_class?(edgeCollection, "edgeCollection", [Arango::Collection])
    retrieve_edges collection: edgeCollection, direction: "out"
  end

  def any(edgeCollection)
    satisfy_class?(edgeCollection, "edgeCollection", [Arango::Collection])
    retrieve_edges collection: edgeCollection
  end

  def from_or_to(object, retrieve, type)
    if retrieve || object.is_a?(String)
      result = @client.request(action: "GET", url: "/_db/#{@database.name}/_api/document/#{@body["_#{type}"]}")
      return result if @client.async != false
      name_collection = result["_id"].split("/")[0]
      collection = Arango::Collection.new collection: name_collection, database: @database
      object = Arango::Document.new(document: result["_key"], collection: collection, body: result)
    end
    return object
  end
  private :from_or_to

  def from(retrieve=false)
    from_or_to(@from, retrieve, "from")
  end

  def to(retrieve=false)
    from_or_to(@to, retrieve, "to")
  end

  # def header
  #   result = self.class.head("/_db/#{@database}/_api/document/#{@id}", follow_redirects: true, maintain_method_across_redirects: true)
  #   @@verbose ? result : result["error"] ? result["errorMessage"] : result
  # end

# === POST ====

  def create(body: {}, waitForSync: nil, returnNew: nil)
    body = @body.merge(body)
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}
    request(action: "POST", url: "/_db/#{@database.name}/_api/document/#{@collection.name}", body: body, query: query)
  end
  alias create_document create
  alias create_vertex create

  def self.create(body: {}, waitForSync: nil, returnNew: nil, collection:)
    satisfy_class?(collection, "collection", [Arango::Collection])
    query = {"waitForSync" => waitForSync, "returnNew" => returnNew}
    if body.is_a?(Array)
      body = body.map do |x|
        x.is_a?(Hash) ? x : x.is_a?(Arango::Document) ? x.body : nil
      end
      result = collection.client.request(action: "POST", url: "/_db/#{collection.database.name}/_api/document/#{collection.name}", body: body,
      query: query)
      return true if collection.client.async != false
      result = result.parsed_response
      i = -1
      result.map do |x|
        i += 1
        Arango::Document.new(document: x["_key"], collection: collection, body: body[i])
      end
    else
      result = collection.client.request(action: "POST", url: "/_db/#{collection.database.name}/_api/document/#{collection.name}", body: body,
      query: query)
      return true if collection.client.async != false
      name_collection = result["_id"].split("/")[0]
      collection = Arango::Collection.new collection: name_collection, database: collection.database
      Arango::Document.new(document: result["_key"], collection: collection, body: body)
    else
  end

  # def create_edge(body: {}, from:, to:, waitForSync: nil, returnNew: nil)  # TESTED
  #   satisfy_class?(collection, "collection", [Arango::Collection])
  #   body = @body.merge(body)
  #   edges = []
  #   from = [from] unless from.is_a? Array
  #   to = [to] unless to.is_a? Array
  #   from.each do |f|
  #     body["_from"] = f.is_a?(String) ? f : f.id
  #     to.each do |t|
  #       body["_to"] = t.is_a?(String) ? t : t.id
  #       edges << body.clone
  #     end
  #   end
  #   edges = edges[0]
  #   ArangoDocument.create(body: edges, waitForSync: waitForSync, returnNew: returnNew, collection: @collection)
  # end

  def self.create_edge(body: {}, from:, to:, waitForSync: nil, returnNew: nil, collection:)
    satisfy_class?(collection, "collection", [Arango::Collection])
    edges = []
    from = [from] unless from.is_a? Array
    to   = [to]   unless to.is_a? Array
    body = [body] unless body.is_a? Array
    body = body.map{|x| x.is_a?(Hash) ? x : x.is_a?(Arango::Document) ? x.body : nil}
    body.each do |b|
      from.each do |f|
        b["_from"] = f.is_a?(String) ? f : f.id
        to.each do |t|
          b["_to"] = t.is_a?(String) ? t : t.id
          edges << b.clone
        end
      end
    end
    edges = edges[0] if edges.length == 1
    Arango::Document.create(body: edges, waitForSync: waitForSync, returnNew: returnNew, collection: collection)
  end

# === MODIFY ===

  def replace(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil)
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }
    if body.is_a?(Array)
      result = @client.request(action: "PUT", url: "/_db/#{@database.name}/_api/document/#{@collection.name}", body: body, query: query)
      return result if @client.async != false
      i = -1
      result.map do |x|
        i += 1
        Arango::Document.new(document: x["_key"], collection: @collection,
          body: body[i])
      end
    else
      request(action: "PUT", url: "/_db/#{@database.name}/_api/document/#{@id}", body: body, query: query)
    end
  end

  def update(body: {}, waitForSync: nil, ignoreRevs: nil, returnOld: nil, returnNew: nil, keepNull: nil, mergeObjects: nil)  # TESTED
    query = {
      "waitForSync" => waitForSync,
      "returnNew" => returnNew,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs,
      "keepNull" => keepNull,
      "mergeObjects" => mergeObjects
    }
    if body.is_a?(Array)
      result = @client.request(action: "PATCH", url: "/_db/#{@database.name}/_api/document/#{@collection.name}", body: body, query: query)
      return result if @client.async != false
      i = -1
      result.map do |x|
        i += 1
        Arango::Document.new(document: x["_key"], collection: @collection,
          body: body[i])
      end
    else
      request(action: "PATCH", url: "/_db/#{@database.name}/_api/document/#{@id}", body: body, query: query)
    end
  end

# === DELETE ===

  def destroy(body: nil, waitForSync: nil, ignoreRevs: nil, returnOld: nil)
    query = {
      "waitForSync" => waitForSync,
      "returnOld" => returnOld,
      "ignoreRevs" => ignoreRevs
    }
    if body.is_a?(Array)
      @client.request(action: "DELETE",
        url: "/_db/#{@database.name}/_api/document/#{@collection.name}",
        body: body, query: query)
    else
      @client.request(action: "DELETE",
        url: "/_db/#{@database.name}/_api/document/#{@id}", query: query)
    end
  end
end
