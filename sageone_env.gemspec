# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sageone_env/version'

Gem::Specification.new do |spec|
  spec.name          = "sageone_env"
  spec.version       = SageoneEnv::VERSION
  spec.authors       = ["Nige"]
  spec.email         = ["nigel.surtees@sage.com"]

  spec.summary       = %q{ Enables configuration of the environment settings for Sageone apps}
  spec.description   = %q{ Allows the database connection settings to be more easily changed depending on the environment in use. This gem iterates over all Sageone apps in the directory it is executed from and reconfigures the database yaml file for the environment chosen. It is a command line utitlity that uses switches and commands to provide flexibilty of argument passing}
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = " Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end
  #Only with ruby 2.0.x
  spec.required_ruby_version = '~> 2.0'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ["sageone_env"]
  spec.require_paths = ["lib"]
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
end
