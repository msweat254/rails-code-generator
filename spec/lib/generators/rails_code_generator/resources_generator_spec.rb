# frozen_string_literal: true

require "fileutils"
require "ostruct"
require "spec_helper"
require "generators/rails_code_generator/resources/resources_generator"
require "rails/generators/testing/behavior"
require "rails/generators/testing/setup_and_teardown"

RSpec.describe RailsCodeGenerator::ResourcesGenerator do
  include FileUtils
  include Rails::Generators::Testing::Behavior
  include Rails::Generators::Testing::SetupAndTeardown

  tests described_class

  destination File.expand_path("../../../../tmp/generator", __dir__)

  def read_generated(path)
    File.read(File.join(destination_root, path))
  end

  let(:expected_files) do
    [
      "app/controllers/pricing_configs_controller.rb",
      "app/services/pricing_configs/build.rb",
      "app/services/pricing_configs/save.rb",
      "app/services/pricing_configs/update.rb",
      "app/validators/pricing_configs/create_validator.rb",
      "app/validators/pricing_configs/update_validator.rb",
      "app/normalizers/pricing_configs_normalizer.rb",
      "spec/factories/pricing_config.rb",
      "spec/requests/pricing_configs/index_spec.rb",
      "spec/requests/pricing_configs/show_spec.rb",
      "spec/requests/pricing_configs/create_spec.rb",
      "spec/requests/pricing_configs/update_spec.rb",
      "spec/requests/pricing_configs/destroy_spec.rb",
    ]
  end

  before { prepare_destination }

  describe "single mode" do
    before { run_generator ["PricingConfig"] }

    it "creates all expected files" do
      expected_files.each do |file|
        expect(File.exist?(File.join(destination_root, file))).to be true
      end
    end

    it "generates the controller with single-mode patterns" do
      content = read_generated("app/controllers/pricing_configs_controller.rb")

      expect(content).to include("class PricingConfigsController < ApplicationController")
      expect(content).to include("PricingConfigs::CreateValidator.call params")
      expect(content).to include("pricing_config = PricingConfigs::Build.call validated_params")
      expect(content).not_to include("Activities::Save.call")
    end

    it "generates services with single-mode patterns" do
      build = read_generated("app/services/pricing_configs/build.rb")
      save = read_generated("app/services/pricing_configs/save.rb")
      update = read_generated("app/services/pricing_configs/update.rb")

      expect(build).to include("::PricingConfig.new params")
      expect(build).not_to include("ServiceHelpers::CleanBuildParams")
      expect(save).to include("pricing_config.save!")
      expect(save).not_to include(".import")
      expect(update).to include("pricing_config.assign_attributes params")
      expect(update).not_to include("ServiceHelpers::CleanUpdateParams")
    end

    it "generates validators with singular param keys" do
      create_validator = read_generated("app/validators/pricing_configs/create_validator.rb")
      update_validator = read_generated("app/validators/pricing_configs/update_validator.rb")

      expect(create_validator).to include("required(:pricing_config).maybe :hash do")
      expect(update_validator).to include("required(:pricing_config).maybe :hash do")
    end

    it "generates the normalizer" do
      content = read_generated("app/normalizers/pricing_configs_normalizer.rb")

      expect(content).to include("class PricingConfigsNormalizer < BaseResponseNormalizer")
      expect(content).to include("attributes(")
    end

    it "generates request specs with singular param keys and id in destroy path" do
      create_spec = read_generated("spec/requests/pricing_configs/create_spec.rb")
      update_spec = read_generated("spec/requests/pricing_configs/update_spec.rb")
      destroy_spec = read_generated("spec/requests/pricing_configs/destroy_spec.rb")

      expect(create_spec).to include("pricing_config: {")
      expect(update_spec).to include("pricing_config: {")
      expect(destroy_spec).to include(%q(Given(:path) { "/pricing_configs/#{pricing_config.id}" }))
      expect(destroy_spec).to include("delete path, headers: api_auth_headers(user)")
      expect(destroy_spec).not_to include("ids: ids")
    end
  end

  describe "bulk mode" do
    before { run_generator ["PricingConfig", "--bulk"] }

    it "creates all expected files" do
      expected_files.each do |file|
        expect(File.exist?(File.join(destination_root, file))).to be true
      end
    end

    it "generates the controller with bulk-mode patterns" do
      content = read_generated("app/controllers/pricing_configs_controller.rb")

      expect(content).to include("Activities::Save.call")
      expect(content).to include("destroy_all")
      expect(content).to include("def pricing_config_params")
    end

    it "generates services with bulk-mode patterns" do
      build = read_generated("app/services/pricing_configs/build.rb")
      save = read_generated("app/services/pricing_configs/save.rb")
      update = read_generated("app/services/pricing_configs/update.rb")

      expect(build).to include("ServiceHelpers::CleanBuildParams.call")
      expect(save).to include("PricingConfig.import")
      expect(update).to include("ServiceHelpers::CleanUpdateParams.call")
      expect(update).to include("pricing_config.assign_attributes params[pricing_config.id]")
    end

    it "generates validators with plural param keys" do
      create_validator = read_generated("app/validators/pricing_configs/create_validator.rb")
      update_validator = read_generated("app/validators/pricing_configs/update_validator.rb")

      expect(create_validator).to include("required(:pricing_configs).maybe :hash do")
      expect(update_validator).to include("required(:pricing_configs).maybe :hash do")
    end

    it "generates request specs with plural param keys and ids param for destroy" do
      create_spec = read_generated("spec/requests/pricing_configs/create_spec.rb")
      update_spec = read_generated("spec/requests/pricing_configs/update_spec.rb")
      destroy_spec = read_generated("spec/requests/pricing_configs/destroy_spec.rb")

      expect(create_spec).to include("pricing_configs: {")
      expect(update_spec).to include("pricing_configs: {")
      expect(destroy_spec).to include('RSpec.describe "[DELETE] /pricing_configs", type: :request do')
      expect(destroy_spec).to include("params: { ids: ids }")
    end
  end

  describe "model column introspection" do
    before do
      columns = [
        OpenStruct.new(name: "id", type: :integer),
        OpenStruct.new(name: "name", type: :string),
        OpenStruct.new(name: "amount", type: :decimal),
        OpenStruct.new(name: "created_at", type: :datetime),
        OpenStruct.new(name: "updated_at", type: :datetime),
      ]
      stub_const(
        "PricingConfig",
        Class.new do
          define_singleton_method(:columns) { columns }
        end,
      )
    end

    it "fills attributes from the model in single mode" do
      run_generator ["PricingConfig"]

      build = read_generated("app/services/pricing_configs/build.rb")
      update = read_generated("app/services/pricing_configs/update.rb")
      create_validator = read_generated("app/validators/pricing_configs/create_validator.rb")
      normalizer = read_generated("app/normalizers/pricing_configs_normalizer.rb")
      create_spec = read_generated("spec/requests/pricing_configs/create_spec.rb")
      update_spec = read_generated("spec/requests/pricing_configs/update_spec.rb")

      expect(build).to include(":name,")
      expect(build).to include(":amount,")
      expect(build).not_to include(":id,")
      expect(build).not_to include(":created_at,")
      expect(update).to include(":name,")
      expect(update).not_to include(":id,")
      expect(create_validator).to include("optional(:name).maybe :string")
      expect(create_validator).to include("optional(:amount).maybe :decimal")
      expect(normalizer).to include(":name,")
      expect(normalizer).to include(":amount,")
      expect(normalizer).not_to include("# TODO: add attributes")
      expect(create_spec).to include("name: Faker::Lorem.word,")
      expect(create_spec).to include("amount: Faker::Number.decimal(l_digits: 2),")
      expect(update_spec).to include("name: Faker::Lorem.word,")
      expect(update_spec).to include("amount: Faker::Number.decimal(l_digits: 2),")
    end

    it "includes id in bulk update permitted attributes" do
      run_generator ["PricingConfig", "--bulk"]

      update = read_generated("app/services/pricing_configs/update.rb")

      expect(update).to include(":id,")
      expect(update).to include(":name,")
      expect(update).to include(":amount,")
      expect(update).not_to include(":created_at,")
    end
  end

  describe "model association introspection" do
    before do
      columns = [
        OpenStruct.new(name: "id", type: :integer),
        OpenStruct.new(name: "user_id", type: :integer),
        OpenStruct.new(name: "location_id", type: :integer),
        OpenStruct.new(name: "name", type: :string),
        OpenStruct.new(name: "created_at", type: :datetime),
        OpenStruct.new(name: "updated_at", type: :datetime),
      ]
      location_klass = Class.new do
        define_singleton_method(:model_name) { OpenStruct.new(singular: "location") }
      end
      user_klass = Class.new do
        define_singleton_method(:model_name) { OpenStruct.new(singular: "user") }
      end
      reflections = [
        OpenStruct.new(
          name: :user,
          foreign_key: "user_id",
          options: {},
          klass: user_klass,
        ),
        OpenStruct.new(
          name: :location,
          foreign_key: "location_id",
          options: {},
          klass: location_klass,
        ),
      ]
      stub_const(
        "PricingConfig",
        Class.new do
          define_singleton_method(:columns) { columns }
          define_singleton_method(:reflect_on_all_associations) { |_macro = nil| reflections }
        end,
      )
    end

    it "adds association Givens and uses association ids in create/update specs" do
      run_generator ["PricingConfig"]

      create_spec = read_generated("spec/requests/pricing_configs/create_spec.rb")
      update_spec = read_generated("spec/requests/pricing_configs/update_spec.rb")
      factory = read_generated("spec/factories/pricing_config.rb")

      expect(create_spec).to include("Given(:location) { create :location }")
      expect(create_spec).to include("location_id: location.id,")
      expect(create_spec).to include("user_id: user.id,")
      expect(create_spec).to include("name: Faker::Lorem.word,")
      expect(create_spec.scan("Given(:user)").size).to eq(1)

      expect(update_spec).to include("Given(:location) { create :location }")
      expect(update_spec).to include("location_id: location.id,")
      expect(update_spec).to include("user_id: user.id,")

      expect(factory).to include("factory :pricing_config do")
      expect(factory).to include("association  :user, factory: :user")
      expect(factory).to include("association  :location, factory: :location")
      expect(factory).to include("name { Faker::Lorem.word }")
      expect(factory).not_to include("user_id")
      expect(factory).not_to include("location_id")
    end
  end
end
