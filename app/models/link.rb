# frozen_string_literal: true

class Link < ApplicationRecord
  DEFAULT_EXPIRATION = 2.years

  belongs_to :user

  validates :long_link, presence: true
  validates :short_link, presence: true, uniqueness: true

  scope :active, -> { where(active: true) }
  scope :not_expired, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :available, -> { active.not_expired }

  def self.generate_for(user:, long_link:)
    user.links.create!(
      long_link: long_link,
      short_link: ShortCodeGenerator.call,
      expires_at: DEFAULT_EXPIRATION.from_now
    )
  end
end
