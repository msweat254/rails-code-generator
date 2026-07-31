# frozen_string_literal: true

require "rails/generators"
require "rails/generators/named_base"
require "rails/code/generator/naming"

module RailsCodeGenerator
  class ResourcesGenerator < Rails::Generators::NamedBase
    include Rails::Code::Generator::Naming

    class_option :bulk, type: :boolean, default: false, desc: "Generate bulk endpoints"

    source_root File.expand_path("templates", __dir__)

    def create_controller
      template "#{template_mode}/controller.rb", File.join("app/controllers", "#{table_name}_controller.rb")
    end

    def create_services
      template "#{template_mode}/build.rb", File.join("app/services", table_name, "build.rb")
      template "#{template_mode}/save.rb", File.join("app/services", table_name, "save.rb")
      template "#{template_mode}/update.rb", File.join("app/services", table_name, "update.rb")
    end

    def create_validators
      template "#{template_mode}/create_validator.rb",
               File.join("app/validators", table_name, "create_validator.rb")
      template "#{template_mode}/update_validator.rb",
               File.join("app/validators", table_name, "update_validator.rb")
    end

    def create_request_specs
      template "shared/index_spec.rb", File.join("spec/requests", table_name, "index_spec.rb")
      template "shared/show_spec.rb", File.join("spec/requests", table_name, "show_spec.rb")
      template "#{template_mode}/create_spec.rb", File.join("spec/requests", table_name, "create_spec.rb")
      template "#{template_mode}/update_spec.rb", File.join("spec/requests", table_name, "update_spec.rb")
      template "#{template_mode}/destroy_spec.rb", File.join("spec/requests", table_name, "destroy_spec.rb")
    end
  end
end
