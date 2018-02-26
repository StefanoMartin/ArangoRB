module Arango
  module Helper_Return
  def return_directly?(result)
    return @client.async != false || @client.return_direct_result
    return result == true
  end

  def return_element(result)
    return result if @client.async != false
    assign_attributes(result)
    return return_directly?(result) ? result : self
  end
end

module Arango
  module Database_Return
    def database=(database)
      satisfy_class?(database, [Arango::Database])
      @database = database
      @client = @database.client
    end
    alias assign_database database=
  end
end

module Arango
  module Collection_Return
    def collection=(collection)
      satisfy_class?(collection, [Arango::Collection])
      @collection = collection
      @graph = @collection.graph
      @database = @collection.database
      @client = @database.client
    end
    alias assign_collection collection=
  end
end
