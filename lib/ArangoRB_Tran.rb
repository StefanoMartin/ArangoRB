# === TRANSACTION ===

class ArangoTransaction < ArangoServer
  def initialize(database: @@database, action:, write: [], read: [], params: nil, lockTimeout: nil, waitForSync: nil) # TESTED
    if database.is_a?(String)
      @database = database
    elsif database.is_a?(ArangoDatabase)
      @database = database.database
    else
      raise "database should be a String or an ArangoDatabase instance, not a #{database.class}"
    end
    @action = action
    @collections = {}
    @collections["write"] = write.is_a?(Array) ? write.map{ |x| x.is_a?(String) ? x : x.is_a?(ArangoCollection) ? x.collection : nil } : write.is_a?(String) ? [write] : write.is_a?(ArangoCollection) ? [write.collection] : []
    @collections["read"] = read.is_a?(Array) ? read.map{ |x| x.is_a?(String) ? x : x.is_a?(ArangoCollection) ? x.collection : nil } : read.is_a?(String) ? [read] : read.is_a?(ArangoCollection) ? [read.collection] : []
    @params = params
    @lockTimeout = lockTimeout
    @waitForSync = waitForSync
    @result = nil
    @idCache = "AT_#{@database}_#{Random.rand(0..10^12)}"
  end

  attr_reader :action, :params, :lockTimeout, :waitForSync, :idCache

  ### RETRIEVE ###

  def collections
    result = {}
    result["write"] = @collections["write"].map{|x| ArangoCollection.new(database: @database, collection: x)} unless @collections["write"].nil?
    result["read"] = @collections["read"].map{|x| ArangoCollection.new(database: @database, collection: x)} unless @collections["read"].nil?
    result
  end

  def database
    ArangoDatabase.new(database: @database)
  end

  def execute # TESTED
    body = {
      "action" => @action,
      "collections" => @collections,
      "params" => @params,
      "lockTimeout" => @lockTimeout,
      "waitForSync" => @waitForSync
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_db/#{@database}/_api/transaction", request)
    return result.headers["x-arango-async-id"] if @@async == "store"
    result = result.parsed_response
    @result = result["result"] unless result["error"]
    @@verbose ? result : result["error"] ? {"message": result["errorMessage"], "stacktrace": result["stacktrace"]} : result["result"]
  end
end
