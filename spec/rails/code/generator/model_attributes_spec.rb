# frozen_string_literal: true

require "ostruct"
require "spec_helper"
require "rails/code/generator/model_attributes"

RSpec.describe Rails::Code::Generator::ModelAttributes do
  subject(:helper) do
    Class.new do
      include Rails::Code::Generator::ModelAttributes

      def class_name
        "PricingConfig"
      end
    end.new
  end

  def stub_pricing_config(columns:, reflections: [])
    klass = Class.new do
      define_singleton_method(:columns) { columns }
      define_singleton_method(:reflect_on_all_associations) { |_macro = nil| reflections }
    end
    stub_const("PricingConfig", klass)
  end

  def reflection_for(name:, foreign_key:, factory: nil, polymorphic: false, klass: nil)
    associated_klass = klass || Class.new do
      define_singleton_method(:model_name) do
        OpenStruct.new(singular: factory || name.to_s)
      end
    end

    OpenStruct.new(
      name: name,
      foreign_key: foreign_key,
      options: { polymorphic: polymorphic },
      klass: associated_klass,
    )
  end

  describe "#model_attributes" do
    it "returns an empty array when the model cannot be loaded" do
      expect(helper.model_attributes).to eq([])
    end

    it "returns an empty array when constantize raises" do
      allow(helper).to receive(:class_name).and_return("MissingModel")

      expect(helper.model_attributes).to eq([])
    end

    it "excludes id, created_at, and updated_at" do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
          OpenStruct.new(name: "amount", type: :decimal),
          OpenStruct.new(name: "created_at", type: :datetime),
          OpenStruct.new(name: "updated_at", type: :datetime),
        ],
      )

      expect(helper.model_attributes).to eq(
        [
          { name: "name", type: "string", dry_type: :string },
          { name: "amount", type: "decimal", dry_type: :decimal },
        ],
      )
    end

    it "returns an empty array when columns raises" do
      klass = Class.new do
        def self.columns
          raise "db unavailable"
        end
      end
      stub_const("PricingConfig", klass)

      expect(helper.model_attributes).to eq([])
    end

    it "attaches belongs_to association metadata from reflections" do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "id", type: :integer),
          OpenStruct.new(name: "location_id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
        ],
        reflections: [
          reflection_for(name: :location, foreign_key: "location_id", factory: "location"),
        ],
      )

      expect(helper.model_attributes).to include(
        name: "location_id",
        type: "integer",
        dry_type: :integer,
        association: { name: "location", factory: "location" },
      )
    end

    it "falls back to stripping _id when no reflection matches" do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "parent_id", type: :integer),
        ],
      )

      expect(helper.model_attributes).to eq(
        [
          {
            name: "parent_id",
            type: "integer",
            dry_type: :integer,
            association: { name: "parent", factory: "parent" },
          },
        ],
      )
    end

    it "skips polymorphic belongs_to foreign keys" do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "commentable_id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
        ],
        reflections: [
          reflection_for(name: :commentable, foreign_key: "commentable_id", polymorphic: true),
        ],
      )

      expect(helper.model_attributes).to eq(
        [
          { name: "commentable_id", type: "integer", dry_type: :integer },
          { name: "name", type: "string", dry_type: :string },
        ],
      )
    end

    it "uses the associated model name as the factory for renamed belongs_to" do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "author_id", type: :integer),
        ],
        reflections: [
          reflection_for(name: :author, foreign_key: "author_id", factory: "user"),
        ],
      )

      expect(helper.model_attributes.first[:association]).to eq(
        name: "author",
        factory: "user",
      )
    end
  end

  describe "template helpers" do
    before do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
          OpenStruct.new(name: "active", type: :boolean),
          OpenStruct.new(name: "created_at", type: :datetime),
          OpenStruct.new(name: "updated_at", type: :datetime),
        ],
      )
    end

    it "formats permitted attributes without id by default" do
      expect(helper.permitted_attributes_list).to eq(
        "      :name,\n      :active,",
      )
    end

    it "formats permitted attributes with id when requested" do
      expect(helper.permitted_attributes_list(include_id: true)).to eq(
        "      :id,\n      :name,\n      :active,",
      )
    end

    it "formats normalizer attributes" do
      expect(helper.normalizer_attributes_list).to eq(
        "    :name,\n    :active,",
      )
    end

    it "formats validator attributes with dry types" do
      expect(helper.validator_attributes_list).to eq(
        "        optional(:name).maybe :string\n        optional(:active).maybe :bool",
      )
    end

    it "formats request params with Faker expressions by type" do
      expect(helper.request_params_attributes_list).to eq(
        "          name: Faker::Lorem.word,\n          active: Faker::Boolean.boolean,",
      )
    end
  end

  describe "association request helpers" do
    before do
      stub_pricing_config(
        columns: [
          OpenStruct.new(name: "id", type: :integer),
          OpenStruct.new(name: "user_id", type: :integer),
          OpenStruct.new(name: "location_id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
        ],
        reflections: [
          reflection_for(name: :user, foreign_key: "user_id", factory: "user"),
          reflection_for(name: :location, foreign_key: "location_id", factory: "location"),
        ],
      )
    end

    it "uses association.id for foreign keys and Faker for other attributes" do
      expect(helper.request_params_attributes_list).to eq(
        "          user_id: user.id,\n" \
        "          location_id: location.id,\n" \
        "          name: Faker::Lorem.word,",
      )
    end

    it "emits Given lines for associations except the auth user" do
      expect(helper.request_spec_association_givens).to eq(
        "  Given(:location) { create :location }",
      )
    end

    it "formats a FactoryBot definition with associations and Faker attributes" do
      expect(helper.factory_definition_body).to eq(
        "    association  :user, factory: :user\n" \
        "    association  :location, factory: :location\n" \
        "    name { Faker::Lorem.word }",
      )
    end
  end

  describe "fallback helpers" do
    it "falls back to TODO comments when attributes are unavailable" do
      expect(helper.normalizer_attributes_list).to eq("    # TODO: add attributes")
      expect(helper.validator_attributes_list).to eq("        # TODO: add attributes")
      expect(helper.request_params_attributes_list).to eq("          # TODO: add attributes")
      expect(helper.request_spec_association_givens).to eq("")
      expect(helper.factory_definition_body).to eq("    # TODO: add attributes")
      expect(helper.permitted_attributes_list).to eq("")
      expect(helper.permitted_attributes_list(include_id: true)).to eq("      :id,")
    end
  end
end
