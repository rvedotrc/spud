# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spud/version'

Gem::Specification.new do |s|
  s.name        = 'spud'
  s.version     = Spud::VERSION
  s.summary     = 'Tool for generating and managing CloudFormation stacks'
  s.description = <<-EOF
    spud is a tool for generating CloudFormation stack templates,
    comparing them to the existing templates in AWS, merging the results,
    then pushing the results back to CloudFormation.
  EOF
  s.homepage    = 'http://rve.org.uk/gems/spud'
  s.authors     = ['Rachel Evans']
  s.email       = 'git@rve.org.uk'
  s.license     = 'Apache-2.0'
  s.require_paths = ["lib"]

  s.files       = Dir.glob(%w[
README.md
Gemfile
Gemfile.lock
bin/*
lib/**/*.rb
scripts/default/*
spec/*.rb
  ])

  s.executables = %w[
    spud
  ]

  # NOTE: if you change these dependencies, also change the Gemfile
  s.add_development_dependency 'rspec', "~> 3.4"
  s.add_dependency 'aws-sdk', "~> 2.0"
  s.add_dependency 'json', '~> 1.8'
  s.add_dependency 'cfn-events', '~> 0.2'
end
