#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

prompt = 'def fibonacci(n: int):'
suffix = "n = int(input('Enter a number: '))\nprint(fibonacci(n))"

response = client.completion(
  model: 'codestral-latest',
  prompt: prompt,
  suffix: suffix
)

print <<~COMPLETION
  #{prompt}
  #{response.choices[0].message.content}
  #{suffix}
COMPLETION
