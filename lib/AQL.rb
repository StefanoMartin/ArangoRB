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
      @query = query.is_a?(String) ? query: query.query
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
      ["failOnWarning", "profile", "maxTransactionSize",
      "skipInaccessibleCollections", "maxWarningCount", "intermediateCommitCount",
      "satelliteSyncWait", "fullCount", "intermediateCommitSize",
      "optimizer_rules", "maxPlans"].each do |param_name|
        param = eval(param_name)
        set_option(param, param_name)
        define_singleton_method("#{param_name}=") do |value|
          set_option(value, param_name)
        end
      end
    end

# === DEFINE ===

    attr_accessor :count, :query, :batchSize, :ttl, :cache, :options, :bindVars, :quantity
    attr_reader :hasMore, :id, :result, :idCache, :failOnWarning, :profile,
      :maxTransactionSize, :skipInaccessibleCollections, :maxWarningCount,
      :intermediateCommitCount, :satelliteSyncWait, :fullCount, :server, :cached, :extra,
      :intermediateCommitSize, :optimizer_rules, :maxPlans, :database
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

    def to_h
      {
        "query":       @query,
        "result":      @result,
        "count":       @count,
        "quantity":    @quantity,
        "ttl":         @ttl,
        "cache":       @cache,
        "batchSize":   @batchSize,
        "bindVars":    @bindVars,
        "options":     @options,
        "idCache":     @idCache,
        "memoryLimit": @memoryLimit,
        "database":    @database.name
      }.delete_if{|k,v| v.nil?}
    end

# === REQUEST ===

    def return_aql(result)
      return result if @server.async != false
      @extra    = result[:extra]
      @cached   = result[:cached]
      @quantity = result[:count]
      @hasMore  = result[:hasMore]
      @id       = result[:id]
      if(result[:result][0].nil? || !result[:result][0].is_a?(Hash) || !result[:result][0].key?(:_key))
        @result = result[:result]
      else
        @result = result[:result].map do |x|
          collection = Arango::Collection.new(name: x[:_id].split("/")[0], database: @database)
          Arango::Document.new(name: x[:_key], collection: collection, body: x)
        end
      end
      return return_directly?(result) ? result: self
    end
    private :return_aql

  # === EXECUTE QUERY ===

    def execute
      body = {
        "query":       @query,
        "count":       @count,
        "batchSize":   @batchSize,
        "ttl":         @ttl,
        "cache":       @cache,
        "options":     @options,
        "bindVars":    @bindVars,
        "memoryLimit": @memoryLimit
      }
      result = @database.request("POST", "_api/cursor", body: body)
      return_aql(result)
    end

    def next
      if @hasMore
        result = @database.request("PUT", "_api/cursor/#{@id}")
        return_aql(result)
      else
        raise Arango::Error.new err::no_other_aql_next, data: {"hasMore": false}
      end
    end

    def destroy
      @database.request("DELETE", "_api/cursor/#{@id}")
    end

# === PROPERTY QUERY ===

    def explain
      body = {
        "query":    @query,
        "options":  @options,
        "bindVars": @bindVars
      }
      @database.request("POST", "_api/explain", body: body)
    end

    def parse
      @database.request("POST", "_api/query", body: {"query": @query})
    end

    def kill(id: @id)
      @database.request("DELETE", "_api/query/#{id}")
    end
  end
end
