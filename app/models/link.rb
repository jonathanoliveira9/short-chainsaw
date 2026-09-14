# frozen_string_literal: true

class Link < ShardedRecord
  DEFAULT_EXPIRATION = 2.years

  belongs_to :user

  validates :long_link, presence: true
  validates :short_link, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :available, -> { active.not_expired }

  def self.generate_for(user:, long_link:)
    short_link = ShortCodeGenerator.call

    on_shard_for(short_link) do
      user.links.create!(
        long_link: long_link,
        short_link: short_link,
        expires_at: DEFAULT_EXPIRATION.from_now
      )
    end
  end

  # Every link's numeric ZooKeeper-issued ID (recovered from its short_link)
  # deterministically picks the shard it lives on, so a lookup by short_link
  # never has to fan out across shards.
  def self.on_shard_for(short_link, &block)
    ShardedRecord.connected_to(shard: shard_for(short_link), &block)
  end

  def self.shard_for(short_link)
    ShardedRecord::SHARDS[ShortCodeGenerator.decode_base62(short_link) % ShardedRecord::SHARDS.size]
  rescue ArgumentError
    raise ActiveRecord::RecordNotFound, "no link with short_link #{short_link.inspect}"
  end
end
