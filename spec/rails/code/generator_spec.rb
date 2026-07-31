# frozen_string_literal: true

RSpec.describe Rails::Code::Generator do
  it "has a version number" do
    expect(Rails::Code::Generator::VERSION).not_to be nil
  end

  it "defines an Error class" do
    expect(Rails::Code::Generator::Error).to be < StandardError
  end
end
