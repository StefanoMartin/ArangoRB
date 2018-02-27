# === AQL ===

module Arango
  class AQL
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(query:, database:, count: nil, batchSize: nil, cache: nil,
      memoryLimit: nil, ttl: nil, bindVars: nil, failOnWarning: nil,
      profile: nil, maxTransactionSize: nil, skipInaccessibleCollections: nil,
      maxWarningCount: nil, intermediateCommitCount: nil,
      satelliteSyncWait: nil, fullCount: nil, intermediateCommitSize: nil,
      optimizer_rules: nil, maxPlans: nil)
      satisfy_class?(query, [Arango::AQL, String])
      @query = query.is_a?(String) ? query : query.query
      assign_database(database)

      @count       = count
      @batchSize   = batchSize
      @cache       = cache
      @memoryLimit = memoryLimit
      @ttl         = ttl
      @bindVars    = bindVars

      @quantity = nil
      @hasMore  = false
      @id       = ""
      @result   = []
      @options  = {}
      # DEFINE
      [failOnWarning, profile, maxTransactionSize,
      skipInaccessibleCollections, maxWarningCount, intermediateCommitCount,
      satelliteSyncWait, fullCount, intermediateCommitSize,
      optimizer_rules, maxPlans].each do |val|
        name = val.object_id.to_s
        set_option(val, name)
        define_method("#{name}=") do |value|
          set_option(value, name)
        end
      end
    end

# === DEFINE ===

    attr_accessor :count, :query, :batchSize, :ttl, :cache, :options, :bindVars, :quantity
    attr_reader :hasMore, :id, :result, :idCache, :failOnWarning, :profile,
      :maxTransactionSize, :skipInaccessibleCollections, :maxWarningCount,
      :intermediateCommitCount, :satelliteSyncWait, :fullCount,
      :intermediateCommitSize, :optimizer_rules, :maxPlans, :database, :client, :cached, :extra
    alias size batchSize
    alias size= batchSize=

    def set_option(attrs, name)
      @options ||= {}
      instance_variable_set("@#{name}", attrs)
      unless attrs
        name = "optimizer.rules" if name == "optimizer_rules"
        @options[name] = attrs
      end
      @options.delete_if{|k,v| v.nil?}
      @options = nil if @options.empty?
    end
    private :set_option

  # === TO HASH ===

    def to_h(level=0)
      hash = {
        "query"       => @query,
        "database"    => @database,
        "result"      => @result,
        "count"       => @count,
        "quantity"    => @quantity,
        "ttl"         => @ttl,
        "cache"       => @cache,
        "batchSize"   => @batchSize,
        "bindVars"    => @bindVars,
        "options"     => @options,
        "idCache"     => @idCache,
        "memoryLimit" => @memoryLimit
      }.delete_if{|k,v| v.nil?}
      hash["database"] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === REQUEST ===

    def return_aql(result)
      return result if @client.async != false
      @extra    = result["extra"]
      @cached   = result["cached"]
      @quantity = result["count"]
      @hasMore  = result["hasMore"]
      @id       = result["id"]
      if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        @result = result["result"]
      else
        @result = result["result"].map{|x|
          collection = Arango::Collection.new(name: x["_id"].split("/")[0], database: @database)
          Arango::Document.new(name: x["_key"], collection: collection, database: @database, body: x)
        end
      end
      return return_directly?(result) ? result : self
    end

  # === EXECUTE QUERY ===

    def execute
      body = {
        "query"       => @query,
        "count"       => @count,
        "batchSize"   => @batchSize,
        "ttl"         => @ttl,
        "cache"       => @cache,
        "options"     => @options,
        "bindVars"    => @bindVars,
        "memoryLimit" => @memoryLimit
      }
      result = @database.request(action: "POST", url: "_api/cursor", body: body)
      return_aql(result)
    end

    def next
      if @hasMore
        result = @database.request(action: "PUT", url: "_api/cursor/#{@id}")
        return_aql(result)
      else
        raise Arango::Error.new message: "No other results"
      end
    end

    def destroy
      @database.request(action: "DELETE", url: "_api/cursor/#{@id}")
    end

# === PROPERTY QUERY ===

    def explain
      body = {
        "query"    => @query,
        "options"  => @options,
        "bindVars" => @bindVars
      }
      @database.request(action: "POST", url: "_api/explain", body: body)
    end

    def parse
      body = { "query" => @query }
      @database.request(action: "POST", url: "_api/query", body: body)
    end

    def kill(id: @id)
      @database.request(action: "DELETE", url: "_api/query/#{id}")
    end
  end
end
