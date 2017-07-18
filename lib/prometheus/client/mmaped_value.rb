require 'prometheus/client/mmaped_dict'
require 'json'

module Prometheus
  module Client
    # A float protected by a mutex backed by a per-process mmaped file.
    class MmapedValue
      @@files = {}
      @@files_lock = Mutex.new
      @@pid = Process.pid

      def initialize(type, metric_name, name, labels, multiprocess_mode='')
        file_prefix = type.to_s
        if type == :gauge
          file_prefix += '_' + multiprocess_mode.to_s
        end

        @@files_lock.synchronize do
          unless @@files.has_key?(file_prefix)
            filename = File.join(Prometheus::Client.configuration.multiprocess_files_dir, "#{file_prefix}_#{@@pid}.db")
            @@files[file_prefix] = MmapedDict.new(filename)
          end
        end

        @file = @@files[file_prefix]
        labelnames = []
        labelvalues = []
        labels.each do |k, v|
          labelnames << k
          labelvalues << v
        end

        @key = [metric_name, name, labelnames, labelvalues].to_json
        @value = read_value(@key)
        @mutex = Mutex.new
      end

      def increment(amount=1)
        @mutex.synchronize do
          @value += amount
          write_value(@key, @value)
          @value
        end
      end

      def set(value)
        @mutex.synchronize do
          @value = value
          write_value(@key, @value)
          @value
        end
      end

      def get
        @mutex.synchronize do
          return @value
        end
      end

      def self.multiprocess
        true
      end

      private

      def write_value(key, val)
        @file.write_value(key, val)
      rescue StandardError => e
        Prometheus::Client.logger.warn("writing value to #{@file.path} failed with #{e}")
      end

      def read_value(key)
        @file.read_value(key)
      rescue StandardError => e
        Prometheus::Client.logger.warn("readomg value from #{@file.path} failed with #{e}")
      end
    end
  end
end

