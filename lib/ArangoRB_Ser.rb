# === SERVER ===

class ArangoServer
  include HTTParty

  @@verbose = false
  @@async = false
  @@database = "_system"
  @@graph = nil
  @@collection = nil
  @@user = nil
  @@request = {:body => {}, :headers => {}, :query => {}}
  @@password = ""
  @@username = ""
  @@server = "localhost"
  @@port = "8529"

  def self.default_server(user: @@username, password: @@password = "", server: @@server, port: @@port) # TESTED
    base_uri "http://#{server}:#{port}"
    basic_auth user, password
    @@username = user
    @@password = password
    @@server = server
    @@port = port
  end

  def self.address  # TESTED
    "#{@@server}:#{@@port}"
  end

  def self.username  # TESTED
    @@username
  end

  def self.verbose=(verbose) # TESTED
    @@verbose = verbose
  end

  def self.verbose  # TESTED
    @@verbose
  end

  def self.async=(async)  # TESTED
    @@async = async
    if async == true || async == "true"
      @@request[:headers] = {"x-arango-async" => "true"}
    elsif async == "store"
      @@request[:headers] = {"x-arango-async" => "store"}
    else
      @@request[:headers] = {}
    end
  end

  def self.async  # TESTED
    @@async
  end

  def self.database=(database)  # TESTED
    if database.is_a? String
      @@database = database
    elsif database.is_a? ArangoDatabase
      @@database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end
  end

  def self.database  # TESTED
    @@database
  end

  def self.graph=(graph)  # TESTED
    if graph.is_a? String
      @@graph = graph
    elsif graph.is_a? ArangoGraph
      @@graph = graph.graph
    else
      raise "graph should be a String or an ArangoGraph instance, not a #{graph.class}"
    end
  end

  def self.graph  # TESTED
    @@graph
  end

  def self.collection=(collection)  # TESTED
    if collection.is_a? String
      @@collection = collection
    elsif collection.is_a? ArangoCollection
      @@collection = collection.collection
    else
      raise "graph should be a String or an ArangoCollection instance, not a #{collection.class}"
    end
  end

  def self.collection  # TESTED
    @@collection
  end

  def self.user=(user)
    if user.is_a? String
      @@user = user
    elsif user.is_a? ArangoUser
      @@user = user.user
    else
      raise "graph should be a String or an ArangoUser instance, not a #{user.class}"
    end
  end

  def self.user # TESTED
    @@user
  end

  def self.request # TESTED
    @@request
  end

# === MONITORING ===

  def self.log  # TESTED
    result = get("/_admin/log", @@request)
    return_result result: result
  end

  def self.reload # TESTED
    result = post("/_admin/routing/reload", @@request)
    return_result result: result, caseTrue: true
  end

  def self.statistics # TESTED
    result = get("/_admin/statistics", @@request)
    return_result result: result
  end

  def self.statisticsDescription # TESTED
    result = get("/_admin/statistics-description", @@request)
    return_result result: result
  end

  def self.role # TESTED
    result = get("/_admin/server/role", @@request)
    return_result result: result, key: "role"
  end

  def self.server # TESTED
    result = get("/_admin/server/id", @@request)
    return_result result: result
  end

  def self.clusterStatistics # TESTED
    result = get("/_admin/clusterStatistics", @@request)
    return_result result: result
  end

# === ENDPOINTS ===

  def self.endpoints # TESTED
    result = get("/_api/endpoint", @@request)
    return_result result: result
  end

  def self.users # TESTED
    result = get("/_api/user", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        return result
      else
        if result["error"]
          return result["errorMessage"]
        else
          return result["result"].map{|x| ArangoUser.new(user: x["user"], active: x["active"], extra: x["extra"])}
        end
      end
    end
  end

  # === BATCH ===

  def self.batch(queries:) # TESTED
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
    return_result result: result
  end

  def self.destroyDumpBatch(id:, dbserver: nil) # TESTED
    query = {"DBserver" => dbserver}.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = delete("/_api/replication/batch/#{id}", request)
    return true if result.nil?
    return result["errorMessage"] if result["error"]
  end

  def self.createDumpBatch(ttl:, dbserver: nil) # TESTED
    query = {"DBserver" => dbserver}.delete_if{|k,v| v.nil?}
    body = { "ttl" => ttl }
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = post("/_api/replication/batch", request)
    return_result result: result, key: "id"
  end

  def self.prolongDumpBatch(id:, ttl:, dbserver: nil) # TESTED
    query = {"DBserver" => dbserver}.delete_if{|k,v| v.nil?}
    body = { "ttl" => ttl }
    request = @@request.merge({ :body => body.to_json, :query => query })
    result = post("/_api/replication/batch/#{id}", request)
    return_result result: result, key: "id"
  end

# === REPLICATION ===

  def self.serverId # TESTED
    result = get("/_api/replication/server-id", @@request)
    return_result result: result, key: "serverId"
  end

# === SHARDING ===

  def self.clusterRoundtrip
    result = get("/_admin/cluster-test", @@request)
    return_result result: result
  end

  def self.executeCluster(body:)
    request = @@request.merge({ "body" => body.to_json })
    result = post("/_admin/cluster-test", request)
    return_result result: result
  end

  def self.executeCluster2(body:)
    request = @@request.merge({ "body" => body.to_json })
    result = put("/_admin/cluster-test", request)
    return_result result: result
  end

  def self.destroyCluster
    result = delete("/_admin/cluster-test", @@request)
    return_result result: result, caseTrue: true
  end

  def self.updateCluster(body:)
    request = @@request.merge({ "body" => body.to_json })
    result = patch("/_admin/cluster-test", request)
    return_result result: result, caseTrue: true
  end

  def self.headCluster(body:)
    result = head("/_admin/cluster-test", @@request)
    return_result result: result
  end

  def self.checkPort(port:)
    query = {"port": port}
    request = @@request.merge({ "query" => query })
    result = get("/_admin/clusterCheckPort", request)
    return_result result: result
  end

# === TASKS ===

  def self.tasks # TESTED
    result = get("/_api/tasks", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result.is_a?(Hash) && result["error"]
          result["errorMessage"]
        else
          result.map{|x| ArangoTask.new(id: x["id"], name: x["name"], type: x["type"], period: x["period"], created: x["created"], command: x["command"], database: x["database"])}
        end
      end
    end
  end

# === MISCELLANEOUS FUNCTIONS ===

  def self.version(details: nil) # TESTED
    query = {"details": details}
    request = @@request.merge({ "query" => query })
    result = get("/_api/version", request)
    return_result result: result
  end

  def self.flushWAL(waitForSync: nil, waitForCollector: nil) # TESTED
    body = {
      "waitForSync" => waitForSync,
      "waitForCollector" => waitForCollector
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = put("/_admin/wal/flush", request)
    return_result result: result, caseTrue: true
  end

  def self.propertyWAL # TESTED
    result = put("/_admin/wal/properties", @@request)
    return_result result: result
  end

  def self.changePropertyWAL(allowOversizeEntries: nil, logfileSize: nil, historicLogfiles: nil, reserveLogfiles: nil, throttleWait: nil, throttleWhenPending: nil) # TESTED
    body = {
      "allowOversizeEntries" => allowOversizeEntries,
      "logfileSize" => allowOversizeEntries,
      "historicLogfiles" => historicLogfiles,
      "reserveLogfiles" => reserveLogfiles,
      "throttleWait" => throttleWait,
      "throttleWhenPending" => throttleWhenPending
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = put("/_admin/wal/properties", request)
    return_result result: result
  end

  def self.transactions # TESTED
    result = get("/_admin/wal/transactions", @@request)
    return_result result: result
  end

  def self.time # TESTED
    result = get("/_admin/time", @@request)
    return_result result: result, key: "time"
  end

  def self.echo # TESTED
    result = get("/_admin/echo", @@request)
    return_result result: result
  end

  # def self.longEcho body: {}
  #   request = @@request.merge({ :body => body.to_json })
  #   result = get("/_admin/long_echo", request)
  #   return_result result: result
  # end

  def self.databaseVersion # TESTED
    result = get("/_admin/database/target-version", @@request)
    return_result result: result, key: "version"
  end

  def self.sleep(duration:) # TESTED
    query = {"duration": duration}
    request = @@request.merge({ "query" => query })
    result = get("/_admin/sleep", request)
    return_result result: result, key: "duration"
  end

  def self.shutdown # TESTED
    result = delete("/_admin/shutdown", @@request)
    return_result result: result, caseTrue: true
  end

  def self.restart
    `sudo service arangodb restart`
  end

  def self.test(body:)
    request = @@request.merge({ "body" => body.to_json })
    result = post("/_admin/test", request)
    return_result result: result
  end

  def self.execute(body:)
    request = @@request.merge({ "body" => body.to_json })
    result = post("/_admin/execute", request)
    return_result result: result
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
