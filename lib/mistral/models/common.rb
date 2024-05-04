# frozen_string_literal: true

module Mistral
  class UsageInfo < Dry::Struct
    transform_keys(&:to_sym)

    attribute :prompt_tokens, Types::Strict::Integer
    attribute :total_tokens, Types::Strict::Integer
    attribute? :completion_tokens, Types::Strict::Integer.optional
  end
end
