# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'mistral'
require 'minitest/autorun'
require 'webmock/minitest'
require 'json'

def mock_list_models_response_payload
  <<~JSON
    {
      "object": "list",
      "data": [
        {
          "id": "mistral-medium",
          "object": "model",
          "created": 1703186988,
          "owned_by": "mistralai",
          "root": null,
          "parent": null,
          "permission": [
            {
              "id": "modelperm-15bebaf316264adb84b891bf06a84933",
              "object": "model_permission",
              "created": 1703186988,
              "allow_create_engine": false,
              "allow_sampling": true,
              "allow_logprobs": false,
              "allow_search_indices": false,
              "allow_view": true,
              "allow_fine_tuning": false,
              "organization": "*",
              "group": null,
              "is_blocking": false
            }
          ]
        },
        {
          "id": "mistral-small-latest",
          "object": "model",
          "created": 1703186988,
          "owned_by": "mistralai",
          "root": null,
          "parent": null,
          "permission": [
            {
              "id": "modelperm-d0dced5c703242fa862f4ca3f241c00e",
              "object": "model_permission",
              "created": 1703186988,
              "allow_create_engine": false,
              "allow_sampling": true,
              "allow_logprobs": false,
              "allow_search_indices": false,
              "allow_view": true,
              "allow_fine_tuning": false,
              "organization": "*",
              "group": null,
              "is_blocking": false
            }
          ]
        },
        {
          "id": "mistral-tiny",
          "object": "model",
          "created": 1703186988,
          "owned_by": "mistralai",
          "root": null,
          "parent": null,
          "permission": [
            {
              "id": "modelperm-0e64e727c3a94f17b29f8895d4be2910",
              "object": "model_permission",
              "created": 1703186988,
              "allow_create_engine": false,
              "allow_sampling": true,
              "allow_logprobs": false,
              "allow_search_indices": false,
              "allow_view": true,
              "allow_fine_tuning": false,
              "organization": "*",
              "group": null,
              "is_blocking": false
            }
          ]
        },
        {
          "id": "mistral-embed",
          "object": "model",
          "created": 1703186988,
          "owned_by": "mistralai",
          "root": null,
          "parent": null,
          "permission": [
            {
              "id": "modelperm-ebdff9046f524e628059447b5932e3ad",
              "object": "model_permission",
              "created": 1703186988,
              "allow_create_engine": false,
              "allow_sampling": true,
              "allow_logprobs": false,
              "allow_search_indices": false,
              "allow_view": true,
              "allow_fine_tuning": false,
              "organization": "*",
              "group": null,
              "is_blocking": false
            }
          ]
        }
      ]
    }
  JSON
end

def mock_embedding_response_payload(batch_size: 1)
  {
    'id' => 'embd-98c8c60e3fbf4fc49658eddaf447357c',
    'object' => 'list',
    'data' => [
      {
        'object' => 'embedding',
        'embedding' => [-0.018585205078125, 0.027099609375, 0.02587890625],
        'index' => 0
      }
    ] * batch_size,
    'model' => 'mistral-embed',
    'usage' => { 'prompt_tokens' => 90, 'total_tokens' => 90, 'completion_tokens' => 0 }
  }.to_json
end

def mock_chat_response_payload
  <<~JSON
    {
      "id": "chat-98c8c60e3fbf4fc49658eddaf447357c",
      "object": "chat.completion",
      "created": 1703165682,
      "choices": [
        {
          "finish_reason": "stop",
          "message": {
            "role": "assistant",
            "content": "What is the best French cheese?"
          },
          "index": 0
        }
      ],
      "model": "mistral-small-latest",
      "usage": {"prompt_tokens": 90, "total_tokens": 90, "completion_tokens": 0}
    }
  JSON
end

def mock_chat_response_streaming_payload
  [
    'data: ' + {
      'id' => 'cmpl-8cd9019d21ba490aa6b9740f5d0a883e',
      'model' => 'mistral-small-latest',
      'choices' => [
        {
          'index' => 0,
          'delta' => { 'role' => 'assistant' },
          'finish_reason' => nil
        }
      ]
    }.to_json + "\n\n",
    *Array.new(10) do |i|
      'data: ' + {
        'id' => 'cmpl-8cd9019d21ba490aa6b9740f5d0a883e',
        'object' => 'chat.completion.chunk',
        'created' => 1_703_168_544,
        'model' => 'mistral-small-latest',
        'choices' => [
          {
            'index' => i,
            'delta' => { 'content' => "stream response #{i}" },
            'finish_reason' => nil
          }
        ]
      }.to_json + "\n\n"
    end,
    "data: [DONE]\n\n"
  ]
end

def mock_completion_response_payload
  {
    'id' => 'chat-98c8c60e3fbf4fc49658eddaf447357c',
    'object' => 'chat.completion',
    'created' => 1_703_165_682,
    'choices' => [
      {
        'finish_reason' => 'stop',
        'message' => {
          'role' => 'assistant',
          'content' => ' a + b'
        },
        'index' => 0
      }
    ],
    'model' => 'mistral-small-latest',
    'usage' => {
      'prompt_tokens' => 90,
      'total_tokens' => 90,
      'completion_tokens' => 0
    }
  }.to_json
end
