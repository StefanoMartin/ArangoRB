# === SERVER ===

class ArangoS
  include HTTParty
  @@verbose = false
  @@database = "_system"
  @@graph = nil
  @@collection = nil
  @@user = nil

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

# === MONITORING ===

  def self.log
    self.class.get("/_admin/log").parsed_response
  end

  def self.reload
    self.class.post("/_admin/reload").parsed_response
  end

  def self.statistics
    self.class.get("/_admin/statistics").parsed_response
  end

  def self.statisticsDescription
    self.class.get("/_admin/statistics-description").parsed_response
  end

  def self.role
    self.class.get("/_admin/server/role").parsed_response
  end

  def self.server
    self.class.get("/_admin/server/id").parsed_response
  end

  def self.clusterStatistics
    self.class.get("/_admin/clusterStatistics").parsed_response
  end

# === ENDPOINTS ===

  def self.endpoints
    self.class.get("/_api/endpoint").parsed_response
  end

  def self.users
    result = self.class.get("/_api/user").parsed_response
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
