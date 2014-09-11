# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'azkaban_scheduler/version'

Gem::Specification.new do |spec|
  spec.name          = "azkaban_scheduler"
  spec.version       = AzkabanScheduler::VERSION
  spec.authors       = ["Dylan Thacker-Smith"]
  spec.email         = ["Dylan.Smith@shopify.com"]
  spec.summary       = "Azkaban client that can update the schedule"
  spec.homepage      = "https://github.com/Shopify/azkaban-scheduler-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency("rubyzip", "~> 1.1")
  spec.add_dependency("multipart-post", "~> 2.0")

  spec.add_development_dependency("bundler", "~> 1.6")
  spec.add_development_dependency("rake")
  spec.add_development_dependency("minitest", "~> 5.4")
  spec.add_development_dependency("webmock", "~> 1.18")
  spec.add_development_dependency("vcr", "~> 2.9")
end
