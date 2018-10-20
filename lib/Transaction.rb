  # === TRANSACTION ===

module Arango
  class Transaction
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(database:, action:, write: [], read: [], params: nil,
      maxTransactionSize: nil, lockTimeout: nil, waitForSync: nil, intermediateCommitCount: nil, intermedateCommitSize: nil)
      assign_database(database)
      @action = action
      @write  = return_write_or_read(write)
      @read   = return_write_or_read(read)
      @params = params
      @maxTransactionSize      = maxTransactionSize
      @lockTimeout             = lockTimeout
      @waitForSync             = waitForSync
      @intermediateCommitCount = intermediateCommitCount
      @intermedateCommitSize   = intermedateCommitSize
      @result = nil
    end

# === DEFINE ===

    attr_reader :read, :write, :result, :server, :database
    attr_accessor :action, :params, :maxTransactionSize,
      :lockTimeout, :waitForSync, :intermediateCommitCount,
      :intermedateCommitSize

    def write=(write)
      @write = return_write_or_read(write)
    end

    def addWrite(write)
      write = return_write_or_read(write)
      @write ||= []
      @write << write
    end

    def read=(read)
      @read = return_write_or_read(read)
    end

    def addRead(read)
      read = return_write_or_read(read)
      @read ||= []
      @read << read
    end

    def return_write_or_read(value)
      case value
      when Array
        return value.map{|x| return_collection(x)}
      when String, Arango::Collection
        return [return_collection(value)]
      when NilClass
        return []
      else
        raise Arango::Error.new err: :read_or_write_should_be_string_or_collections, data: {"wrong_value": value, "wrong_class": value.class}
      end
    end
    private :return_write_or_read

    def return_collection(collection, type=nil)
      satisfy_class?(collection, [Arango::Collection, String])
      if collection.is_a?(Arango::Collection)
        return collection
      elsif collection.is_a?(String)
        return Arango::Collection.new(name: collection, database: @database)
      end
    end
    private :return_collection

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "action": @action,
        "result": @result,
        "params": @params,
        "read": @read.map{|x| x.name},
        "write": @write.map{|x| x.name}
      }
      hash.delete_if{|k,v| v.nil?}
      hash[:database] = level > 0 ? @database.to_h(level-1) : @database.name
    end

# === EXECUTE ===

    def execute(action: @action, params: @params,
      maxTransactionSize: @maxTransactionSize,
      lockTimeout: @lockTimeout, waitForSync: @waitForSync,
      intermediateCommitCount: @intermediateCommitCount,
      intermedateCommitSize: @intermedateCommitSize)
      body = {
        "collections": {
          "read": @read.map{|x| x.name},
          "write": @write.map{|x| x.name}
        },
        "action": action,
        "params": params,
        "lockTimeout": lockTimeout,
        "waitForSync": waitForSync,
        "maxTransactionSize": maxTransactionSize,
        "intermediateCommitCount": intermediateCommitCount,
        "intermedateCommitSize": intermedateCommitSize
      }
      result = @database.request("POST", "_api/transaction", body: body)
      return result if @server.async != false
      @result = result[:result]
      return return_directly?(result) ? result : result[:result]
    end
  end
end
