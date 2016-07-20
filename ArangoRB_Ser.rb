# === SERVER ===

class ArangoS
  include HTTParty
  @@verbose = false
  @@database = "_system"
  @@graph = ""

  def self.default_server(username: "root", password:, server: "localhost", port: "8529")
    base_uri "http://#{server}:#{port}"
    basic_auth username, password
  end

  def self.verbose=(verbose)
    @@verbose = verbose
  end

  def self.verbose
    @@verbose
  end

  def self.database=(database)
    @@database = database
  end

  def self.database
    @@database
  end

  def self.graph=(graph)
    @@graph = graph
  end

  def self.graph
    @@graph
  end
end
