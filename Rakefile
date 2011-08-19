begin
  require 'cover_me'
  namespace :cover_me do
    desc 'rcov-esque report for ruby-1.9.x'
    task :report do
      # we expect this to fail
      begin
        Rake::Task['spec'].invoke
      rescue => e
      end

      CoverMe.complete!
    end
  end
rescue LoadError; end

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the uid_attribute plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the uid_attribute plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'UidAttribute'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = 'uid_attribute'
    gemspec.summary = 'machina to automatically generate UUIDs upon object instantiation.'
    gemspec.description = "Some projects are confined by regulations (or requirements) that demand data can not be used to identify individuals. In such cases data must be scrubbed i.e. identifiable object names must be removed before unauthorized users can see said data. For example, when a developer needs to recreate a bug on their own system that was reported by a customer using customer-specific data.\n\nOne method to do this is to use globally unique identifiers within the system to identify any given object."
    gemspec.email = 'Paul Belt'
    gemspec.authors = ['Paul Belt']
    gemspec.homepage = 'http://github.com/belt/uid_attribute'
    gemspec.extra_rdoc_files = ['README.rdoc']
    gemspec.rdoc_options = ['--charset=UTF-8']
    gemspec.add_dependency('uuidtools', '>= 2.1.1')
    gemspec.rubyforge_project = 'uid_attribute'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

