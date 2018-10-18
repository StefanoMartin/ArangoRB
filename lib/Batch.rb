module Arango
  class Batch
    include Arango::Helper_Error
    include Arango::Helper_Return
    include Arango::Server_Return

    def initialize(server:, boundary: "XboundaryX", queries: [])
      @id = 1
      assign_server(server)
      assign_queries(queries)
      @headers = {
        "Content-Type": "multipart/form-data",
        "boundary":     boundary
      }
      @boundary = boundary
    end

# === DEFINE ===

    attr_reader :server, :boundary, :queries

    def boundary=(boundary)
      @boundary = boundary
      @headers[:boundary] = boundary
    end

    def queries=(queries)
      queries = [queries] unless queries.is_a?(Array)
      queries.each do |query|
        satisfy_class?(query, Hash)
        if query[:id].nil?
          query[:id] = @id.clone.to_s
          @id += 1
        end
      end
      @queries = queries
    end
    alias assign_queries queries=

# === TO HASH ===

    def to_h(level=0)
      hash = {
        "boundary": @boundary,
        "queries":  @queries
      }
      hash.delete_if{|k,v| v.nil?}
      hash[:database] = level > 0 ? @database.to_h(level-1) : @database.name
      hash
    end

# === QUERY ===

    def addQuery(id: @id, method:, url:, body: nil)
      id = id.to_s
      @queries[id.to_s] = {
        "id":     id,
        "method": method,
        "url":    url,
        "body":   body
      }
      @id += 1
    end

    def removeQuery(id:)
      @queries.delete(id)
    end

# === EXECUTE ===

    def execute
      body = ""
      @queries.each do |query|
        body += "--#{@boundary}\n"
        body += "Content-Type: application/x-arango-batchpart\n"
        body += "Content-Id: #{query[:id]}\n"
        body += "\n"
        body += "#{query[:method]} "
        body += "#{query[:url]} HTTP/1.1\n"
        body += "\n#{query[:body].to_json}\n" unless query[:body].nil?
      end
      body += "--#{@boundary}--\n" if @queries.length > 0
      @database.request("POST", "_api/batch", body: body, skip_to_json: true,
        headers: @headers)
    end
  end
end
