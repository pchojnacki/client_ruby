require 'prometheus/client/registry'
require 'prometheus/client/valuetype'

module Prometheus
  module Client
    class Configuration
      attr_accessor :value_class, :multiprocess_files_dir

      def initialize
        @value_class = ::Prometheus::Client::MmapedValue
        @multiprocess_files_dir = ENV['prometheus_multiproc_dir']
      end
    end
  end
end
