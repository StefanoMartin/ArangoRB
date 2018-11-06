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
      @queries = {}
      queries.each do |query|
        begin
          query.keys.each do |key|
            query[(key.to_sym rescue key) || key] = query.delete(key)
          end
        rescue
          raise Arango::Error.new(err: :batch_query_not_valid,
            data: {wrong_query: query})
        end
        satisfy_class?(query, [Hash])
        if query[:id].nil?
          query[:id] = @id.to_s
          @id += 1
        end
        @queries[query[:id]] = query
      end
      return @queries
    end
    alias assign_queries queries=

# === TO HASH ===

    def to_h
      {
        "boundary": @boundary,
        "queries":  @queries,
        "database": @database.name
      }.delete_if{|k,v| v.nil?}
    end

# === QUERY ===

    def addQuery(id: @id, method:, address:, body: nil)
      id = id.to_s
      @queries[id] = {
        "id":      id,
        "method":  method,
        "address": address,
        "body":    body
      }.delete_if{|k,v| v.nil?}
      @id += 1
      return @queries
    end
    alias modifyQuery addQuery

    def removeQuery(id:)
      @queries.delete(id)
      return @queries
    end

# === EXECUTE ===

    def execute
      body = ""
      @queries.each do |id, query|
        body += "--#{@boundary}\n"
        body += "Content-Type: application/x-arango-batchpart\n"
        body += "Content-Id: #{query[:id]}\n\n"
        body += "#{query[:method]} "
        body += "#{query[:address]} HTTP/1.1\n"
        body += "\n#{Oj.dump(query[:body])}\n" unless query[:body].nil?
      end
      body += "--#{@boundary}--\n" if @queries.length > 0
      @server.request("POST", "_api/batch", body: body, skip_to_json: true,
        headers: @headers, skip_parsing: true)
    end
  end
end
