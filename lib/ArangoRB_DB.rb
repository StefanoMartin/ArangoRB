# === DATABASE ===

class ArangoDB < ArangoS
  def initialize(database: @@database)
    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String, not a #{database.class}"
    end
  end

  attr_reader :database

  # === GET ===

  def self.info
    result = get("/_api/database/current")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === POST ===

  def create(username: nil, passwd: nil, users: nil)
    body = {
      "name" => @database,
      "username" => username,
      "passwd" => passwd,
      "users" => users
    }
    body = body.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = self.class.post("/_api/database", new_DB)
    @@verbose ? result : result["error"] ? result["errorMessage"] : ArangoDB.new(database: @database)
  end

  # === DELETE ===

  def destroy
    result = self.class.delete("/_api/database/#{@database}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === LISTS ===

  def self.databases(user: nil)
    result = user.nil? ? get("/_api/database") : get("/_api/database/#{user}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoDB.new(database: x)}
  end

  def collections(excludeSystem: true)
    query = { "excludeSystem": excludeSystem }.delete_if{|k,v| v.nil?}
    new_Document = { :query => query }
    result = self.class.get("/_db/#{@database}/_api/collection", new_Document)
    if @@verbose
      return result
    else
      if result["error"]
        return result["errorMessage"]
      else
        return result["result"].map{|x| ArangoC.new(database: @database, collection: x["name"])}
      end
    end
  end

  def graphs
    result = self.class.get("/_db/#{@database}/_api/gharial")
    if @@verbose
      return result
    else
      if result["error"]
        return result["errorMessage"]
      else
        return result["graphs"].map{|x| ArangoG.new(database: @database, graph: x["_key"], edgeDefinitions: x["edgeDefinitions"], orphanCollections: x["orphanCollections"])}
      end
    end
  end

  def functions
    self.class.get("/_db/#{@database}/_api/aqlfunction").parsed_response
  end

  # === QUERY ===

  def propertiesQuery
    result = self.class.get("/_db/#{@database}/_api/query/properties").parsed_response
    return_result(result)
  end

  def currentQuery
    self.class.get("/_db/#{@database}/_api/query/current").parsed_response
  end

  def slowQuery
    self.class.get("/_db/#{@database}/_api/query/slow").parsed_response
  end

  def stopSlowQuery
    result = self.class.delete("/_db/#{@database}/_api/query/slow").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def killQuery(id:)
    result = self.class.delete("/_db/#{@database}/_api/query/#{id}").parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
  end

  def changePropertiesQuery(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)
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
    result = self.class.delete("/_db/#{@database}/_api/aqlfunction/#{name}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : true
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
