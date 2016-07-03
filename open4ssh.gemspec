# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'open4ssh/version'

Gem::Specification.new do |spec|
  spec.name          = "open4ssh"
  spec.version       = Open4ssh::VERSION
  spec.authors       = ["Nane Kratzke"]
  spec.email         = ["nane.kratzke@fh-luebeck.de"]

  spec.summary       = %q{Wrapper around net-ssh for plain execution of remote shell commands.}
  spec.description   = %q{Wrapper around net-ssh for plain execution of remote shell commands and painless collection of exit codes, stdout, stderr messages.}
  spec.homepage      = "https://rubygems.org/gems/open4ssh"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "test-unit", "~> 3.2"

  spec.add_runtime_dependency "net-ssh", "~> 3.2"
end