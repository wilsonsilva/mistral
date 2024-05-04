# frozen_string_literal: true

module Mistral
  # Base error class, returned when nothing more specific applies
  class Error < StandardError
  end

  class APIError < Error
    attr_reader :http_status, :headers

    def initialize(message: nil, http_status: nil, headers: nil)
      super(message: message)

      @http_status = http_status
      @headers = headers
    end

    def self.from_response(response, message: nil)
      new(
        message: message || response.to_s,
        http_status: response.code,
        headers: response.headers.to_h
      )
    end

    def to_s
      "#{self.class.name}(message=#{super}, http_status=#{http_status})"
    end
  end

  # Returned when we receive a non-200 response from the API that we should retry
  class APIStatusError < APIError
  end

  # Returned when the SDK can not reach the API server for any reason
  class ConnectionError < Error
  end
end
