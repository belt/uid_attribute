# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# CI matrix: AR_VERSION=7.2 or AR_VERSION=8.1 (default: latest)
ar_version = ENV.fetch("AR_VERSION", nil)
if ar_version
  gem "activemodel", "~> #{ar_version}.0"
  gem "activerecord", "~> #{ar_version}.0"
  gem "activesupport", "~> #{ar_version}.0"
else
  gem "activerecord", ">= 7.2"
end

group :development do
  gem "debug", ">= 1.11", require: false
  gem "rubycritic", "~> 5.0", require: false
  gem "reek", "~> 6.5", require: false
end

group :development, :test do
  gem "rspec", "~> 3.13"
  gem "standard", "~> 1.54", require: false
  gem "simplecov", "~> 0.22", require: false
  gem "sqlite3", "~> 2.9"
  gem "bundler-audit", "~> 0.9", require: false
  gem "railties", ">= 7.2", require: false
  gem "ammeter", "~> 1.1", require: false
end
