require 'prometheus/client/registry'
require 'prometheus/client/configuration'

module Prometheus
  # Client is a ruby implementation for a Prometheus compatible client.
  module Client
    class << self
      attr_writer :configuration

      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield(configuration)
      end

      # Returns a default registry object
      def registry
        @registry ||= Registry.new
      end
    end
  end
end
