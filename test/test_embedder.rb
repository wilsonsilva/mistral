# frozen_string_literal: true

require 'test_helper'

class TestEmbeddings < Minitest::Test
  def setup
    @client = Mistral::Client.new
  end

  def test_embeddings
    stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        },
        body: {
          model: 'mistral-embed',
          input: 'What is the best French cheese?'
        }.to_json
      )
      .to_return(status: 200, body: mock_embedding_response_payload, headers: {})

    result = @client.embeddings(
      model: 'mistral-embed',
      input: 'What is the best French cheese?'
    )

    assert_requested(:post, 'https://api.mistral.ai/v1/embeddings',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'mistral-embed',
        input: 'What is the best French cheese?'
      }.to_json,
      times: 1
    )

    assert_kind_of Mistral::EmbeddingResponse, result, 'Should return an EmbeddingResponse'
    assert_equal 1, result.data.length
    assert_equal 0, result.data[0].index
    assert_equal 'list', result.object
  end

  def test_embeddings_batch
    stub_request(:post, 'https://api.mistral.ai/v1/embeddings')
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        },
        body: {
          model: 'mistral-embed',
          input: ['What is the best French cheese?'] * 10
        }.to_json
      )
      .to_return(status: 200, body: mock_embedding_response_payload(batch_size: 10), headers: {})

    result = @client.embeddings(
      model: 'mistral-embed',
      input: ['What is the best French cheese?'] * 10
    )

    assert_requested(:post, 'https://api.mistral.ai/v1/embeddings',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'mistral-embed',
        input: ['What is the best French cheese?'] * 10
      }.to_json,
      times: 1
    )

    assert_kind_of Mistral::EmbeddingResponse, result, 'Should return an EmbeddingResponse'
    assert_equal 10, result.data.length
    assert_equal 0, result.data[0].index
    assert_equal 'list', result.object
  end
end
