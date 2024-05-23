# frozen_string_literal: true

require 'mistral/client_base'

module Mistral
  # Synchronous wrapper around the async client
  class Client < ClientBase
    def initialize(
      api_key: nil,
      endpoint: ENDPOINT,
      max_retries: 5,
      timeout: 120
    )
      super(endpoint: endpoint, api_key: api_key, max_retries: max_retries, timeout: timeout)

      @client = HTTP.persistent(ENDPOINT)
                    .follow
                    .timeout(timeout)
                    .use(:line_iterable_body)
                    .headers('Accept' => 'application/json',
                      'User-Agent' => "mistral-client-ruby/#{VERSION}",
                      'Authorization' => "Bearer #{@api_key}",
                      'Content-Type' => 'application/json'
                    )
    end

    # A chat endpoint that returns a single response.
    #
    # @param messages [Array<ChatMessage>] An array of messages to chat with, e.g.
    #   [{role: 'user', content: 'What is the best French cheese?'}]
    # @param model [String] The name of the model to chat with, e.g. mistral-tiny
    # @param tools [Array<Hash>] A list of tools to use.
    # @param temperature [Float] The temperature to use for sampling, e.g. 0.5.
    # @param max_tokens [Integer] The maximum number of tokens to generate, e.g. 100.
    # @param top_p [Float] The cumulative probability of tokens to generate, e.g. 0.9.
    # @param random_seed [Integer] The random seed to use for sampling, e.g. 42.
    # @param safe_mode [Boolean] Deprecated, use safe_prompt instead.
    # @param safe_prompt [Boolean] Whether to use safe prompt, e.g. true.
    # @param tool_choice [String, ToolChoice] The tool choice.
    # @param response_format [Hash<String, String>, ResponseFormat] The response format.
    # @return [ChatCompletionResponse] A response object containing the generated text.
    #
    def chat(
      messages:,
      model: nil,
      tools: nil,
      temperature: nil,
      max_tokens: nil,
      top_p: nil,
      random_seed: nil,
      safe_mode: false,
      safe_prompt: false,
      tool_choice: nil,
      response_format: nil
    )
      request = make_chat_request(
        messages: messages,
        model: model,
        tools: tools,
        temperature: temperature,
        max_tokens: max_tokens,
        top_p: top_p,
        random_seed: random_seed,
        stream: false,
        safe_prompt: safe_mode || safe_prompt,
        tool_choice: tool_choice,
        response_format: response_format
      )

      single_response = request('post', 'v1/chat/completions', json: request)

      single_response.each do |response|
        return ChatCompletionResponse.new(response)
      end

      raise Mistral::Error.new(message: 'No response received')
    end

    # A chat endpoint that streams responses.
    #
    # @param messages [Array<Any>] An array of messages to chat with, e.g.
    #   [{role: 'user', content: 'What is the best French cheese?'}]
    # @param model [String] The name of the model to chat with, e.g. mistral-tiny
    # @param tools [Array<Hash>] A list of tools to use.
    # @param temperature [Float] The temperature to use for sampling, e.g. 0.5.
    # @param max_tokens [Integer] The maximum number of tokens to generate, e.g. 100.
    # @param top_p [Float] The cumulative probability of tokens to generate, e.g. 0.9.
    # @param random_seed [Integer] The random seed to use for sampling, e.g. 42.
    # @param safe_mode [Boolean] Deprecated, use safe_prompt instead.
    # @param safe_prompt [Boolean] Whether to use safe prompt, e.g. true.
    # @param tool_choice [String, ToolChoice] The tool choice.
    # @param response_format [Hash<String, String>, ResponseFormat] The response format.
    # @return [Enumerator<ChatCompletionStreamResponse>] A generator that yields ChatCompletionStreamResponse objects.
    #
    def chat_stream(
      messages:,
      model: nil,
      tools: nil,
      temperature: nil,
      max_tokens: nil,
      top_p: nil,
      random_seed: nil,
      safe_mode: false,
      safe_prompt: false,
      tool_choice: nil,
      response_format: nil
    )
      request = make_chat_request(
        messages: messages,
        model: model,
        tools: tools,
        temperature: temperature,
        max_tokens: max_tokens,
        top_p: top_p,
        random_seed: random_seed,
        stream: true,
        safe_prompt: safe_mode || safe_prompt,
        tool_choice: tool_choice,
        response_format: response_format
      )

      Enumerator.new do |yielder|
        request('post', 'v1/chat/completions', json: request, stream: true).each do |json_response|
          yielder << ChatCompletionStreamResponse.new(**json_response)
        end
      end
    end

    # An embeddings endpoint that returns embeddings for a single, or batch of inputs
    #
    # @param model [String] The embedding model to use, e.g. mistral-embed
    # @param input [String, Array<String>] The input to embed, e.g. ['What is the best French cheese?']
    #
    # @return [EmbeddingResponse] A response object containing the embeddings.
    #
    def embeddings(model:, input:)
      request = { model: model, input: input }
      singleton_response = request('post', 'v1/embeddings', json: request)

      singleton_response.each do |response|
        return EmbeddingResponse.new(response)
      end

      raise Mistral::Error.new(message: 'No response received')
    end

    # Returns a list of the available models
    #
    # @return [ModelList] A response object containing the list of models.
    #
    def list_models
      singleton_response = request('get', 'v1/models')

      singleton_response.each do |response|
        return ModelList.new(response)
      end

      raise Mistral::Error.new(message: 'No response received')
    end

    private

    def request(method, path, json: nil, stream: false, attempt: 1)
      url = File.join(@endpoint, path)
      headers = {}
      headers['Accept'] = 'text/event-stream' if stream

      @logger.debug("Sending request: #{method.upcase} #{url} #{json}")

      Enumerator.new do |yielder|
        response = @client.headers(headers).request(method.downcase.to_sym, url, json: json)
        check_response_status_codes(response)

        if stream
          response.body.each_line do |line|
            processed_line = process_line(line)
            next if processed_line.nil?

            yielder << processed_line
          end
        else
          yielder << check_response(response)
        end
      rescue HTTP::ConnectionError => e
        raise Mistral::ConnectionError, e.message
      rescue HTTP::RequestError => e
        raise Mistral::Error, "Unexpected exception (#{e.class}): #{e.message}"
      rescue JSON::ParserError
        raise Mistral::APIError.from_response(response, message: "Failed to decode json body: #{response.body}")
      rescue Mistral::APIStatusError => e
        attempt += 1

        raise Mistral::APIStatusError.from_response(response, message: e.message) if attempt > @max_retries

        backoff = 2.0**attempt # exponential backoff
        sleep(backoff)

        # Retry and yield the response
        request(method, path, json: json, stream: stream, attempt: attempt).each do |r|
          yielder << r
        end
      end
    end

    def check_response(response)
      check_response_status_codes(response)

      json_response = JSON.parse(response.body.to_s)

      if !json_response.key?('object')
        raise Mistral::Error, "Unexpected response: #{json_response}"
      elsif json_response['object'] == 'error' # has errors
        raise Mistral::APIError.from_response(response, message: json_response['message'])
      end

      json_response
    end

    def check_response_status_codes(response)
      if RETRY_STATUS_CODES.include?(response.code)
        raise APIStatusError.from_response(response, message: "Status: #{response.code}. Message: #{response.body}")
      elsif response.code >= 400 && response.code < 500
        raise APIError.from_response(response, message: "Status: #{response.code}. Message: #{response.body}")
      elsif response.code >= 500
        raise Mistral::Error.new(message: "Status: #{response.code}. Message: #{response.body}")
      end
    end
  end
end
