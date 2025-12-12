# frozen_string_literal: true

require_relative "lib/uid_attribute/version"

Gem::Specification.new do |spec|
  spec.name = "uid_attribute"
  spec.version = UidAttribute::VERSION
  spec.authors = ["Paul Belt"]
  spec.email = ["153964+belt@users.noreply.github.com"]

  spec.summary = "Auto-assign UUIDs (v4 / v7) to PORO and ActiveRecord attributes."
  spec.description = <<~DESC
    Auto-generates a UUID for a designated attribute (default :uid) on
    instantiation. Defaults to UUID v7 (RFC 9562) — time-ordered and
    index-friendly — with v4 available. Works with PORO via Poro mixin
    and ActiveRecord via ActiveRecordIntegration. Includes a standalone
    generator, ActiveModel custom type, and opt-in refinements.
  DESC
  spec.homepage = "https://github.com/belt/uid_attribute"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.0"
  spec.required_rubygems_version = ">= 3.6"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/belt/uid_attribute",
    "changelog_uri" => "https://github.com/belt/uid_attribute/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/belt/uid_attribute/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "lib/generators/**/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activemodel", ">= 7.2"
  spec.add_dependency "activesupport", ">= 7.2"
end
