# === ERROR ===

module Arango
  class Error < StandardError
    def initialize(message:, data: nil, code: nil)
      @data = data
      @code = code
      super(message)
    end
    attr_reader :data, :code, :message
  end
end
