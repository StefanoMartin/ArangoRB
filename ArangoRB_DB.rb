# === DATABASE ===

class ArangoDB < ArangoS
  def initialize(database: @@database)
    if database.is_a?(String)
      @database = database
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

  def self.create(database: @@database, username: nil, passwd: nil, users: nil, itself: true)
    body = {
      "name" => database,
      "username" => username,
      "passwd" => passwd,
      "users" => users
    }
    body = body.delete_if{|k,v| v.nil?}.to_json
    new_DB = { :body => body }
    result = post("/_api/database", new_DB)
    if itself
      @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
    else
      @@verbose ? result : result["error"] ? result["errorMessage"] : self
    end
  end

  # === DELETE ===

  def self.destroy(database: @@database)
    result = delete("/_api/database/#{database}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === LISTS ===

  def self.databases(user: nil)
    result = user.nil? ? get("/_api/database") : get("/_api/database/#{user}")
    @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  def self.collections(database: @@database, excludeSystem: true)
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

  def self.graphs(database: @@database)
    result = get("/_db/#{database}/_api/gharial")
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

  # === FROM INSTANCE ===

  def create(username: nil, passwd: nil, users: nil)
    ArangoDB.create(database: @database, username: username, passwd: passwd, users: users, itself: false)
  end

  def destroy
    ArangoDB.destroy(database: @database)
  end

  def collections(excludeSystem: true)
    ArangoDB.collections(database: @database, excludeSystem: true)
  end

  def graphs
    ArangoDB.graphs(database: @database, excludeSystem: true)
  end
end
