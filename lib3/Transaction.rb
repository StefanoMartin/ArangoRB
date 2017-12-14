  # === TRANSACTION ===

module Arango
  class Transaction
    def initialize(database:, action:, write: [], read: [], params: nil)
      satisfy_class?(database, "database", [Arango::Database])
      @atabase = database
      @client = database.client
      @action = action
      @collections = {}
      @collections["write"] = write.is_a?(Array) ? write.map{ |x| x.is_a?(String) ? x : x.is_a?(Arango::Collection) ? x.name : nil } : write.is_a?(String) ? [write] : write.is_a?(Arango::Collection) ? [write.name] : []
      @collections["read"] = read.is_a?(Array) ? read.map{ |x| x.is_a?(String) ? x : x.is_a?(Arango::Collection) ? x.collection : nil } : read.is_a?(String) ? [read] : read.is_a?(Arango::Collection) ? [read.name] : []
      @params = params
      @lockTimeout = lockTimeout
      @waitForSync = waitForSync
      @result = nil
    end

    attr_reader :action, :params, :lockTimeout, :waitForSync, :idCache

    ### RETRIEVE ###

    def to_hash
      {
        "database"    => @database,
        "action"      => @action,
        "collections" => @collections,
        "result"      => @result,
        "params"      => @params
      }.delete_if{|k,v| v.nil?}
    end
    alias to_h to_hash

    def collections
      result = {}
      result["write"] = @collections["write"].map{|x| Arango::Collection.new(database: @database, name: x)} unless @collections["write"].nil?
      result["read"] = @collections["read"].map{|x| Arango::Collection.new(database: @database, name: x)} unless @collections["read"].nil?
      result
    end

    def execute(maxTransactionSize: nil, lockTimeout: nil, waitForSync: nil, intermediateCommitCount: nil, intermedateCommitSize: nil) # TESTED
      body = {
        "action" => @action,
        "collections" => @collections,
        "params" => @params,
        "lockTimeout" => lockTimeout,
        "waitForSync" => waitForSync,
        "maxTransactionSize" => maxTransactionSize,
        "intermediateCommitCount" => intermediateCommitCount,
        "intermedateCommitSize" => intermedateCommitSize
      }
      request = @database.request(action: "POST", url: "/_api/transaction", body: body)
      result = self.class.post("/_db/#{@database}", request)
      return result if @client.async != false
      @result = result["result"]
      return return_directly?(result) ? result : result["result"]
    end
  end
end
