require 'bundler/gem_tasks'

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

