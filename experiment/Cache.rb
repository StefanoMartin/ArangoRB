module Arango
  class Cache
    def initialize
      @max  = {
        database: 10,
        collection: 20,
        document: 200,
        graph: 1,
        vertex: 50,
        edge: 100,
        index: 20,
        aql: 100,
        user: 50,
        task: 20,
        traversal: 20,
        transaction: 20,
        other: 100
      }

      @cache = {
        database: {},
        collection: {},
        document: {},
        graph: {},
        vertex: {},
        edge: {},
        index: {},
        aql: {},
        user: {},
        task: {},
        traversal: {},
        transaction: {},
        other: {}
      }
    end

    attr_reader :cache, :max

    def save(type, id, obj)
      while @cache[type].length >= @max[type]
        @cache[type].shift
      end
      @cache[type][id] = obj
    end

    def updateMax(type:, val:)
      type = type.to_sym rescue type = :error
      unless @max.has_key?(type.to_sym)
        ArangoDB::Error.new :element_in_cache_does_not_exist,
          {wrong_attribute: :type, wrong_value: type}
      end
      while @cache[type].length > val
        @cache[type].shift
      end
      @max[type] = val
    end
  end
end
