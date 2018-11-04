# ==== DOCUMENT ====

module Arango
  class View
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def self.new(*args)
      hash = args[0]
      super unless hash.is_a?(Hash)
      database = hash[:database]
      if database.is_a?(Arango::Database) && database.server.active_cache && !hash[:id].nil?
        cache_name = "#{database.name}/#{hash[:id]}"
        cached = database.server.cache.cache.dig(:view, cache_name)
        if cached.nil?
          hash[:cache_name] = cache_name
          return super
        else
          body = {}
          [:type, :name].each{|k| body[k] ||= hash[k]}
          cached.assign_attributes(body)
          return cached
        end
      end
      super
    end

    def initialize(database:, type: "arangosearch", name:, id: nil, cache_name: nil)
      assign_database(database)
      unless cache_name.nil?
        @cache_name = cache_name
        @server.cache.save(:view, cache_name, self)
      end
      satisfy_category?(type, ["arangosearch"])
      @type = type
      @name = name
      @links = {}
      @id = id
    end

# === DEFINE ===

    attr_reader :type, :links, :database, :cache_name
    attr_accessor :id, :name

    def type=(type)
      satisfy_category?(type, ["arangosearch"])
      @type = type
    end
    alias assign_type type=

    def add_link(collection:, analyzers: nil, fields: {}, includeAllFields: nil, trackListPositions: nil, storeValues: nil)
      satisfy_class?(collection, [Arango::Collection, String])
      collection_name = collection.is_a?(String) ? collection : collection.name
      satisfy_category?(storeValues, ["none", "id", nil])
      @links[collection_name] = {
        analyzers: analyzers,
        fields: fields,
        includeAllFields: includeAllFields,
        trackListPositions: trackListPositions,
        storeValues: storeValues
      }
      @links[collection_name].delete_if{|k,v| v.nil?}
    end

    def to_h
      {
        "name": @name,
        "id": @id,
        "type": @type,
        "links": @links,
        "cache_name": @cache_name,
        "database": @database.name
      }.delete_if{|k,v| v.nil?}
    end

    def body=(result)
      @body  = result
      @id    = result[:id] || @id
      @type  = assign_type(result[:type] || @type)
      @links = result[:links] || @links
      @name  = result[:name] || name
      if @server.active_cache && @cache_name.nil?
        @cache_name = "#{@database.name}/#{@id}"
        @server.cache.save(:task, @cache_name, self)
      end
    end
    alias assign_attributes body=

    # === COMMANDS ===

    def retrieve
      result = @database.request("GET", "_api/view/#{@name}")
      return result.headers[:"x-arango-async-id"] if @server.async == :store
      return_element(result)
    end

    def manage_properties(method, url, consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      body = {
        properties: {
          links: @links.empty? ? nil : @links,
          consolidationIntervalMsec: consolidationIntervalMsec,
          consolidationPolicy: {
            threshold: threshold,
            segmentThreshold: segmentThreshold
          },
          cleanupIntervalStep: cleanupIntervalStep
        }
      }
      if method == "POST"
        body[:type] = @type
        body[:name] = @name
      end
      body[:properties][:consolidationPolicy].delete_if{|k,v| v.nil?}
      body[:properties].delete(:consolidationPolicy) if body[:properties][:consolidationPolicy].empty?
      body[:properties].delete_if{|k,v| v.nil?}
      body.delete(:properties) if body[:properties].empty?
      body.delete_if{|k,v| v.nil?}
      result = @database.request(method, url, body: body)
      return_element(result)
    end
    private :manage_properties

    def create(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("POST", "_api/view", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def replaceProperties(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("PUT", "_api/view/#{@name}/properties", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def updateProperties(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("PATCH", "_api/view/#{@name}/properties", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def rename name:
      body = {name: name}
      result = @database.request("PUT", "_api/view/#{@name}/rename", body: body)
      return_element(result)
    end

    def properties
      @database.request("GET", "_api/view/#{@name}/properties")
    end

    def destroy
      @database.request("DELETE", "_api/view/#{@name}", key: :result)
    end
  end
end
