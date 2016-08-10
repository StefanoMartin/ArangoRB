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
  end

  attr_reader :action, :collections, :params, :lockTimeout, :waitForSync

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
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          {"message": result["errorMessage"], "stacktrace": result["stacktrace"]}
        else
          result["result"]
        end
      end
    end
  end
end
