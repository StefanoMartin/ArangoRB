# === TRANSACTION ===

class ArangoTransaction < ArangoServer
  def initialize(action:, write:, read:, params: nil, lockTimeout: nil, waitForSync: nil)
    @action = action
    @collections = {}
    @collections["write"] = write.map{ |x| x.is_a?(String) ? x : x.is_a?(ArangoCollection) ? x.collection : nil }
    @collections["read"] = read.map{ |x| x.is_a?(String) ? x : x.is_a?(ArangoCollection) ? x.collection : nil }
    @params = params
    @lockTimeout = lockTimeout
    @waitForSync = waitForSync
  end

  def execute
    body = {
      "action" => @action,
      "collections" => @collections,
      "params" => @params,
      "lockTimeout" => @lockTimeout,
      "waitForSync" => @waitForSync
    }.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/transaction", request)
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
