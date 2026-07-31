# frozen_string_literal: true

require_relative "generator/version"
require_relative "generator/naming"

module Rails
  module Code
    module Generator
      class Error < StandardError; end
    end
  end
end

require_relative "generator/railtie" if defined?(::Rails::Railtie)
