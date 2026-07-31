# frozen_string_literal: true

require_relative "lib/rails/code/generator/version"

Gem::Specification.new do |spec|
  spec.name = "rails-code-generator"
  spec.version = Rails::Code::Generator::VERSION
  spec.authors = ["Michael Sweat"]
  spec.email = ["michael.sweat@ionsolar.com"]

  spec.summary = "Custom Rails generators for scaffolding and code generation"
  spec.description = "A collection of Rails generators that automate common code generation tasks " \
                     "in Rails applications."
  spec.homepage = "https://github.com/msweat254/rails-code-generator"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/msweat254/rails-code-generator"
  spec.metadata["changelog_uri"] = "https://github.com/msweat254/rails-code-generator/blob/main/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
end
