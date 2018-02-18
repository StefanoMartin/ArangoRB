# === AQL ===

module Arango
  class AQL
    def initialize(query: nil, batchSize: nil, ttl: nil, cache: nil, options: nil, bindVars: nil, database:, memoryLimit: nil, count: true)
      satisfy_class?(database, "database", [Arango::Database, String])
      satisfy_class?(query, "query", [Arango::AQL, String])
      if query.is_a?(String)
        @query = query
      elsif query.is_a?(ArangoAQL)
        @query = query.query
      end
      @database = database
      @batchSize = batchSize
      @ttl = ttl
      @cache = cache
      @options = options
      @bindVars = bindVars
      @memoryLimit = memoryLimit

      @count = count
      @quantity = nil
      @hasMore = false
      @id = ""
      @result = []
    end

    attr_accessor :count, :query, :batchSize, :ttl, :cache, :options, :bindVars, :quantity
    attr_reader :hasMore, :id, :result, :idCache
    alias size batchSize
    alias size= batchSize=

  # === RETRIEVE ===

    def to_hash
      {
        "query" => @query,
        "database" => @database,
        "result" => @result,
        "count" => @count,
        "quantity" => @quantity,
        "ttl" => @ttl,
        "cache" => @cache,
        "batchSize" => @batchSize,
        "bindVars" => @bindVars,
        "options" => @options,
        "idCache" => @idCache,
        "memoryLimit" => @memoryLimit
      }.delete_if{|k,v| v.nil?}
    end
    alias to_h to_hash

    def return_aql(result)
      return result if @database.client.async != false
      @quantity = result["count"]
      @hasMore = result["hasMore"]
      @id = result["id"]
      if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        @result = result["result"]
      else
        @result = result["result"].map{|x|
          collection = Arango::Collection.new(name: x["_id"].split("/")[0], database: @database)
          Arango::Document.new(key: x["_key"], collection: collection, database: @database, body: x)
        end
      end
      return return_directly?(result) ? result : self
    end

  # === EXECUTE QUERY ===

    def execute
      body = {
        "query" => @query,
        "count" => count,
        "batchSize" => @batchSize,
        "ttl" => @ttl,
        "cache" => @cache,
        "options" => @options,
        "bindVars" => @bindVars,
        "memoryLimit" => @memoryLimit
      }
      result = @database.request(action: "POST", url: "_api/cursor", body: body)
      return_aql(result)
    end

    def next
      unless @hasMore
        Arango::Error message: "No other results"
      else
        result = @database.request(action: "PUT", url: "_api/cursor/#{@id}")
        return_aql(result)
      end
    end

    def destroy
      @database.request(action: "DELETE", url: "_api/cursor/#{@id}")
    end

# === PROPERTY QUERY ===

    def explain
      body = {
        "query" => @query,
        "options" => @options,
        "bindVars" => @bindVars
      }
      @database.request(action: "POST", url: "/_api/explain", body: body)
    end

    def parse
      body = { "query" => @query }
      @database.request(action: "POST", url: "/_api/query", body: body)
    end

    # def self.properties(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "GET", url: "/_api/query/properties")
    # end

    # def self.current(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "GET", url: "/_api/query/current")
    # end

    # def self.slow(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "GET", url: "/_api/query/slow")
    # end

# === UPDATE ===

    def self.changeProperties(database:, slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil, trackBindVars: trackBindVars)
      satisfy_class?(database, "database", [Arango::Database])
      body = {
        "slowQueryThreshold" => slowQueryThreshold,
        "enabled" => enabled,
        "maxSlowQueries" => maxSlowQueries,
        "trackSlowQueries" => trackSlowQueries,
        "maxQueryStringLength" => maxQueryStringLength,
        "trackBindVars" => trackBindVars
      }
      database.request(action: "PUT", url: "_api/query/properties", body: body)
    end

# === DELETE ===

    # def self.stopSlow(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "DELETE", url: "_api/query/slow")
    # end

    def kill(id: @id) # TESTED
      @database.request(action: "DELETE", url: "query/#{id}")
    end

# === CACHE ===

    # def self.clearCache(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "DELETE", url: "_api/query-cache")
    # end

    # def self.propertyCache(database:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "GET", url: "_api/query-cache/properties")
    # end

    # def self.changePropertyCache(database:, mode: nil, maxResults: nil)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   body = { "mode" => mode, "maxResults" => maxResults }
    #   database.request(action: "PUT",
    #     url: "_api/query-cache/properties",
    #     body: body)
    # end

# === FUNCTION ===

    # def self.functions(database:, namespace: nil)
    #   query = {"namespace" => namespace}
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "GET", url: "_api/aqlfunction",
    #     query: query)
    # end

    # def self.createFunction(database:, code:, name:, isDeterministic: nil)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   body = {
    #     "code" => code,
    #     "name" => name,
    #     "isDeterministic" => isDeterministic
    #   }
    #   database.request(action: "POST",
    #     url: "_api/aqlfunction",
    #     body: body)
    # end
    #
    # def self.deleteFunction(database:, name:)
    #   satisfy_class?(database, "database", [Arango::Database])
    #   database.request(action: "DELETE",
    #     url: "_api/aqlfunction/#{name}")
    # end
  end
end
