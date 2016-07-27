# === AQL ===

class ArangoAQL < ArangoS
  def initialize(query: nil, batchSize: nil, ttl: nil, cache: nil, options: nil, bindVars: nil, database: @@database)
    if query.is_a?(String)
      @query = query
    elsif query.is_a?(ArangoAQL)
      @query = query.query
    else
      raise "query should be String or ArangoAQL instance, not a #{query.class}"
    end
    @database = database
    @batchSize = batchSize
    @ttl = ttl
    @cache = cache
    @options = options
    @bindVars = bindVars

    @count = 0
    @hasMore = false
    @id = ""
    @result = []
  end

  attr_accessor :query, :batchSize, :ttl, :cache, :options, :bindVars
  attr_reader :count, :database, :count, :hasMore, :id, :result
  alias size batchSize
  alias size= batchSize=

# === EXECUTE QUERY ===

  def execute(count: true)
    body = {
      "query" => @query,
      "count" => count,
      "batchSize" => @batchSize,
      "ttl" => @count,
      "cache" => @cache,
      "options" => @options,
      "bindVars" => @bindVars
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/cursor", new_Document).parsed_response
    if result["error"]
      return @@verbose ? result : result["errorMessage"]
    else
      @count = result["count"]
      @hasMore = result["hasMore"]
      @id = result["id"]
      if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
        @result = result["result"]
      else
        @result = result["result"].map{|x| ArangoDoc.new(
          key: x["_key"],
          collection: x["_id"].split("/")[0],
          database: @database,
          body: x
        )}
      end
      return @@verbose ? result : self
    end
  end

  def next
    unless @hasMore
      print "No other results"
    else
      result = self.class.put("/_db/#{@database}/_api/cursor/#{@id}")
      if result["error"]
        return @@verbose ? result : result["errorMessage"]
      else
        @count = result["count"]
        @hasMore = result["hasMore"]
        @id = result["id"]
        if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
          @result = result["result"]
        else
          @result = result["result"].map{|x| ArangoDoc.new(
            key: x["_key"],
            collection: x["_id"].split("/")[0],
            database: @database,
            body: x
          )}
        end
        return @@verbose ? result : self
      end
    end
  end

  # === PROPERTY QUERY ===

  def explain
    body = {
      "query" => @query,
      "options" => @options,
      "bindVars" => @bindVars
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/explain", new_Document).parsed_response
    return_result(result)
  end

  def parse
    body = { "query" => @query }
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/query", new_Document).parsed_response
    return_result(result)
  end

  def properties
    result = self.class.get("/_db/#{@database}/_api/query/properties").parsed_response
    return_result(result)
  end

  def current
    self.class.get("/_db/#{@database}/_api/query/current").parsed_response
  end

  def slow
    self.class.get("/_db/#{@database}/_api/query/slow").parsed_response
  end

# === DELETE ===

  def stopSlow
    result = self.class.delete("/_db/#{@database}/_api/query/slow").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def kill(id: @id)
    result = self.class.delete("/_db/#{@database}/_api/query/#{id}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def changeProperties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)
    body = {
      "slowQueryThreshold" => slowQueryThreshold,
      "enabled" => enabled,
      "maxSlowQueries" => maxSlowQueries,
      "trackSlowQueries" => trackSlowQueries,
      "maxQueryStringLength" => maxQueryStringLength
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json }
    result = self.class.put("/_db/#{@database}/_api/query/properties", new_Document).parsed_response
    return_result(result)
  end

# === CACHE ===

  def clearCache
    result = self.class.delete("/_db/#{@database}/_api/query-cache").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def propertyCache
    self.class.get("/_db/#{@database}/_api/query-cache/properties").parsed_response
  end

  def changePropertyCache(mode: nil, maxResults: nil)
    body = { "mode" => mode, "maxResults" => maxResults }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json }
    self.class.put("/_db/#{@database}/_api/query-cache/properties", new_Document).parsed_response
  end

# === AQL FUNCTION ===

  def createFunction(code:, name:, isDeterministic: nil)
    body = {
      "code" => code,
      "name" => name,
      "isDeterministic" => isDeterministic
    }.delete_if{|k,v| v.nil?}
    new_Document = { :body => body.to_json }
    result = self.class.post("/_db/#{@database}/_api/aqlfunction", new_Document).parsed_response
    return_result(result)
  end

  def deleteFunction(name:)
    result = self.class.delete("/_db/#{@database}/_api/aqlfunction/#{name}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def functions
    self.class.get("/_db/#{@database}/_api/aqlfunction").parsed_response
  end

# === UTILITY ===

  def return_result(result)
    if @@verbose
      result
    else
      if result["error"]
        result["errorMessage"]
      else
        result.delete("error")
        result.delete("code")
        result
      end
    end
  end
end
