# frozen_string_literal: true

class ShortCodeGenerator
  ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".freeze
  BASE = ALPHABET.length
  BLOCK_SIZE = Integer(ENV.fetch("SHORT_CODE_BLOCK_SIZE", 1000))

  @mutex = Mutex.new

  class << self
    def call
      encode_base62(next_id)
    end

    def decode_base62(string)
      string.chars.reduce(0) do |number, char|
        digit = ALPHABET.index(char)
        raise ArgumentError, "invalid base62 character: #{char.inspect}" unless digit

        (number * BASE) + digit
      end
    end

    # Test-only: clears the memoized range/cursor/allocator so specs don't
    # leak state into each other within the same test process.
    def reset!
      @allocator = nil
      @cursor = nil
      @range_end = nil
    end

    private

    def next_id
      @mutex.synchronize do
        refill_range! if @range_end.nil? || @cursor > @range_end

        @cursor.tap { @cursor += 1 }
      end
    end

    def refill_range!
      range = allocator.next_range(block_size: BLOCK_SIZE)
      @cursor = range.begin
      @range_end = range.end
    end

    def allocator
      @allocator ||= RangeAllocator.new
    end

    def encode_base62(number)
      return ALPHABET[0] if number.zero?

      digits = []
      while number.positive?
        number, remainder = number.divmod(BASE)
        digits << ALPHABET[remainder]
      end
      digits.reverse.join
    end
  end
end
