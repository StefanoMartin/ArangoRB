# === DATABASE ===

class ArangoDB < ArangoS
  # include HTTParty
  # @@verbose = false
  # @@database = "_system"

  # def self.database=(database)
  #   @@database = database
  # end
  #
  # def self.database
  #   @@database
  # end

  # def self.verbose=(verbose)
  #   @@verbose = verbose
  # end
  #
  # def self.verbose
  #   @@verbose
  # end

  # def self.default_server(username: "root", password:, server: "localhost", port: "8529")
  #   base_uri "http://#{server}:#{port}"
  #   basic_auth username, password
  # end

  # === GET ===

  def self.info
    result = get("/_api/database/current")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === POST ===

  def self.create(username: nil, passwd: nil, users: nil)
    body = {
      "name" => @@database,
      "username" => username,
      "passwd" => passwd,
      "users" => users
    }
    body = body.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = post("/_api/database", new_DB)
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === DELETE ===

  def self.destroy
    result = delete("/_api/database/#{@@database}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === LISTS ===

  def self.databases(user: nil)
    result = user.nil? ? get("/_api/database") : get("/_api/database/#{user}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  def self.collections(excludeSystem: true)
    query = { "excludeSystem": excludeSystem }.delete_if{|k,v| v.nil?}
    new_Document = { :query => query }
    result = get("/_db/#{@@database}/_api/collection", new_Document)
    if @@verbose
      return result
    else
      if result["error"]
        return result["errorMessage"]
      else
        return result["result"].map{|x| ArangoC.new(collection: x["name"])}
      end
    end
  end

  def self.graphs
    result = get("/_db/#{@@database}/_api/gharial")
    if @@verbose
      return result
    else
      if result["error"]
        return result["errorMessage"]
      else
        return result["graphs"].map{|x| ArangoG.new(graph: x["_key"], edgeDefinitions: x["edgeDefinitions"], orphanCollections: x["orphanCollections"])}
      end
    end
  end
end
