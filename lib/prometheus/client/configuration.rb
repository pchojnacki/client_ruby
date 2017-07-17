require 'prometheus/client/registry'
require 'prometheus/client/valuetype'

module Prometheus
  module Client
    class Configuration
      attr_accessor :value_class, :multiprocess_files_dir, :initial_mmap_file_size

      def initialize
        @value_class = ::Prometheus::Client::MmapedValue
        @multiprocess_files_dir = ENV['prometheus_multiproc_dir']
        @initial_mmap_file_size = 64 * 1024;
      end
    end
  end
end
