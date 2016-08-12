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
  @@username = "root"
  @@server = "localhost"
  @@port = "8529"
  @@cluster = "cluster-test"

  def self.default_server(user: @@username, password: @@password, server: @@server, port: @@port) # TESTED
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
    ArangoDatabase.new(database: @@database)
  end

  def self.database  # TESTED
    ArangoDatabase.new(database: @@database)
  end

  def self.graph=(graph)  # TESTED
    if graph.is_a? String
      @@graph = graph
    elsif graph.is_a? ArangoGraph
      @@graph = graph.graph
    else
      raise "graph should be a String or an ArangoGraph instance, not a #{graph.class}"
    end
    ArangoGraph.new(database: @@database, graph: @@graph)
  end

  def self.graph  # TESTED
    ArangoGraph.new(database: @@database, graph: @@graph)
  end

  def self.collection=(collection)  # TESTED
    if collection.is_a? String
      @@collection = collection
    elsif collection.is_a? ArangoCollection
      @@collection = collection.collection
    else
      raise "graph should be a String or an ArangoCollection instance, not a #{collection.class}"
    end
    ArangoCollection.new(database: @@database, collection: @@collection)
  end

  def self.collection  # TESTED
    ArangoCollection.new(database: @@database, collection: @@collection)
  end

  def self.user=(user)
    if user.is_a? String
      @@user = user
    elsif user.is_a? ArangoUser
      @@user = user.user
    else
      raise "graph should be a String or an ArangoUser instance, not a #{user.class}"
    end
    ArangoUser.new(user: @@user)
  end

  def self.user # TESTED
    ArangoUser.new(user: @@user)
  end

  def self.request # TESTED
    @@request
  end

  def self.cluster
    @@cluster
  end

  def self.cluster=(cluster)
    @@cluster = cluster
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

  def self.statistics description: false # TESTED
    if description
      result = get("/_admin/statistics-description", @@request)
    else
      result = get("/_admin/statistics", @@request)
    end
    return_result result: result
  end

  def self.role # TESTED
    result = get("/_admin/server/role", @@request)
    return_result result: result, key: "role"
  end

  def self.server
    result = get("/_admin/server/id", @@request)
    return_result result: result
  end

  def self.clusterStatistics dbserver:
    query = {"DBserver": dbserver}
    request = @@request.merge({ :query => query })
    result = get("/_admin/clusterStatistics", request)
    return_result result: result
  end

# === LISTS ===

  def self.endpoints # TESTED
    result = get("/_api/endpoint", @@request)
    return_result result: result
  end

  def self.users # TESTED
    result = get("/_api/user", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"].map{|x| ArangoUser.new(user: x["user"], active: x["active"], extra: x["extra"])}
  end

  def self.databases(user: nil) # TESTED
    ArangoDatabase.databases user: user
  end


  def self.tasks # TESTED
    result = get("/_api/tasks", @@request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @@verbose ? result : (result.is_a?(Hash) && result["error"]) ? result["errorMessage"] : result.map{|x| ArangoTask.new(id: x["id"], name: x["name"], type: x["type"], period: x["period"], created: x["created"], command: x["command"], database: x["database"])}
  end

  # === ASYNC ===

  def self.pendingAsync # TESTED
    result = get("/_api/job/pending")
    return_result_async result: result
  end

  def self.fetchAsync(id:) # TESTED
    result = put("/_api/job/#{id}")
    return_result_async result: result
  end

  def self.retrieveAsync(type: nil, id: nil) # TESTED
    result = id.nil? ? get("/_api/job/#{type}") : get("/_api/job/#{id}")
    return_result_async result: result
  end

  def self.retrieveDoneAsync # TESTED
    retrieveAsync(type: "done")
  end

  def self.retrievePendingAsync # TESTED
    retrieveAsync(type: "pending")
  end

  def self.cancelAsync(id:) # TESTED
    result = put("/_api/job/#{id}/cancel")
    return_result_async result: result
  end

  def self.destroyAsync(type: nil, id: nil) # TESTED
    result = id.nil? ? delete("/_api/job/#{type}") : delete("/_api/job/#{id}")
    return_result_async result: result, caseTrue: true
  end

  def self.destroyAllAsync # TESTED
    destroyAsync(type: "all")
  end

  def self.destroyExpiredAsync # TESTED
    destroyAsync(type: "expired")
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

  def self.clusterRoundtrip(cluster: @@cluster)
    result = get("/_admin/#{cluster}", @@request)
    return_result result: result
  end

  def self.executeCluster(body:, cluster: @@cluster)
    request = @@request.merge({ "body" => body.to_json })
    result = post("/_admin/#{cluster}", request)
    return_result result: result
  end

  def self.executeClusterPut(body:, cluster: @@cluster)
    request = @@request.merge({ "body" => body.to_json })
    result = put("/_admin/#{cluster}", request)
    return_result result: result
  end

  def self.destroyCluster(cluster: @@cluster)
    result = delete("/_admin/#{cluster}", @@request)
    return_result result: result, caseTrue: true
  end

  def self.updateCluster(body:, cluster: @@cluster)
    request = @@request.merge({ "body" => body.to_json })
    result = patch("/_admin/#{cluster}", request)
    return_result result: result, caseTrue: true
  end

  def self.executeClusterHead(body:, cluster: @@cluster)
    result = head("/_admin/#{cluster}", @@request)
    return_result result: result
  end

  def self.checkPort(port:)
    query = {"port": port}
    request = @@request.merge({ "query" => query })
    result = get("/_admin/clusterCheckPort", request)
    return_result result: result
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
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    return result if @@verbose || !result.is_a?(Hash)
    return result["errorMessage"] if result["error"]
    return true if caseTrue
    return key.nil? ? result.delete_if{|k,v| k == "error" || k == "code"} : result[key]
  end

  def self.return_result_async(result:, caseTrue: false)
    result = result.parsed_response
    (@@verbose || !result.is_a?(Hash)) ? result : result["error"] ? result["errorMessage"] : caseTrue ? true : result.delete_if{|k,v| k == "error" || k == "code"}
  end
end
