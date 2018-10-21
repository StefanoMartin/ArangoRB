module Arango
  class Cache
    def initialize
      @max  = {
        database: 10,
        collection: 20,
        document: 200,
        graph: 10,
        index: 20,
        user: 20,
        task: 20,
        view: 20,
        foxx: 20
      }

      @cache = {
        database: {},
        collection: {},
        document: {},
        graph: {},
        index: {},
        aql: {},
        user: {},
        task: {},
        view: {},
        foxx: {}
      }
    end

    attr_reader :cache, :max

    def to_h
      hash = {
        "max": @max,
        "cache": {}
      }
      @cache.each do |key, hash2|
        next if hash2.empty?
        hash[:cache][key] = hash2.keys
      end
      hash
    end

    def save(type, id, obj)
      while @cache[type].length >= @max[type]
        @cache[type].shift
      end
      @cache[type][id] = obj
    end

    def destroy(type, id)
      @cache[type].delete(id)
    end

    def clear
      @cache.each_key{|k| @cache[k] = {}}
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
