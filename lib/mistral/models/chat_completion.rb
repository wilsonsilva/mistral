# frozen_string_literal: true

module Mistral
  class Function < Dry::Struct
    transform_keys(&:to_sym)

    attribute :name, Types::Strict::String
    attribute :description, Types::Strict::String
    attribute :parameters, Types::Strict::Hash
  end

  ToolType = Types::Strict::String.default('function').enum('function')

  class FunctionCall < Dry::Struct
    transform_keys(&:to_sym)

    attribute :name, Types::Strict::String
    attribute :arguments, Types::Strict::String
  end

  class ToolCall < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String.default('null')
    attribute :type, ToolType
    attribute :function, FunctionCall
  end

  ResponseFormats = Types::Strict::String.default('text').enum('text', 'json_object')

  ToolChoice = Types::Strict::String.enum('auto', 'any', 'none')

  class ResponseFormat < Dry::Struct
    transform_keys(&:to_sym)

    attribute :type, ResponseFormats
  end

  class ChatMessage < Dry::Struct
    transform_keys(&:to_sym)

    attribute :role, Types::Strict::String
    attribute :content, Types::Strict::Array.of(Types::Strict::String) | Types::Strict::String
    attribute? :name, Types::String.optional
    attribute? :tool_calls, Types::Strict::Array.of(ToolCall).optional
  end

  class DeltaMessage < Dry::Struct
    transform_keys(&:to_sym)

    attribute? :role, Types::Strict::String.optional
    attribute? :content, Types::Strict::String.optional
    attribute? :tool_calls, Types::Strict::Array.of(ToolCall).optional
  end

  FinishReason = Types::Strict::String.enum('stop', 'length', 'error', 'tool_calls')

  class ChatCompletionResponseStreamChoice < Dry::Struct
    transform_keys(&:to_sym)

    attribute :index, Types::Strict::Integer
    attribute :delta, DeltaMessage
    attribute? :finish_reason, FinishReason.optional
  end

  class ChatCompletionStreamResponse < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String
    attribute :model, Types::Strict::String
    attribute :choices, Types::Strict::Array.of(ChatCompletionResponseStreamChoice)
    attribute? :created, Types::Strict::Integer.optional
    attribute? :object, Types::Strict::String.optional
    attribute? :usage, UsageInfo.optional
  end

  class ChatCompletionResponseChoice < Dry::Struct
    transform_keys(&:to_sym)

    attribute :index, Types::Strict::Integer
    attribute :message, ChatMessage
    attribute? :finish_reason, FinishReason.optional
  end

  class ChatCompletionResponse < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String
    attribute :object, Types::Strict::String
    attribute :created, Types::Strict::Integer
    attribute :model, Types::Strict::String
    attribute :choices, Types::Strict::Array.of(ChatCompletionResponseChoice)
    attribute :usage, UsageInfo
  end
end
