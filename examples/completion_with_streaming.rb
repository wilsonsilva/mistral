#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

prompt = 'def fibonacci(n: int):'
suffix = "n = int(input('Enter a number: '))\nprint(fibonacci(n))"

print(prompt)

client.completion_stream(
  model: 'codestral-latest',
  prompt: prompt,
  suffix: suffix
).each do |chunk|
  print(chunk.choices[0].delta.content) unless chunk.choices[0].delta.content.nil?
end

print(suffix)
