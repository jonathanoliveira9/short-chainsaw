require "test_helper"

class ShortCodeGeneratorTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup { ShortCodeGenerator.reset! }
  teardown { ShortCodeGenerator.reset! }

  class FakeAllocator
    def initialize(*ranges)
      @ranges = ranges.dup
    end

    def next_range(block_size:)
      @ranges.shift || (raise ShortCodeGenerator::UnavailableError, "no ranges left")
    end
  end

  def with_allocator(allocator)
    ShortCodeGenerator.instance_variable_set(:@allocator, allocator)
    yield
  end

  test "encodes known integers as base62" do
    with_allocator(FakeAllocator.new(0..0)) { assert_equal "0", ShortCodeGenerator.call }

    ShortCodeGenerator.reset!
    with_allocator(FakeAllocator.new(35..35)) { assert_equal "z", ShortCodeGenerator.call }

    ShortCodeGenerator.reset!
    with_allocator(FakeAllocator.new(61..61)) { assert_equal "Z", ShortCodeGenerator.call }

    ShortCodeGenerator.reset!
    with_allocator(FakeAllocator.new(62..62)) { assert_equal "10", ShortCodeGenerator.call }
  end

  test "issues sequential ids within a single held range" do
    with_allocator(FakeAllocator.new(0..2)) do
      codes = Array.new(3) { ShortCodeGenerator.call }
      assert_equal %w[0 1 2], codes
    end
  end

  test "requests a fresh range only once the held one is exhausted" do
    with_allocator(FakeAllocator.new(0..1, 2..3)) do
      codes = Array.new(4) { ShortCodeGenerator.call }
      assert_equal %w[0 1 2 3], codes
    end
  end

  test "propagates UnavailableError from the allocator" do
    with_allocator(FakeAllocator.new) do
      assert_raises(ShortCodeGenerator::UnavailableError) { ShortCodeGenerator.call }
    end
  end

  test "never hands out a duplicate code under concurrent access" do
    with_allocator(FakeAllocator.new(0..999)) do
      codes = Array.new(20) do
        Thread.new { Array.new(50) { ShortCodeGenerator.call } }
      end.flat_map(&:value)

      assert_equal 1000, codes.uniq.size
    end
  end

  test "decode_base62 is the inverse of encode_base62" do
    assert_equal 0, ShortCodeGenerator.decode_base62("0")
    assert_equal 35, ShortCodeGenerator.decode_base62("z")
    assert_equal 61, ShortCodeGenerator.decode_base62("Z")
    assert_equal 62, ShortCodeGenerator.decode_base62("10")

    [0, 1, 61, 62, 12_345, 999_999].each do |number|
      with_allocator(FakeAllocator.new(number..number)) do
        assert_equal number, ShortCodeGenerator.decode_base62(ShortCodeGenerator.call)
      end
      ShortCodeGenerator.reset!
    end
  end

  test "decode_base62 raises on characters outside the alphabet" do
    assert_raises(ArgumentError) { ShortCodeGenerator.decode_base62("!!!") }
  end
end
