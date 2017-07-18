require 'json'
require 'mmap'

module Prometheus
  module Client
    class SimpleValue
      def initialize(type, metric_name, name, labels, value = 0)
        @value = value
      end

      def set(value)
        @value = value
      end

      def increment(by = 1)
        @value += by
      end

      def get
        @value
      end

      def self.multiprocess
        false
      end
    end
  end
end
