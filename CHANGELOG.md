# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.1.1/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-05-23

### Added

- We now support tool_call_id for tool messages. This will be mandatory in the future but you can start using right
away to improve the model performance during function calling (especially multiple).
Ports [mistralai/client-python#93](https://github.com/mistralai/client-python/pull/93)

### Changed

- Renamed `LOG_LEVEL` to `MISTRAL_LOG_LEVEL`. This is not a direct port of the Python client because Python has a
global logger in the `logging` module, but Ruby doesn't.
Ports [mistralai/client-python#86](https://github.com/mistralai/client-python/pull/86)
- Get API key at client initialization. Ports
[mistralai/client-python#57](https://github.com/mistralai/client-python/pull/57)

## [0.1.0] - 2024-05-04

- Initial release. Feature parity with `v0.1.8` of the
[mistralai/client-python](https://github.com/mistralai/client-python)

[0.2.0]: https://github.com/wilsonsilva/mistral/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/wilsonsilva/mistral/compare/28e7c9...v0.1.0
