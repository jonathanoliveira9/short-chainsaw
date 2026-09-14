require "test_helper"

class ShortCodeGenerator::RangeAllocatorTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  ZkTestError = Class.new(StandardError)

  class FakeZkClient
    attr_reader :deleted_paths

    def initialize
      @next_seq = 0
      @deleted_paths = []
      @fail_create = false
    end

    def mkdir_p(_path); end

    def fail_next_create!
      @fail_create = true
    end

    def create(prefix, _data, mode:)
      raise ZkTestError, "boom" if @fail_create

      seq = @next_seq
      @next_seq += 1
      "#{prefix}#{format('%010d', seq)}"
    end

    def delete(path)
      @deleted_paths << path
    end
  end

  class RaisingOnDeleteClient < FakeZkClient
    def delete(path)
      raise ZkTestError, "delete boom"
    end
  end

  test "first allocation starts at the beginning of the sequence" do
    allocator = ShortCodeGenerator::RangeAllocator.new(client: FakeZkClient.new)

    assert_equal 0..999, allocator.next_range(block_size: 1000)
  end

  test "successive allocations return non-overlapping ranges" do
    allocator = ShortCodeGenerator::RangeAllocator.new(client: FakeZkClient.new)

    first = allocator.next_range(block_size: 1000)
    second = allocator.next_range(block_size: 1000)

    assert_equal 0..999, first
    assert_equal 1000..1999, second
  end

  test "deletes the transient sequence node after reading it" do
    client = FakeZkClient.new
    allocator = ShortCodeGenerator::RangeAllocator.new(client: client)

    allocator.next_range(block_size: 1000)

    assert_equal 1, client.deleted_paths.size
  end

  test "a failed delete does not prevent the range from being returned" do
    allocator = ShortCodeGenerator::RangeAllocator.new(client: RaisingOnDeleteClient.new)

    assert_equal 0..999, allocator.next_range(block_size: 1000)
  end

  test "wraps a ZK failure into ShortCodeGenerator::UnavailableError" do
    client = FakeZkClient.new
    client.fail_next_create!
    allocator = ShortCodeGenerator::RangeAllocator.new(client: client)

    assert_raises(ShortCodeGenerator::UnavailableError) do
      allocator.next_range(block_size: 1000)
    end
  end
end
