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

  # === FROM INSTANCE ===

  # def create(username: nil, passwd: nil, users: nil)
  #   ArangoDB.create(database: @database, username: username, passwd: passwd, users: users)
  # end
  #
  # def destroy
  #   ArangoDB.destroy(database: @database)
  # end

  # def collections(excludeSystem: true)
  #   ArangoDB.collections(database: @database, excludeSystem: true)
  # end
  #
  # def graphs
  #   ArangoDB.graphs(database: @database, excludeSystem: true)
  # end
end
