# ==== CACHE ====

class ArangoCache
  @max  = {
    "Database" => 1,
    "Collection" => 20,
    "Document" => 200,
    "Graph" => 1,
    "Vertex" => 50,
    "Edge" => 100,
    "Index" => 20,
    "AQL" => 100,
    "User" => 50,
    "Task" => 20,
    "Traversal" => 20,
    "Transaction" => 20,
    "Other" => 100
  }
  @cache = {
    "Database" => {},
    "Collection" => {},
    "Document" => {},
    "Graph" => {},
    "Vertex" => {},
    "Edge" => {},
    "Index" => {},
    "AQL" => {},
    "User" => {},
    "Task" => {},
    "Traversal" => {},
    "Transaction" => {},
    "Other" => {}
  }

  class << self
    attr_accessor :max

    def max(type:, val:)
      return nil if @max[type].nil?
      while @cache[type].length > val
        @cache[type].shift
      end
      @max[type] = val
    end

    def retrieve
      @cache
    end

    def cache(id: nil, data:)
      val_to_cache = []
      data = [data] unless data.is_a? Array

      if id.nil?
        data.each do |d|
          type = d.class.to_s
          type.slice! "Arango"
          if @max[type].nil?
            type = "Other"
            idCache = "OTH_#{d.class.to_s}_#{Random.rand(10^12)}"
          else
            idCache = d.idCache
          end
          val_to_cache << [type, idCache, d]
        end
      else
        id = [id] unless id.is_a? Array
        if data.length == id.length
          for i in 0...id.length
            type = data[i].class.to_s
            type.slice! "Arango"
            type = "Other" if @max[type].nil?
            val_to_cache << [type, id[i], data[i]]
          end
        else
          return "Id should be a String or an Array with the same size of the Data Array"
        end
      end

      val_to_cache.each do |val|
        @cache[val[0]][val[1]] = val[2]
        @cache[val[0]].shift if @cache[val[0]].length > @max[val[0]]
      end

      val_to_cache
    end

    def uncache(type: nil, id: nil, data: nil)
      if id.nil? && data.nil? && !type.nil?
        val_to_uncache = @cache[type].map{|k,v| v}
        val_to_uncache = val_to_uncache[0] if val_to_uncache.length == 1
        return val_to_uncache
      end

      val_to_uncache = []
      unless data.nil?
        data = [data] unless data.is_a? Array
        data.each do |d|
          type = d.class.to_s
          type.slice! "Arango"
          next if @max[type].nil? || type == "Other"
          idCache = d.idCache
          val_to_uncache << [type, idCache]
        end
      end
      unless type.nil? || id.nil?
        id = [id] unless id.is_a? Array
        if type.is_a? Array
          if type.length == id.length
            for i in 0...type.length
              val_to_uncache << [type[i], id[i]]
            end
          else
            return "Type should be a String or an Array with the same size of the Id Array"
          end
        elsif type.is_a? String
          id.each do |idCache|
            val_to_uncache << [type, idCache]
          end
        else
          return "Type should be a String or an Array with the same size of the Id Array"
        end
      end
      val_to_uncache = val_to_uncache.map{|val| @cache[val[0]][val[1]]}
      val_to_uncache = val_to_uncache[0] if val_to_uncache.length == 1
      val_to_uncache
    end

    def clear(type: nil, id: nil, data: nil)
      if type.nil? && id.nil? && data.nil?
        @cache = { "Database" => {}, "Collection" => {}, "Document" => {}, "Graph" => {}, "Vertex" => {}, "Edge" => {}, "Index" => {}, "Query" => {},"User" => {}, "Traversal" => {}, "Transaction" => {} }
        return true
      end

      if !type.nil? && id.nil? && data.nil?
        @cache[type] = {}
        return true
      end

      val_to_clear = []
      unless data.nil?
        data = [data] unless data.is_a? Array
        data.each do |d|
          type = d.class.to_s
          type.slice! "Arango"
          next if @max[type].nil? || type == "Other"
          val_to_clear <<  [type, d.idCache]
        end
      end

      unless type.nil? || id.nil?
        id = [id] unless id.is_a? Array
        if type.is_a? Array
          if type.length == id.length
            for i in 0...type.length
              val_to_clear << [type[i], id[i]]
            end
          else
            return "Type should be a String or an Array with the same size of the Id Array"
          end
        elsif type.is_a? String
          id.each do |idCache|
            val_to_clear << [type, idCache]
          end
        else
          return "Type should be a String or an Array with the same size of the Id Array"
        end
      end

      val_to_clear.each{|val| @cache[val[0]].delete(val[1])}
      true
    end
  end
end
