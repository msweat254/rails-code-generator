# frozen_string_literal: true

module Rails
  module Code
    module Generator
      module ModelAttributes
        EXCLUDED_COLUMNS = %w[id created_at updated_at].freeze

        DRY_TYPE_MAP = {
          "string" => :string,
          "text" => :string,
          "citext" => :string,
          "integer" => :integer,
          "bigint" => :integer,
          "float" => :float,
          "decimal" => :decimal,
          "boolean" => :bool,
          "date" => :date,
          "datetime" => :time,
          "timestamp" => :time,
          "timestamptz" => :time,
          "json" => :hash,
          "jsonb" => :hash,
          "uuid" => :string,
        }.freeze

        FAKER_EXPRESSION_MAP = {
          "string" => "Faker::Lorem.word",
          "text" => "Faker::Lorem.paragraph",
          "citext" => "Faker::Lorem.word",
          "integer" => "Faker::Number.number(digits: 5)",
          "bigint" => "Faker::Number.number(digits: 5)",
          "float" => "Faker::Number.decimal(l_digits: 2).to_f",
          "decimal" => "Faker::Number.decimal(l_digits: 2)",
          "boolean" => "Faker::Boolean.boolean",
          "date" => "Faker::Date.forward(days: 30)",
          "datetime" => "Faker::Time.forward(days: 30)",
          "timestamp" => "Faker::Time.forward(days: 30)",
          "timestamptz" => "Faker::Time.forward(days: 30)",
          "json" => "{}",
          "jsonb" => "{}",
          "uuid" => "Faker::Internet.uuid",
        }.freeze

        def model_attributes
          @model_attributes ||= fetch_model_attributes
        end

        def permitted_attributes_list(include_id: false)
          names = model_attribute_names
          names = [:id, *names] if include_id
          format_symbol_list(names)
        end

        def normalizer_attributes_list(include_id: false)
          names = model_attribute_names
          names = [:id, *names] if include_id
          return "    # TODO: add attributes" if names.empty?

          format_symbol_list(names, indent: 4)
        end

        def validator_attributes_list
          return "        # TODO: add attributes" if model_attributes.empty?

          model_attributes.map { |attribute| validator_line_for(attribute) }.join("\n")
        end

        def request_params_attributes_list(indent: 10)
          padding = " " * indent
          return "#{padding}# TODO: add attributes" if model_attributes.empty?

          model_attributes.map { |attribute| "#{padding}#{attribute[:name]}: #{faker_expression_for(attribute)}," }.join("\n")
        end

        private

        def model_attribute_names
          model_attributes.map { |attribute| attribute[:name].to_sym }
        end

        def format_symbol_list(names, indent: 6)
          padding = " " * indent
          names.map { |name| "#{padding}:#{name}," }.join("\n")
        end

        def validator_line_for(attribute)
          name = attribute[:name]
          dry_type = attribute[:dry_type]

          if dry_type
            "        optional(:#{name}).maybe :#{dry_type}"
          else
            "        optional(:#{name})"
          end
        end

        def faker_expression_for(attribute)
          FAKER_EXPRESSION_MAP.fetch(attribute[:type], "Faker::Lorem.word")
        end

        def fetch_model_attributes
          klass = class_name.constantize
          return [] unless klass.respond_to?(:columns)

          klass.columns.filter_map do |column|
            next if EXCLUDED_COLUMNS.include?(column.name)

            type = column.type.to_s

            {
              name: column.name,
              type: type,
              dry_type: DRY_TYPE_MAP[type],
            }
          end
        rescue StandardError
          []
        end
      end
    end
  end
end
