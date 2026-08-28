# frozen_string_literal: true

module Rails
  module Code
    module Generator
      module ModelAttributes
        EXCLUDED_COLUMNS = %w[id created_at updated_at].freeze
        AUTH_USER_ASSOCIATION = "user"

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

          model_attributes.map { |attribute| "#{padding}#{attribute[:name]}: #{param_expression_for(attribute)}," }.join("\n")
        end

        def request_spec_association_givens
          associations_for_givens.map { |association|
            "  Given(:#{association[:name]}) { create :#{association[:factory]} }"
          }.join("\n")
        end

        def factory_definition_body
          lines = factory_association_lines + factory_attribute_lines
          return "    # TODO: add attributes" if lines.empty?

          lines.join("\n")
        end

        private

        def model_attribute_names
          model_attributes.map { |attribute| attribute[:name].to_sym }
        end

        def model_associations
          model_attributes.filter_map { |attribute| attribute[:association] }
                          .uniq { |association| association[:name] }
        end

        def associations_for_givens
          model_associations.reject { |association| association[:name] == AUTH_USER_ASSOCIATION }
        end

        def factory_association_lines
          model_associations.map { |association|
            "    association  :#{association[:name]}, factory: :#{association[:factory]}"
          }
        end

        def factory_attribute_lines
          attributes = model_attributes.reject { |attribute| attribute[:association] }
          return [] if attributes.empty?

          width = attributes.map { |attribute| attribute[:name].length }.max

          attributes.map { |attribute|
            name = attribute[:name].ljust(width)
            expression = FAKER_EXPRESSION_MAP.fetch(attribute[:type], "Faker::Lorem.word")
            "    #{name} { #{expression} }"
          }
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

        def param_expression_for(attribute)
          association = attribute[:association]
          return "#{association[:name]}.id" if association

          FAKER_EXPRESSION_MAP.fetch(attribute[:type], "Faker::Lorem.word")
        end

        def fetch_model_attributes
          klass = class_name.constantize
          return [] unless klass.respond_to?(:columns)

          associations_by_fk, polymorphic_fks = belongs_to_association_maps(klass)

          klass.columns.filter_map do |column|
            next if EXCLUDED_COLUMNS.include?(column.name)

            type = column.type.to_s

            {
              name: column.name,
              type: type,
              dry_type: DRY_TYPE_MAP[type],
              association: association_for_column(column.name, associations_by_fk, polymorphic_fks),
            }.compact
          end
        rescue StandardError
          []
        end

        def belongs_to_association_maps(klass)
          return [{}, []] unless klass.respond_to?(:reflect_on_all_associations)

          associations_by_fk = {}
          polymorphic_fks = []

          klass.reflect_on_all_associations(:belongs_to).each do |reflection|
            foreign_key = reflection.foreign_key.to_s

            if reflection.options[:polymorphic]
              polymorphic_fks << foreign_key
              next
            end

            associations_by_fk[foreign_key] = {
              name: reflection.name.to_s,
              factory: factory_name_for(reflection),
            }
          rescue StandardError
            next
          end

          [associations_by_fk, polymorphic_fks]
        rescue StandardError
          [{}, []]
        end

        def factory_name_for(reflection)
          reflection.klass.model_name.singular
        rescue StandardError
          reflection.name.to_s
        end

        def association_for_column(column_name, associations_by_fk, polymorphic_fks)
          return if polymorphic_fks.include?(column_name)
          return associations_by_fk[column_name] if associations_by_fk.key?(column_name)
          return unless column_name.end_with?("_id")

          association_name = column_name.delete_suffix("_id")
          return if association_name.empty?

          {
            name: association_name,
            factory: association_name,
          }
        end
      end
    end
  end
end
