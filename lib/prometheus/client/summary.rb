# encoding: UTF-8

require 'prometheus/client/metric'

module Prometheus
  module Client
    # Summary is an accumulator for samples. It captures Numeric data and
    # provides an efficient quantile calculation mechanism.
    class Summary < Metric
      extend Gem::Deprecate

      # Value represents the state of a Summary at a given point.
      class Value < Hash
        attr_accessor :sum, :total

        def initialize(type, name, labels)
          @sum = value_class.new(type, name, "#{name}_sum", labels)
          @total = value_class.new(type, name, "#{name}_count", labels)
        end

        def observe(value)
          @sum.increment(value)
          @total.increment()
        end

        private
        
        def value_class
          Prometheus::Client.configuration.value_class
        end
      end

      def initialize(name, docstring, base_labels = {})
        super(name, docstring, base_labels)
      end

      def type
        :summary
      end

      # Records a given value.
      def observe(labels, value)
        label_set = label_set_for(labels)
        synchronize { @values[label_set].observe(value) }
      end

      alias add observe
      deprecate :add, :observe, 2016, 10

      # Returns the value for the given label set
      def get(labels = {})
        @validator.valid?(labels)

        synchronize do
          Value.new(@values[labels].sum)
        end
      end

      # Returns all label sets with their values
      def values
        synchronize do
          @values.each_with_object({}) do |(labels, value), memo|
            memo[labels] = value.sum
          end
        end
      end

      private

      def default(labels)
        Value.new(type, @name, labels)
      end
    end
  end
end
