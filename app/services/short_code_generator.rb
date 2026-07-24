# frozen_string_literal: true

class ShortCodeGenerator
  def self.call
    raise NotImplementedError, "short_link generation will be provided via Zookeeper"
  end
end
