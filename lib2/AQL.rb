# === AQL ===

module Arango
  class AQL
    def initialize(query:, database:, client:, batchSize: nil, ttl: nil, cache: nil, options: nil, bindVars: nil)
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(query, "query", [Arango::AQL, String])
      satisfy_class?(client, "client", [Arango::Client])
      @query = query.is_a?(String) ? query : query.query
      @database = database.is_a?(String) ? database : database.database
      @client = client
      @batchSize = batchSize
      @ttl = ttl
      @cache = cache
      @options = options
      @bindVars = bindVars
      @count = true
      @quantity = nil
      @hasMore = false
      @id = ""
      @result = []
    end

    attr_accessor :count, :query, :batchSize, :ttl, :cache, :options, :bindVars, :quantity
    attr_reader :hasMore, :id, :result
    alias size batchSize
    alias size= batchSize=

# === RETRIEVE ===

    def to_hash
      {
        "query" => @query,
        "database" => @database,
        "result" => @result.map{|x| x.is_a?(ArangoServer) ? x.to_h : x},
        "count" => @count,
        "quantity" => @quantity,
        "ttl" => @ttl,
        "cache" => @cache,
        "batchSize" => @batchSize,
        "bindVars" => @bindVars,
        "options" => @options,
        "idCache" => @idCache,
      }.delete_if{|k,v| v.nil?}
    end
    alias to_h to_hash

    def database
      Arango::Database.new(database: @database, client: @client)
    end

# === EXECUTE QUERY ===

    def execute # TESTED
      body = {
        "query" => @query,
        "count" => count,
        "batchSize" => @batchSize,
        "ttl" => @ttl,
        "cache" => @cache,
        "options" => @options,
        "bindVars" => @bindVars
      }
      result = @client.request(action: "POST", url: "/_db/#{@database}/_api/cursor", body: body)
      return result if @client.async != false
      @quantity = result["count"]
      @hasMore = result["hasMore"]
      @id = result["id"]
      if (result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        @result = result["result"]
      else
        @result = result["result"].map do |x|
          Arango::Document.new(key: x["_key"],
            collection: x["_id"].split("/")[0], database: @database, body: x, client: @client)
        end
      end
      return self
    end

    def next
      unless @hasMore
        Arango::Error message: "No other results"
      else
        result = @client.request(action: "PUT", url: "/_db/#{@database}/_api/cursor/#{@id}")
        return result if @client.async != false
        @count = result["count"]
        @hasMore = result["hasMore"]
        @id = result["id"]
        if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
          @result = result["result"]
        else
          @result = result["result"].map do |x|
            Arango::Document.new(key: x["_key"],
              collection: x["_id"].split("/")[0], database: @database, body: x, client: @client)
          end
        end
        return self
      end
    end

# === PROPERTY QUERY ===

    def explain
      body = {
        "query" => @query,
        "options" => @options,
        "bindVars" => @bindVars
      }
      @client.request(action: "POST", url: "/_db/#{@database}/_api/explain", body: body)
    end

    def parse
      body = { "query" => @query }
      @client.request(action: "POST", url: "/_db/#{@database}/_api/query", body: body)
    end

    def properties
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/properties")
    end

    def current
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/current")
    end

    def slow
      @client.request(action: "GET", url: "/_db/#{@database}/_api/query/slow")
    end

# === DELETE ===

    def stopSlow
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/query/slow")
    end

    def kill(id: @id)
      @client.request(action: "DELETE", url: "/_db/#{@database}/_api/query/#{id}")
    end

    def changeProperties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)
      body = {
        "slowQueryThreshold" => slowQueryThreshold,
        "enabled" => enabled,
        "maxSlowQueries" => maxSlowQueries,
        "trackSlowQueries" => trackSlowQueries,
        "maxQueryStringLength" => maxQueryStringLength
      }
      @client.request(action: "PUT", url: "/_db/#{@database}/_api/query/properties", body: body)
      result = self.class.put("/_db/#{@database}/_api/query/properties", request)
    end
  end
end
