# frozen_string_literal: true

require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # rspec not available
end

begin
  require "standard/rake"
rescue LoadError
  # standard not available
end

desc "Run reek code smell detection"
task :reek do
  sh "bundle exec reek lib/"
end

desc "Run rubycritic quality report"
task :quality do
  sh "bundle exec rubycritic --no-browser lib/"
end

desc "Run bundler-audit security check"
task :audit do
  sh "bundle exec bundler-audit check --update"
end

desc "Run all checks (spec + lint + reek + audit)"
task ci: %i[spec standard reek audit]

task default: :spec
