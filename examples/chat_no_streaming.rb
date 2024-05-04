#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

model = 'mistral-tiny'

chat_response = client.chat(
  model: model,
  messages: [Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')]
)

puts chat_response.choices[0].message.content
