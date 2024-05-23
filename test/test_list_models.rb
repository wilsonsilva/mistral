# frozen_string_literal: true

require 'test_helper'

class TestListModels < Minitest::Test
  def setup
    @client = Mistral::Client.new(api_key: 'test_api_key')
  end

  def test_list_models
    stub_request(:get, 'https://api.mistral.ai/v1/models')
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{@client.api_key}",
          'Content-Type' => 'application/json',
          'Connection' => 'Keep-Alive',
          'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}"
        }
      )
      .to_return(status: 200, body: mock_list_models_response_payload, headers: {})

    result = @client.list_models

    assert_requested(:get, 'https://api.mistral.ai/v1/models',
      headers: {
        'User-Agent' => "mistral-client-ruby/#{Mistral::VERSION}",
        'Accept' => 'application/json',
        'Authorization' => "Bearer #{@client.api_key}",
        'Content-Type' => 'application/json',
        'Connection' => 'Keep-Alive'
      },
      times: 1
    )

    assert_kind_of Mistral::ModelList, result, 'Should return a ModelList'
    assert_equal 4, result.data.length
    assert_equal 'list', result.object
  end
end
