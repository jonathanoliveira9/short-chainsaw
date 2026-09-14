require "test_helper"

class LinkTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    ShortCodeGenerator.reset!
    @user = User.create!(email: "link-test-#{SecureRandom.hex(4)}@example.com", password: "password123")
  end

  teardown { ShortCodeGenerator.reset! }

  class FakeAllocator
    def initialize(range)
      @range = range
    end

    def next_range(block_size:)
      @range
    end
  end

  test "shard_for deterministically maps a decoded id to one of the three shards" do
    assert_equal :shard_one, Link.shard_for("0")
    assert_equal :shard_two, Link.shard_for("1")
    assert_equal :shard_three, Link.shard_for("2")
    assert_equal :shard_one, Link.shard_for("3")
  end

  test "shard_for raises RecordNotFound for a short_link that cannot be decoded" do
    assert_raises(ActiveRecord::RecordNotFound) { Link.shard_for("!!!") }
  end

  test "generate_for persists the link on the shard its id maps to" do
    ShortCodeGenerator.instance_variable_set(:@allocator, FakeAllocator.new(7..7))

    link = Link.generate_for(user: @user, long_link: "https://example.com")

    assert_equal :shard_two, Link.shard_for(link.short_link) # 7 % 3 == 1 -> SHARDS[1]

    found = Link.on_shard_for(link.short_link) { Link.find_by(short_link: link.short_link) }
    assert_equal link.id, found&.id
  end
end
