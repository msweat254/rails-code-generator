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

  def stub_pricing_config_columns(columns)
    klass = Class.new do
      define_singleton_method(:columns) { columns }
    end
    stub_const("PricingConfig", klass)
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
      stub_pricing_config_columns(
        [
          OpenStruct.new(name: "id", type: :integer),
          OpenStruct.new(name: "name", type: :string),
          OpenStruct.new(name: "amount", type: :decimal),
          OpenStruct.new(name: "created_at", type: :datetime),
          OpenStruct.new(name: "updated_at", type: :datetime),
        ],
      )

      expect(helper.model_attributes).to eq(
        [
          { name: "name", dry_type: :string },
          { name: "amount", dry_type: :decimal },
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
  end

  describe "template helpers" do
    before do
      stub_pricing_config_columns(
        [
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
  end

  describe "fallback helpers" do
    it "falls back to TODO comments when attributes are unavailable" do
      expect(helper.normalizer_attributes_list).to eq("    # TODO: add attributes")
      expect(helper.validator_attributes_list).to eq("        # TODO: add attributes")
      expect(helper.permitted_attributes_list).to eq("")
      expect(helper.permitted_attributes_list(include_id: true)).to eq("      :id,")
    end
  end
end
