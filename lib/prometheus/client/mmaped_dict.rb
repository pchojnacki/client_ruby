require 'prometheus/client'

module Prometheus
  module Client
    class ParsingError < StandardError; end

    # A dict of doubles, backed by an mmapped file.
    #
    # The file starts with a 4 byte int, indicating how much of it is used.
    # Then 4 bytes of padding.
    # There's then a number of entries, consisting of a 4 byte int which is the
    # size of the next field, a utf-8 encoded string key, padding to an 8 byte
    # alignment, and then a 8 byte float which is the value.
    #
    # TODO(julius): dealing with Mmap.new, truncate etc. errors?
    class MmapedDict
      MINIMUM_SIZE = 4.freeze
      attr_reader :m, :capacity, :used, :positions

      def initialize(filename)
        @mutex = Mutex.new
        @f = File.open(filename, 'a+b')
        process_file
      rescue StandardError => e
        raise ParsingError.new("exception #{e} while processing metrics file #{@f.path}")
      end

      # Yield (key, value, pos). No locking is performed.
      def all_values
        read_all_values.map { |k, v, p| [k, v] }
      end

      def read_value(key)
        @mutex.synchronize do
          init_value(key) unless @positions.has_key?(key)
        end
        pos = @positions[key]
        # We assume that reading from an 8 byte aligned value is atomic.
        @m[pos..pos+7].unpack('d')[0]
      end

      def write_value(key, value)
        @mutex.synchronize do
          init_value(key) unless @positions.has_key?(key)
        end
        pos = @positions[key]
        # We assume that writing to an 8 byte aligned value is atomic.
        @m[pos..pos+7] = [value].pack('d')
      end

      def close()
        @m.munmap
        @f.close
      end

      def initial_mmap_file_size
        Prometheus::Client.configuration.initial_mmap_file_size
      end

      private

      def process_file
        if @f.size < MINIMUM_SIZE
          @f.truncate(initial_mmap_file_size)
        end

        @capacity = @f.size
        @m = Mmap.new(@f.path, 'rw', Mmap::MAP_SHARED)
        # @m.mlock # TODO: Why does this raise an error?

        @positions = {}
        @used = @m[0..3].unpack('l')[0]
        if @used == 0
          @used = 8
          @m[0..3] = [@used].pack('l')
        else
          read_all_values.each do |key, _, pos|
            @positions[key] = pos
          end
        end
      end

      # Initialize a value. Lock must be held by caller.
      def init_value(key)
        # Pad to be 8-byte aligned.
        padded = key + (' ' * (8 - (key.length + 4) % 8))
        value = [key.length, padded, 0.0].pack("lA#{padded.length}d")
        while @used + value.length > @capacity
          @capacity *= 2
          @f.truncate(@capacity)
          @m.unmap
          @m = Mmap.new(@f.path, 'rw', Mmap::MAP_SHARED)
        end
        @m[@used..@used + value.length] = value

        # Update how much space we've used.
        @used += value.length
        @m[0..3] = [@used].pack('l')
        @positions[key] = @used - 8
      end

      # Yield (key, value, pos). No locking is performed.
      def read_all_values
        pos = 8
        values = []
        while pos < @used
          encoded_len = @m[pos..-1].unpack('l')[0]
          pos += 4
          encoded = @m[pos..-1].unpack("A#{encoded_len}")[0]
          padded_len = encoded_len + (8 - (encoded_len + 4) % 8)
          pos += padded_len
          value = @m[pos..-1].unpack('d')[0]
          values << [encoded, value, pos]
          pos += 8
        end
        values
      end
    end
  end
end