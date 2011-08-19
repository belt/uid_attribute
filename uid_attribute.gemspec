# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'uid_attribute/version'

Gem::Specification.new do |s|
  s.name        = 'uid_attribute'
  s.version     = UIDAttribute::VERSION
  s.authors     = ['Paul Belt']
  s.email       = ['paul.belt@gmail.com']
  s.homepage    = %q{http://github.com/belt/uid_attribute}
  s.summary     = %q{machina to automatically generate UIDs upon object instantiation}
  s.description = %q{Some projects are confined by regulations (or requirements) that demand data can not be used to identify individuals. In such cases data must be scrubbed i.e. identifiable object names must be removed before unauthorized users can see said data. For example, when a developer needs to recreate a bug on their own system that was reported by a customer using customer-specific data.

One method to do this is to use globally unique identifiers within the system to identify any given object.}

  s.rubyforge_project = 'uid_attribute'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency 'rspec'
  s.add_runtime_dependency 'uuidtools'
end

