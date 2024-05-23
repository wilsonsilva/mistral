# frozen_string_literal: true

require 'test_helper'

class TestChat < Minitest::Test
  def setup
    @client = Mistral::Client.new(api_key: 'test_api_key')
  end

  def test_chat
    stub_request(:post, 'https://api.mistral.ai/v1/chat/completions')
      .with(
        body: {
          messages: [{ role: 'user', content: 'What is the best French cheese?' }],
          safe_prompt: false,
          model: 'mistral-small',
          stream: false
        }.to_json,
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{@client.api_key}",
          'Connection' => 'Keep-Alive',
          'Content-Type' => 'application/json',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        }
      )
      .to_return(status: 200, body: mock_chat_response_payload, headers: {})

    result = @client.chat(
      model: 'mistral-small',
      messages: [
        Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')
      ]
    )

    assert_requested(:post, 'https://api.mistral.ai/v1/chat/completions',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json',
        'Connection' => 'Keep-Alive'
      },
      body: {
        messages: [{ role: 'user', content: 'What is the best French cheese?' }],
        safe_prompt: false,
        model: 'mistral-small',
        stream: false
      },
      times: 1
    )

    assert_kind_of Mistral::ChatCompletionResponse, result, 'Should return a ChatCompletionResponse'
    assert_equal 1, result.choices.length
    assert_equal 0, result.choices[0].index
    assert_equal 'chat.completion', result.object
  end

  def test_chat_streaming
    stub_request(:post, 'https://api.mistral.ai/v1/chat/completions')
      .with(
        body: {
          messages: [
            { role: 'user', content: 'What is the best French cheese?' }
          ],
          safe_prompt: false,
          model: 'mistral-small',
          stream: true
        }.to_json,
        headers: {
          'Accept' => 'text/event-stream',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'Connection' => 'Keep-Alive',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        }
      )
      .to_return(status: 200, body: mock_chat_response_streaming_payload.join, headers: {})

    chat_stream_result = @client.chat_stream(
      model: 'mistral-small',
      messages: [
        Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')
      ]
    )

    results = chat_stream_result.to_a

    assert_requested(:post, 'https://api.mistral.ai/v1/chat/completions',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'text/event-stream',
        'Authorization' => "Bearer #{@client.api_key}",
        'Connection' => 'Keep-Alive',
        'Content-Type' => 'application/json'
      },
      body: {
        messages: [
          { role: 'user', content: 'What is the best French cheese?' }
        ],
        safe_prompt: false,
        model: 'mistral-small',
        stream: true
      }.to_json,
      times: 1
    )

    results.each_with_index do |result, i|
      assert_kind_of Mistral::ChatCompletionStreamResponse, result, 'Should return a ChatCompletionStreamResponse'
      assert_equal 1, result.choices.length

      if i.zero?
        assert_equal 0, result.choices[0].index
        assert_equal 'assistant', result.choices[0].delta.role
      else
        assert_equal i - 1, result.choices[0].index
        assert_equal "stream response #{i - 1}", result.choices[0].delta.content
        assert_equal 'chat.completion.chunk', result.object
      end
    end
  end
end
