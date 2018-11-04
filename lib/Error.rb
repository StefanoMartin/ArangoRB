# === ERROR ===

module Arango
  class Error < StandardError
    @@list_arango_rb_errors = {
      no_other_aql_next: {
        code: 10001, message: "No other values with AQL next"
      },
      no_other_simple_next: {
        code: 10002, message: "No other values with AQL next"
      },
      is_a_edge_collection: {
        code: 10003, message: "This collection is an Edge collection"
      },
      is_a_document_collection: {
        code: 10004, message: "This collection is a Document collection"
      },
      database_graph_no_same_as_collection_database: {
        code: 10005, message: "Database of graph is not the same as the class"
      },
      wrong_type_instead_of_expected_one: {
        code: 10006, message: "Expected a type, received another"
      },
      no_other_export_next: {
        code: 10007, message: "No other values with AQL next"
      },
      no_aql_id_available: {
        code: 10008, message: "AQL does not have id. It could have already been killed"
      },
      id_is_not_valid: {
        code: 10009, message: "Given attribute is not a valid document id or an Arango::Document"
      },
      collection_does_not_have_a_graph: {
        code: 10010, message: "Collection does not have a graph"
      },
      arangodb_did_not_return_a_valid_result: {
        code: 10011, message: "ArangoDB didn't return a valid result"
      },
      read_or_write_should_be_string_or_collections: {
        code: 10012, message: "read or write should be an array of name classes or Arango::Collections"
      },
      wrong_class: {
        code: 10013, message: "Wrong class"
      },
      wrong_element: {
        code: 10014, message: "Element is not part of the list"
      },
      orphan_collection_used_by_edge_definition: {
        code: 10015, message: "Orphan collection is already used by an edge definition"
      },
      impossible_to_parse_arangodb_response: {
        code: 10016, message: "Impossible to parse ArangoDB response"
      },
      batch_query_not_valid: {
        code: 10017, message: "Query is not valid"
      },
      arangorb_didnt_return_a_valid_result: {
        code: 10018, message: "ArangoRB didn't return a valid result"
      },
      impossible_to_connect_with_database: {
        code: 10019, message: "Impossible to connect with database"
      },
      you_cannot_assign_from_or_to_to_a_vertex: {
        code: 10020, message: "You cannot assign from or to to a Vertex"
      },
      wrong_start_vertex_type: {
        code: 10021, message: "Starting vertex should be an Arango::Vertex, an Arango::Document (not Edge) or a valid vertex id"
      },
      database_undefined_for_traversal: {
        code: 10022, message: "Database undefined for traversal"
      },
      edge_collection_should_be_of_type_edge: {
        code: 10022, message: "Database undefined for traversal"
      }
    }

    def initialize(err:, data: nil, skip_assignment: false)
      unless skip_assignment
        @message = @@list_arango_rb_errors[err][:message]
        @code = @@list_arango_rb_errors[err][:code]
        @internal_code = err
        @data = data
      end
      super(@message)
    end
    attr_reader :data, :code, :message

    def to_h
      {
        "message": @message,
        "code": @code,
        "data": @data,
        "internal_code": @internal_code
      }.delete_if{|k,v| v.nil?}
    end
  end
end

module Arango
  class ErrorDB < Arango::Error
    def initialize(message:, code:, data:, errorNum:, action:, url:, request:)
      @message  = message
      @code     = code
      @data     = data
      @errorNum = errorNum
      @action   = action
      @url      = url
      @request  = request
      super(err: nil, skip_assignment: true)
    end
    attr_reader :message, :code, :data, :errorNum, :action, :url, :request
  end

  def to_h
    {
      "action": @action,
      "url": @url,
      "request": @request,
      "message": @message,
      "code": @code,
      "data": @data,
      "errorNum": @errorNum
    }.delete_if{|k,v| v.nil?}
  end
end
