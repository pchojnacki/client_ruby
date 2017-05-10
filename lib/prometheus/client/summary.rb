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
          @sum = ValueClass.new(type, name, name + '_sum', labels)
          @total = ValueClass.new(type, name, name + '_count', labels)
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
        synchronize do
          @sum[label_set].increment(1)
          @total[label_set].increment(value)
        end
      end
      alias add observe
      deprecate :add, :observe, 2016, 10

      # Returns the value for the given label set
      def get(labels = {})
        @validator.valid?(labels)

        synchronize do
          Value.new(@values[labels])
        end
      end

      # Returns all label sets with their values
      def values
        synchronize do
          @values.each_with_object({}) do |(labels, value), memo|
            memo[labels] = value
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
