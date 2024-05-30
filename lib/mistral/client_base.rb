# frozen_string_literal: true

module Mistral
  class ClientBase
    attr_reader :endpoint, :api_key, :max_retries, :timeout

    def initialize(endpoint:, api_key: nil, max_retries: 5, timeout: 120)
      @max_retries = max_retries
      @timeout = timeout

      api_key = ENV['MISTRAL_API_KEY'] if api_key.nil?

      raise Error, 'API key not provided. Please set MISTRAL_API_KEY environment variable.' if api_key.nil?

      @api_key = api_key
      @endpoint = endpoint
      @logger = config_logger

      # For azure endpoints, we default to the mistral model
      @default_model = 'mistral' if endpoint.include?('inference.azure.com')
    end

    protected

    def parse_tools(tools)
      parsed_tools = []

      tools.each do |tool|
        next unless tool['type'] == 'function'

        parsed_function = {}
        parsed_function['type'] = tool['type']
        parsed_function['function'] = if tool['function'].is_a?(Function)
                                        tool['function'].to_h
                                      else
                                        tool['function']
                                      end

        parsed_tools << parsed_function
      end

      parsed_tools
    end

    def parse_tool_choice(tool_choice)
      tool_choice.is_a?(ToolChoice) ? tool_choice.to_s : tool_choice
    end

    def parse_response_format(response_format)
      if response_format.is_a?(ResponseFormat)
        response_format.to_h
      else
        response_format
      end
    end

    def parse_messages(messages)
      parsed_messages = []

      messages.each do |message|
        parsed_messages << if message.is_a?(ChatMessage)
                             message.to_h
                           else
                             message
                           end
      end

      parsed_messages
    end

    def make_completion_request(
      prompt:,
      model: nil,
      suffix: nil,
      temperature: nil,
      max_tokens: nil,
      top_p: nil,
      random_seed: nil,
      stop: nil,
      stream: false
    )
      request_data = {
        'prompt' => prompt,
        'suffix' => suffix,
        'model' => model,
        'stream' => stream
      }

      request_data['stop'] = stop unless stop.nil?

      if model.nil?
        raise Error.new(message: 'model must be provided') if @default_model.nil?

        request_data['model'] = @default_model
      else
        request_data['model'] = model
      end

      request_data.merge!(
        build_sampling_params(
          temperature: temperature,
          max_tokens: max_tokens,
          top_p: top_p,
          random_seed: random_seed
        )
      )

      @logger.debug("Completion request: #{request_data}")

      request_data
    end

    def build_sampling_params(max_tokens: nil, random_seed: nil, temperature: nil, top_p: nil)
      params = {}
      params['temperature'] = temperature unless temperature.nil?
      params['max_tokens'] = max_tokens unless max_tokens.nil?
      params['top_p'] = top_p unless top_p.nil?
      params['random_seed'] = random_seed unless random_seed.nil?
      params
    end

    def make_chat_request(
      messages:,
      model: nil,
      tools: nil,
      temperature: nil,
      max_tokens: nil,
      top_p: nil,
      random_seed: nil,
      stream: nil,
      safe_prompt: false,
      tool_choice: nil,
      response_format: nil
    )
      request_data = {
        messages: parse_messages(messages),
        safe_prompt: safe_prompt
      }

      request_data[:model] = if model.nil?
                               raise Mistral::Error.new(message: 'model must be provided') if @default_model.nil?

                               @default_model
                             else
                               model
                             end

      request_data[:tools] = parse_tools(tools) unless tools.nil?
      request_data[:temperature] = temperature unless temperature.nil?
      request_data[:max_tokens] = max_tokens unless max_tokens.nil?
      request_data[:top_p] = top_p unless top_p.nil?
      request_data[:random_seed] = random_seed unless random_seed.nil?
      request_data[:stream] = stream unless stream.nil?
      request_data[:tool_choice] = parse_tool_choice(tool_choice) unless tool_choice.nil?
      request_data[:response_format] = parse_response_format(response_format) unless response_format.nil?

      @logger.debug("Chat request: #{request_data}")

      request_data
    end

    def process_line(line)
      return unless line.start_with?('data: ')

      line = line[6..].to_s.strip
      return if line == '[DONE]'

      JSON.parse(line)
    end

    def config_logger
      Logger.new($stdout).tap do |logger|
        logger.level = ENV.fetch('MISTRAL_LOG_LEVEL', 'ERROR')

        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} #{severity} #{progname}: #{msg}\n"
        end
      end
    end
  end
end
