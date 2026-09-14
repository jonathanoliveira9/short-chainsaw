# frozen_string_literal: true

# Abstract base for models split across the shard databases. `connects_to`
# can only be called on ActiveRecord::Base or an abstract class, so concrete
# sharded models (e.g. Link) inherit from this instead of ApplicationRecord.
class ShardedRecord < ApplicationRecord
  self.abstract_class = true

  SHARDS = %i[shard_one shard_two shard_three].freeze

  connects_to shards: SHARDS.index_with { |shard| { writing: shard } }
end
