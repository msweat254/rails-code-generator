# frozen_string_literal: true

require_relative "generator/version"
require_relative "generator/naming"
require_relative "generator/model_attributes"

module Rails
  module Code
    module Generator
      class Error < StandardError; end
    end
  end
end

require_relative "generator/railtie" if defined?(::Rails::Railtie)
