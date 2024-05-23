#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'mistral'

# Assuming we have the following data
data = {
  'transaction_id' => %w[T1001 T1002 T1003 T1004 T1005],
  'customer_id' => %w[C001 C002 C003 C002 C001],
  'payment_amount' => [125.50, 89.99, 120.00, 54.30, 210.20],
  'payment_date' => %w[2021-10-05 2021-10-06 2021-10-07 2021-10-05 2021-10-08],
  'payment_status' => %w[Paid Unpaid Paid Paid Pending]
}

def retrieve_payment_status(data, transaction_id)
  data['transaction_id'].each_with_index do |r, i|
    return { status: data['payment_status'][i] }.to_json if r == transaction_id
  end

  { status: 'Error - transaction id not found' }.to_json
end

def retrieve_payment_date(data, transaction_id)
  data['transaction_id'].each_with_index do |r, i|
    return { date: data['payment_date'][i] }.to_json if r == transaction_id
  end

  { status: 'Error - transaction id not found' }.to_json
end

names_to_functions = {
  'retrieve_payment_status' => ->(transaction_id) { retrieve_payment_status(data, transaction_id) },
  'retrieve_payment_date' => ->(transaction_id) { retrieve_payment_date(data, transaction_id) }
}

tools = [
  {
    'type' => 'function',
    'function' => Mistral::Function.new(
      name: 'retrieve_payment_status',
      description: 'Get payment status of a transaction id',
      parameters: {
        'type' => 'object',
        'required' => ['transaction_id'],
        'properties' => {
          'transaction_id' => {
            'type' => 'string',
            'description' => 'The transaction id.'
          }
        }
      }
    )
  },
  {
    'type' => 'function',
    'function' => Mistral::Function.new(
      name: 'retrieve_payment_date',
      description: 'Get payment date of a transaction id',
      parameters: {
        'type' => 'object',
        'required' => ['transaction_id'],
        'properties' => {
          'transaction_id' => {
            'type' => 'string',
            'description' => 'The transaction id.'
          }
        }
      }
    )
  }
]

api_key = ENV.fetch('MISTRAL_API_KEY')
model = 'mistral-small-latest'

client = Mistral::Client.new(api_key: api_key)

messages = [Mistral::ChatMessage.new(role: 'user', content: "What's the status of my transaction?")]

response = client.chat(model: model, messages: messages, tools: tools)

puts response.choices[0].message.content

messages << Mistral::ChatMessage.new(role: 'assistant', content: response.choices[0].message.content)
messages << Mistral::ChatMessage.new(role: 'user', content: 'My transaction ID is T1001.')

response = client.chat(model: model, messages: messages, tools: tools)

tool_call = response.choices[0].message.tool_calls[0]
function_name = tool_call.function.name
function_params = JSON.parse(tool_call.function.arguments)

puts "calling function_name: #{function_name}, with function_params: #{function_params}"

function_result = names_to_functions[function_name].call(function_params['transaction_id'])

messages << response.choices[0].message
messages << Mistral::ChatMessage.new(
  role: 'tool', name: function_name, content: function_result, tool_call_id: tool_call.id
)

response = client.chat(model: model, messages: messages, tools: tools)

puts response.choices[0].message.content
