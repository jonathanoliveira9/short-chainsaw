# frozen_string_literal: true

class ShortCodeGenerator::Errors
  def self.unavailable!(reason)
    raise ShortCodeGenerator::UnavailableError, "could not allocate a short-code ID range: #{reason}"
  end
end
