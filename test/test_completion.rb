# frozen_string_literal: true

require 'test_helper'

class TestCompletion < Minitest::Test
  def setup
    @client = Mistral::Client.new(api_key: 'test_api_key')
  end

  def test_completion
    stub_request(:post, 'https://api.mistral.ai/v1/fim/completions')
      .with(
        body: {
          prompt: 'def add(a, b):',
          suffix: 'return a + b',
          model: 'mistral-small-latest',
          stream: false,
          temperature: 0.5,
          max_tokens: 50,
          top_p: 0.9,
          random_seed: 42
        }.to_json,
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'Connection' => 'Keep-Alive',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        }
      )
      .to_return(status: 200, body: mock_completion_response_payload, headers: {})

    result = @client.completion(
      prompt: 'def add(a, b):',
      suffix: 'return a + b',
      model: 'mistral-small-latest',
      temperature: 0.5,
      max_tokens: 50,
      top_p: 0.9,
      random_seed: 42
    )

    assert_requested(:post, 'https://api.mistral.ai/v1/fim/completions',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json',
        'Connection' => 'Keep-Alive'
      },
      body: {
        model: 'mistral-small-latest',
        prompt: 'def add(a, b):',
        suffix: 'return a + b',
        stream: false,
        temperature: 0.5,
        max_tokens: 50,
        top_p: 0.9,
        random_seed: 42
      },
      times: 1
    )

    assert_kind_of Mistral::ChatCompletionResponse, result, 'Should return an ChatCompletionResponse'
    assert_equal 1, result.choices.length
    assert_equal 0, result.choices[0].index
    assert_equal 'chat.completion', result.object
  end

  def test_completion_streaming
    stub_request(:post, 'https://api.mistral.ai/v1/fim/completions')
      .with(
        body: {
          prompt: 'def add(a, b):',
          suffix: 'return a + b',
          model: 'mistral-small-latest',
          stream: true,
          stop: ['#']
        }.to_json,
        headers: {
          'Accept' => 'text/event-stream',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'Connection' => 'Keep-Alive',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        }
      )
      .to_return(status: 200, body: mock_completion_response_payload, headers: {})

    completion_stream_result = @client.completion_stream(
      model: 'mistral-small-latest',
      prompt: 'def add(a, b):',
      suffix: 'return a + b',
      stop: ['#']
    )

    results = completion_stream_result.to_a

    assert_requested(:post, 'https://api.mistral.ai/v1/fim/completions',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'text/event-stream',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json',
        'Connection' => 'Keep-Alive'
      },
      body: {
        prompt: 'def add(a, b):',
        suffix: 'return a + b',
        model: 'mistral-small-latest',
        stream: true,
        stop: ['#']
      }.to_json,
      times: 1
    )

    results.each_with_index do |result, i|
      assert_kind_of Mistral::ChatCompletionStreamResponse, result, 'Should return an ChatCompletionStreamResponse'
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
