  # === TRANSACTION ===

module Arango
  class Transaction
    def initialize(client:, action:, write: [], read: [], params: nil, maxTransactionSize: nil, lockTimeout: nil, waitForSync: nil, intermediateCommitCount: nil, intermedateCommitSize: nil)
      satisfy_class?(database, [Arango::Client])
      @client = client
      @action = action
      @write = return_write_or_read(write)
      @read  = return_write_or_read(read)
      @params = params
      @maxTransactionSize = maxTransactionSize
      @lockTimeout = lockTimeout
      @waitForSync = waitForSync
      @intermediateCommitCount = intermediateCommitCount
      @intermedateCommitSize = intermedateCommitSize
      @result = nil
    end

    def client=(client)
      satisfy_class?(client,[Arango::Client])
      @client = client
    end

    def write=(write)
      @write = return_write_or_read(write)
    end

    def read=(read)
      @read = return_write_or_read(read)
    end

    def return_write_or_read(value)
      case value.class
      when Array
        return value.map{|x| return_collection(x)}
      when String, Arango::Collection
        return [return_collection(value)]
      when NilClass
        return []
      else
        raise Arango::Error.new message: "read or write should be an array of name classes or Arango::Collections"
      end
    end

    def return_collection(collection, type=nil)
      if collection.is_a?(Arango::Collection)
        return collection
      elsif collection.is_a?(String)
        return Arango::Collection.new(name: collection, database: @database)
      else
        raise Arango::Error.new message: "#{collection} should be an Arango::Collection or
        a name of a class"
      end
    end

    attr_reader :read, :write, :result, :client
    attr_accessor :action, :params, :maxTransactionSize,
      :lockTimeout, :waitForSync, :intermediateCommitCount,
      :intermedateCommitSize

    ### RETRIEVE ###

    def to_h(level=0)
      hash = {
        "action"      => @action,
        "collections" => @collections,
        "result"      => @result,
        "params"      => @params,
        "read"  => @read.map{|x| x.name},
        "write" => @write.map{|x| x.name}
      }.delete_if{|k,v| v.nil?}
      hash["client"] = level > 0 ? @client.to_h(level-1) : @client.base_uri
    end

    def execute
      body = {
        "action" => @action,
        "collections" => {
          "read" => @read.map{|x| x.name},
          "write" =>  @write.map{|x| x.name}
        },
        "params" => @params,
        "lockTimeout" => @lockTimeout,
        "waitForSync" => @waitForSync,
        "maxTransactionSize" => @maxTransactionSize,
        "intermediateCommitCount" => @intermediateCommitCount,
        "intermedateCommitSize" => @intermedateCommitSize
      }
      request = @client.request(action: "POST", url: "/_api/transaction", body: body)
      return result if @client.async != false
      @result = result["result"]
      return return_directly?(result) ? result : result["result"]
    end
  end
end
