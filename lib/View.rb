# ==== DOCUMENT ====

module Arango
  class View
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Database_Return

    def initialize(database:, type: "arangosearch", name:, id:)
      assign_database(database)
      satisfy_category?(type, ["arangosearch"])
      @type = type
      @name = name
      @links = {}
      @id = id
    end

# === DEFINE ===

    attr_reader :type, :links, :database
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

    def to_h(level=0)
      hash = {
        "name": @name,
        "id": @id,
        "type": @type,
        "links": @links
      }
      hash.delete_if{|k,v| v.nil?}
      hash[:database] = level > 0 ? @database.to_h(level-1) : @database.name
    end

    def body=(result)
      @body  = result
      @id    = result[:id] || @id
      @type  = assign_type(result[:type] || @type)
      @links = result[:links] || @links
      @name  = result[:name] || name
    end
    alias assign_attributes body=

    # === COMMANDS ===

    def retrieve
      result = @database.request("GET", "_api/views/#{@name}")
      return result.headers[:"x-arango-async-id"] if @@async == "store"
      return_element(result)
    end

    def manage_properties(method, consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
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
      result = @database.request(method, "_api/views", body: body)
      return_element(result)
    end
    private :manage_properties

    def create(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("POST", "_api/views", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def replaceProperties(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("PUT", "_api/views/#{@name}/properties", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def updateProperties(consolidationIntervalMsec: nil, threshold: nil, segmentThreshold: nil, cleanupIntervalStep: nil)
      manage_properties("PATCH", "_api/views/#{@name}/properties", consolidationIntervalMsec: consolidationIntervalMsec, threshold: threshold, segmentThreshold: segmentThreshold, cleanupIntervalStep: cleanupIntervalStep)
    end

    def rename name:
      body = {name: name}
      result = @database.request("PUT", "_api/views/#{@name}/rename", body: body)
      return_element(result)
    end

    def properties
      @database.request("GET", "_api/views/#{@name}/properties")
    end

    def remove
      @database.request("DELETE", "_api/views/#{@name}", key: :result)
    end
  end
end
