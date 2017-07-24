require 'prometheus/client/mmaped_dict'
require 'tempfile'

describe Prometheus::Client::MmapedDict do
  let(:tmp_file) { Tempfile.new('mmaped_dict') }

  after do
    tmp_file.close
    tmp_file.unlink
  end

  describe '#initialize' do
    describe "empty mmap'ed file" do
      it 'is initialized with correct size' do
        dict = described_class.new(tmp_file.path)

        tmp_file.open
        expect(tmp_file.size).to eq(dict.initial_mmap_file_size)
      end
    end

    describe "mmap'ed file that is above minimum size" do
      let(:above_minimum_size) { described_class::MINIMUM_SIZE + 1 }

      before do
        tmp_file.truncate(above_minimum_size)
      end

      it 'is initialized with the same size' do
        described_class.new(tmp_file.path)

        tmp_file.open
        expect(tmp_file.size).to eq(above_minimum_size)
      end
    end
  end
end
