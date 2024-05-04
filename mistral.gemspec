# frozen_string_literal: true

require_relative 'lib/mistral/version'

Gem::Specification.new do |spec|
  spec.name = 'mistral'
  spec.version = Mistral::VERSION
  spec.authors = ['Wilson Silva']
  spec.email = ['wilson.dsigns@gmail.com']

  spec.summary = 'A Ruby client for the Mistral AI platform'
  spec.description = 'You can use the Mistral Ruby client to interact with the Mistral AI API.'
  spec.homepage = 'https://github.com/wilsonsilva/mistral'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/wilsonsilva/mistral'
  spec.metadata['changelog_uri'] = 'https://github.com/wilsonsilva/mistral/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-struct', '~> 1.6'
  spec.add_dependency 'http', '~> 5.2'

  spec.add_development_dependency 'dotenv', '~> 3.1'
  spec.add_development_dependency 'minitest', '~> 5.22'
  spec.add_development_dependency 'rake', '~> 13.2'
  spec.add_development_dependency 'rubocop', '~> 1.63'
  spec.add_development_dependency 'webmock', '~> 3.23'
end
