# frozen_string_literal: true

module Mistral
  RETRY_STATUS_CODES = [429, 500, 502, 503, 504].freeze
  ENDPOINT = 'https://api.mistral.ai'
end
