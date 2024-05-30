# Mistral Ruby Client

[![Gem Version](https://badge.fury.io/rb/mistral.svg)](https://badge.fury.io/rb/mistral)
![Build](https://github.com/wilsonsilva/mistral/actions/workflows/main.yml/badge.svg)

Mistral is a Ruby gem to interact with the [Mistral AI API](https://www.mistral.ai).

This client is a 1:1 port of Mistral's [client-python](https://github.com/mistralai/client-python).
For a detailed comparison between the Ruby and Python clients, please refer to the
[PYTHON_CLIENT_COMPARISON.md](https://github.com/wilsonsilva/mistral/blob/main/PYTHON_CLIENT_COMPARISON.md) file.

## 🔑 Key features

- API parity with the official [Python client](https://github.com/mistralai/client-python)
- Full support for all Mistral AI functionalities, including chat completions, embeddings, and function calling
- Asynchronous streaming of responses
- Comprehensive error handling and retry mechanisms
- Configurable client options (e.g., API endpoint, timeout, max retries)
- Fully leverages `dry-struct` for type safety and avoids primitive obsession with hashes

## 📦 Installation

Install the gem and add to the application's Gemfile by executing:

```
$ bundle add mistral
```

If bundler is not being used to manage dependencies, install the gem by executing:

```
$ gem install mistral
```

## ⚡️ Quickstart

Here are a few examples of how to use the Mistral gem:

### Chat completion

```ruby
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

model = 'mistral-small'

chat_response = client.chat(
 model: model,
 messages: [
   Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')
 ]
)

puts chat_response.choices[0].message.content
```

### Chat completion with streaming

```ruby
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
client = Mistral::Client.new(api_key: api_key)

model = 'mistral-small'

client.chat_stream(
  model: model,
  messages: [
    Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')
  ]
).each do |chunk|
  print chunk.choices[0].delta.content if chunk.choices[0].delta.content
end
```

## 📚 Documentation

In the [`examples`](https://github.com/wilsonsilva/mistral/tree/main/examples) folder, you will find how to do:

| File Name                                                                                                                | Description                                                    |
|--------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| [`chat_no_streaming.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/chat_no_streaming.rb)                 | How to use the chat endpoint without streaming                 |
| [`chat_with_streaming.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/chat_with_streaming.rb)             | How to use the chat endpoint with streaming                    |
| [`chatbot_with_streaming.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/chatbot_with_streaming.rb)       | A simple interactive chatbot using streaming                   |
| [`code_completion.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/code_completion.rb)                     | How to perform a code completion                               |
| [`completion_with_streaming.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/completion_with_streaming.rb) | How to perform a code completion with streaming                |
| [`embeddings.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/embeddings.rb)                               | How to use the embeddings endpoint                             |
| [`function_calling.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/function_calling.rb)                   | How to call functions using the chat endpoint                  |
| [`json_format.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/json_format.rb)                             | How to request and parse JSON responses from the chat endpoint |
| [`list_models.rb`](https://github.com/wilsonsilva/mistral/blob/main/examples/list_models.rb)                             | How to list available models                                   |

## 🔨 Development

After checking out the repo, run `bin/setup` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`.

You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

The health and maintainability of the codebase is ensured through a set of Rake tasks to test and lint the gem:

```
rake build                    # Build mistral into the pkg directory
rake build:checksum           # Generate SHA512 checksum if mistral.gem into the checksums directory
rake clean                    # Remove any temporary products
rake clobber                  # Remove any generated files
rake install                  # Build and install mistral.gem into system gems
rake install:local            # Build and install mistral.gem into system gems without network access
rake release[remote]          # Create tag v0.1.0 and build and push mistral.gem to https://rubygems.org
rake rubocop                  # Run RuboCop
rake rubocop:autocorrect      # Autocorrect RuboCop offenses (only when it's safe)
rake rubocop:autocorrect_all  # Autocorrect RuboCop offenses (safe and unsafe)
rake test                     # Run the test suite
rake test:cmd                 # Print out the test command
rake test:isolated            # Show which test files fail when run in isolation
rake test:slow                # Show bottom 25 tests wrt time
```

## 🐞 Issues & Bugs

If you find any issues or bugs, please report them [here](https://github.com/wilsonsilva/mistral/issues), I will be happy
to have a look at them and fix them as soon as possible.

Please let me know if the [client-python](https://github.com/mistralai/client-python) introduces any new features,
so I can keep this gem in sync with the latest updates.

## 🤝 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wilsonsilva/mistral.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to the [code of conduct](https://github.com/wilsonsilva/mistral/blob/main/CODE_OF_CONDUCT.md).

## 📜 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👔 Code of Conduct

Everyone interacting in the mistral project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/wilsonsilva/mistral/blob/main/CODE_OF_CONDUCT.md).
