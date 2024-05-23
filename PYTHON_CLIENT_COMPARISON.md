# Comparison with [client-python](https://github.com/mistralai/client-python)

This Ruby gem aims to maintain 1:1 parity with the Python client. There are just a few differences to make the API
more idiomatic to Ruby.

## Development standards

In the interest of efficiency and maintainability, this gem __prioritizes parity__ with the Python client over
__adherence to my typical development standards__ such as 100% documentation, 100% test coverage, and strict
linting. This approach simplifies the process of backporting new features from the Python package in the future.

## Public API

The public API remains the same as the Python client. For example, these two examples are equivalent:

```python
import os

from mistralai.client import MistralClient
from mistralai.models.chat_completion import ChatMessage


def main():
    api_key = os.environ["MISTRAL_API_KEY"]
    model = "mistral-tiny"

    client = MistralClient(api_key=api_key)

    chat_response = client.chat(
        model=model,
        messages=[
          ChatMessage(role="user", content="What is the best French cheese?")
        ],
    )
    print(chat_response.choices[0].message.content)


if __name__ == "__main__":
    main()
```

```ruby
require 'mistral'

api_key = ENV.fetch('MISTRAL_API_KEY')
model = 'mistral-tiny'

client = Mistral::Client.new(api_key: api_key)

chat_response = client.chat(
  model: model,
  messages: [
    Mistral::ChatMessage.new(role: 'user', content: 'What is the best French cheese?')
  ]
)

puts chat_response.choices[0].message.content
```

However, since Ruby doesn't have native `async` support, all `async` methods and examples are not implemented.

### Directory structure

Excluding the async files, they are roughly the same. The main differences are the presence of `__init__.py` files in
the Python package, additional files like `http/features/line_iterable_body.rb` in the Ruby gem and `utils.py`
(equivalent to `test_helper.rb`) in the Python package.

```shell
Python package                         Ruby gem
├── examples                           ├── examples
│   ├── chat_no_streaming.py           │   ├── chat_no_streaming.rb
│   ├── chat_with_streaming.py         │   ├── chat_with_streaming.rb
│   ├── chatbot_with_streaming.py      │   ├── chatbot_with_streaming.rb
│   ├── embeddings.py                  │   ├── embeddings.rb
│   ├── function_calling.py            │   ├── function_calling.rb
│   ├── json_format.py                 │   ├── json_format.rb
│   └── list_models.py                 │   └── list_models.rb
├── src                                ├── lib
│   └── mistralai                      │   ├── http
│       ├── __init__.py                │   │   └── features
│       ├── client.py                  │   │       └── line_iterable_body.rb
│       ├── client_base.py             │   ├── mistral
│       ├── constants.py               │   │   ├── client.rb
│       ├── exceptions.py              │   │   ├── client_base.rb
│       └── models                     │   │   ├── constants.rb
│           ├── __init__.py            │   │   ├── exceptions.rb
│           ├── chat_completion.py     │   │   ├── models
│           ├── common.py              │   │   │   ├── chat_completion.rb
│           ├── embeddings.py          │   │   │   ├── common.rb
│           └── models.py              │   │   │   ├── embeddings.rb
└── tests                              │   │   │   └── models.rb
    ├── __init__.py                    │   │   └── version.rb
    ├── test_chat.py                   │   └── mistral.rb
    ├── test_embedder.py               └── test
    ├── test_list_models.py                ├── test_chat.rb
    └── utils.py                           ├── test_embedder.rb
                                           ├── test_helper.rb
                                           └── test_list_models.rb
```

### Errors and exceptions

Ruby lacks a native way to import and namespace constants like Python. To address this, exceptions are namespaced,
and the top-level exception is named `Error` as per Ruby gem standard practice:

| Python                       | Ruby                       |
|------------------------------|----------------------------|
| `MistralException`           | `Mistral::Error`           |
| `MistralAPIException`        | `Mistral::APIError`        |
| `MistralAPIStatusException`  | `Mistral::APIStatusError`  |
| `MistralConnectionException` | `Mistral::ConnectionError` |

## Private API

Unlike Python, where private methods start with an underscore (`_`), Ruby follows the convention of not having a
specific naming pattern for private methods.

```python
def _process_line(self, line: str) -> Optional[Dict[str, Any]]:
  # Implementation

def _make_chat_request:
  # Implementation
```

```ruby
def process_line(line)
end

def make_chat_request(line)
end
```

## Static typing

Python's `Pydantic` package for data validation and manipulation is implemented using `dry-types` and `dry-struct`
in Ruby. `Pydantic`'s `Model`s are implemented as `Dry::Struct`s, and `model_dump` is replaced with `to_h` for
converting structs to hashes.

Ruby's `RBS` type system was initially explored but not fully implemented due to time constraints. It remains
available in a [separate branch](https://github.com/wilsonsilva/mistral/tree/rbs-types).

## Client version

Unlike Python, where the version is set in the `Client` class, Ruby follows the convention of defining the version
as a `VERSION` constant in the gem's top-level module.

## HTTP Client

The Python version uses the package [httpx](https://www.python-httpx.org/) to send HTTP requests. In Ruby, the
gem [http](https://github.com/httprb/http) (also called `http.rb`) is used, which is similar. One difference
is that while `httpx`'s responses let you easily iterate over each line of the body, `http.rb` doesn't have this
functionality built-in.

To mimic `httpx`'s `iter_lines` behavior, I implemented a plugin (known as a `Feature` in `http.rb`):

```python
for line in response.iter_lines():
    json_streamed_response = self._process_line(line)
    if json_streamed_response:
        yield json_streamed_response
```

```ruby
response.body.each_line do |line|
  processed_line = process_line(line)
  next if processed_line.nil?

  yielder << processed_line
end
```

This code resides in `lib/http/features/line_iterable_body.rb`.

## Testing

The Ruby gem aims for 1:1 parity with the Python client. As such, it uses `Minitest` (similar to Python's `pytest`).
However, testing was simplified by using `webmock` for stubbing requests, instead of implementing 100% test
coverage and using RSpec, which is usually what I do.

## Examples

The `function_calling.rb` example omits the unnecessary `n_rows = data['transaction_id'].length` line present in
the Python version.

## Logging

Python has a global logger:

```python
self._logger = logging.getLogger(__name__)
```

Ruby doesn't. Thus, in order to allow users to customize the logging level, they can set the environment variable
`MISTRAL_LOG_LEVEL` to `DEBUG`, `INFO`, `WARN`, `ERROR` or `FATAL`.
