# === SERVER ===

class ArangoS
  include HTTParty
  @@verbose = false
  @@database = "_system"
  @@graph = nil
  @@collection = nil

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
      @@graph = graph
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
      @@collection = collection
    else
      raise "graph should be a String or an ArangoC instance, not a #{collection.class}"
    end
  end

  def self.collection
    @@collection
  end
end
