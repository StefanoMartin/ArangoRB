# === SERVER ===

class ArangoS
  include HTTParty

  @@verbose = false
  @@async = false
  @@database = "_system"
  @@graph = nil
  @@collection = nil
  @@user = nil
  @@request = {:body => {}, :headers => {}, :query => {}}

  def self.default_server(user: "root", password:, server: "localhost", port: "8529")
    base_uri "http://#{server}:#{port}"
    basic_auth user, password
  end

  def self.verbose=(verbose)
    @@verbose = verbose
  end

  def self.verbose
    @@verbose
  end

  def self.async=(async)
    @@async = async
    if async == true || async == "true"
      @@request[:headers] = {"x-arango-async" => "true"}
    elsif async == "store"
      @@request[:headers] = {"x-arango-async" => "store"}
    else
      @@request[:headers] = {}
    end
  end

  def self.async
    @@async
  end

  def self.database=(database)
    if database.is_a? String
      @@database = database
    elsif database.is_a? ArangoDB
      @@database = database.database
    else
      raise "database should be a String or an ArangoDB instance, not a #{database.class}"
    end
  end

  def self.database
    @@database
  end

  def self.graph=(graph)
    if graph.is_a? String
      @@graph = graph
    elsif graph.is_a? ArangoG
      @@graph = graph.graph
    else
      raise "graph should be a String or an ArangoG instance, not a #{graph.class}"
    end
  end

  def self.graph
    @@graph
  end

  def self.collection=(collection)
    if collection.is_a? String
      @@collection = collection
    elsif collection.is_a? ArangoC
      @@collection = collection.collection
    else
      raise "graph should be a String or an ArangoC instance, not a #{collection.class}"
    end
  end

  def self.collection
    @@collection
  end

  def self.user=(user)
    if user.is_a? String
      @@user = user
    elsif user.is_a? ArangoU
      @@user = user.user
    else
      raise "graph should be a String or an ArangoU instance, not a #{user.class}"
    end
  end

  def self.user
    @@user
  end

  def self.request
    @@request
  end

# === MONITORING ===

  def self.log
    result = get("/_admin/log", @@request)
    return_result result: result
    # @@verbose ? result : result["error"] ? result["errorMessage"] : result
  end

  def self.reload
    result = post("/_admin/routing/reload", @@request)
    return_result result: result, caseTrue: true
  end

  def self.statistics
    result = get("/_admin/statistics", @@request)
    return_result result: result
  end

  def self.statisticsDescription
    result = get("/_admin/statistics-description", @@request)
    return_result result: result
  end

  def self.role
    result = get("/_admin/server/role", @@request)
    return_result result: result, key: "role"
  end

  def self.server
    result = get("/_admin/server/id", @@request)
    return_result result: result
  end

  def self.clusterStatistics
    result = get("/_admin/clusterStatistics", @@request)
    return_result result: result
  end

# === ENDPOINTS ===

  def self.endpoints
    result = get("/_api/endpoint", @@request)
    return_result result: result
  end

  def self.users
    result = get("/_api/user", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result.parsed_response
      if @@verbose
        return result
      else
        if result["error"]
          return result["errorMessage"]
        else
          return result["result"].map{|x| ArangoU.new(user: x["user"], active: x["active"], extra: x["extra"])}
        end
      end
    end
  end

  # === BATCH ===

  def self.batch(queries:)
    headers = {
      "Content-Type": "multipart/form-data",
      "boundary": "XboundaryX"
    }
    body = ""
    queries.each{|query|
      body += "--XboundaryX\n"
      body += "Content-Type: application/x-arango-batchpart\n"
      body += "Content-Id: #{query[:id]}\n" unless query[:id].nil?
      body += "\n"
      body += "#{query[:type]} "
      body += "#{query[:address]} HTTP/1.1\n"
      body += "\n#{query[:body].to_json}\n" unless query[:body].nil?
    }
    body += "--XboundaryX--\n" if queries.length > 0
    request = @@request.merge({ :body => body, :headers => headers })
    result = post("/_api/batch", request)
    print result.parsed_response
  end

# === UTILITY ===

  def self.return_result(result:, caseTrue: false, key: nil)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose || !result.is_a?(Hash)
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          if caseTrue
            true
          elsif key.nil?
            result.delete_if{|k,v| k == "error" || k == "code"}
          else
            result[key]
          end
        end
      end
    end
  end
end
