# frozen_string_literal: true

module Rails
  module Code
    module Generator
      module Naming
        def singular_name
          file_name
        end

        def plural_class_name
          table_name.camelize
        end

        def resource_controller_class
          "#{plural_class_name}Controller"
        end

        def resource_normalizer_class
          "#{plural_class_name}Normalizer"
        end

        def route_path
          table_name
        end

        def resource_module_name
          plural_class_name
        end

        def template_mode
          options[:bulk] ? "bulk" : "single"
        end
      end
    end
  end
end
