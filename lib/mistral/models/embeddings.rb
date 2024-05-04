# frozen_string_literal: true

module Mistral
  class EmbeddingObject < Dry::Struct
    transform_keys(&:to_sym)

    attribute :object, Types::Strict::String
    attribute :embedding, Types::Strict::Array.of(Types::Strict::Float)
    attribute :index, Types::Strict::Integer
  end

  class EmbeddingResponse < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String
    attribute :object, Types::Strict::String
    attribute :data, Types::Strict::Array.of(EmbeddingObject)
    attribute :model, Types::Strict::String
    attribute :usage, UsageInfo
  end
end
