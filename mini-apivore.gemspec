# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mini_apivore/version"

Gem::Specification.new do |spec|
  spec.name          = "mini-apivore"
  spec.version       = Mini::Apivore::VERSION
  spec.authors       = ["alekseyl"]
  spec.email         = ["leshchuk@gmail.com"]

  spec.summary       = " Minitest adaptation of an apivore gem "
  spec.description   = ' Minitest adaptation of apivore gem,
                           Provides a tool for testing your application api against your swagger schema '
  spec.homepage      = "https://github.com/alekseyl/mini-apivore"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files       = ["lib/mini_apivore.rb", "data/swagger_2.0_schema.json", "data/draft04_schema.json"]
  spec.files      += Dir["lib/mini_apivore/*.rb"]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib", "data"]

  spec.add_runtime_dependency("hashie", "~> 3.3")
  spec.add_runtime_dependency("json-schema", "~> 2.5")
  spec.add_runtime_dependency("minitest", "~> 5.0")

  spec.add_development_dependency("pry", "~> 0")
  spec.add_development_dependency("rake", ">= 12.3.3")
  spec.add_development_dependency("rubocop-shopify")
end
