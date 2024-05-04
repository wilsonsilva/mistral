#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

embeddings_response = client.embeddings(
  model: 'mistral-embed',
  input: ['What is the best French cheese?'] * 10
)

puts embeddings_response.to_h
