# frozen_string_literal: true

require 'dry-struct'
require 'http'
require 'json'
require 'logger'
require 'time'

require 'http/features/line_iterable_body'

module Mistral
  module Types
    include Dry.Types()
  end
end

require 'mistral/constants'
require 'mistral/exceptions'
require 'mistral/models/models'
require 'mistral/models/common'
require 'mistral/models/embeddings'
require 'mistral/models/chat_completion'
require 'mistral/version'
require 'mistral/client'
