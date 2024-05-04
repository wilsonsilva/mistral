# frozen_string_literal: true

module Mistral
  class ModelPermission < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String
    attribute :object, Types::Strict::String
    attribute :created, Types::Strict::Integer
    attribute :allow_create_engine, Types::Strict::Bool.default(false)
    attribute :allow_sampling, Types::Strict::Bool.default(true)
    attribute :allow_logprobs, Types::Strict::Bool.default(true)
    attribute :allow_search_indices, Types::Strict::Bool.default(false)
    attribute :allow_view, Types::Strict::Bool.default(true)
    attribute :allow_fine_tuning, Types::Strict::Bool.default(false)
    attribute :organization, Types::Strict::String.default('*')
    attribute? :group, Types::Strict::String.optional
    attribute :is_blocking, Types::Strict::Bool.default(false)
  end

  class ModelCard < Dry::Struct
    transform_keys(&:to_sym)

    attribute :id, Types::Strict::String
    attribute :object, Types::Strict::String
    attribute :created, Types::Strict::Integer
    attribute :owned_by, Types::Strict::String
    attribute? :root, Types::Strict::String.optional
    attribute? :parent, Types::Strict::String.optional
    attribute :permission, Types::Strict::Array.of(ModelPermission).default([].freeze)
  end

  class ModelList < Dry::Struct
    transform_keys(&:to_sym)

    attribute :object, Types::Strict::String
    attribute :data, Types::Strict::Array.of(ModelCard)
  end
end
