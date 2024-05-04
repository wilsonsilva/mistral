# frozen_string_literal: true

module HTTP
  module Features
    class LineIterableBody < Feature
      def wrap_response(response)
        options = {
          status: response.status,
          version: response.version,
          headers: response.headers,
          proxy_headers: response.proxy_headers,
          connection: response.connection,
          body: IterableBodyWrapper.new(response.body, response.body.instance_variable_get(:@encoding)),
          request: response.request
        }

        HTTP::Response.new(options)
      end

      class IterableBodyWrapper < HTTP::Response::Body
        def initialize(body, encoding)
          super(body, encoding: encoding)
        end

        def each_line(&block)
          each do |chunk|
            chunk.each_line(&block)
          end
        end
      end
    end
  end

  HTTP::Options.register_feature(:line_iterable_body, Features::LineIterableBody)
end
