# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'stack-fetcher'
  s.version     = '2.0.0'
  s.summary     = 'Tool for generating and managing CloudFormation stacks'
  s.description = <<-EOF
    stack-fetcher is a tool for generating CloudFormation stack templates,
    comparing them to the existing templates in AWS, merging the results,
    then pushing the results back to CloudFormation.
  EOF
  s.homepage    = 'http://rve.org.uk/gems/stack-fetcher'
  s.authors     = ['Rachel Evans']
  s.email       = 'rachel.evans@bbc.co.uk'
  s.license     = 'Apache-2.0'
  s.require_paths = ["lib"]

  s.files       = Dir.glob(%w[
bin/*
lib/**/*.rb
scripts/default/*
  ])

  s.executables = %w[
    spud
  ]

  # NOTE: if you change these dependencies, also change the Gemfile
  s.add_dependency 'aws-sdk', "~> 2.0"
  s.add_dependency 'json', '~> 1.8'
end
