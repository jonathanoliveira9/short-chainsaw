# frozen_string_literal: true

class ShortCodeGenerator::RangeAllocator
  PARENT_PATH = "/short_chainsaw/short_code_ranges"
  SEQUENCE_PREFIX = "#{PARENT_PATH}/seq-"

  def initialize(hosts: ENV.fetch("ZOOKEEPER_HOSTS", "localhost:2181"), client: nil)
    @hosts = hosts
    @client = client
  end

  def next_range(block_size:)
    client.mkdir_p(PARENT_PATH)
    path = client.create(SEQUENCE_PREFIX, "", mode: :ephemeral_sequential)
    seq = path[/\d+\z/].to_i

    begin
      client.delete(path)
    rescue StandardError
      # Best-effort cleanup only: the node is ephemeral and ZK reclaims it
      # automatically once this session ends, so a failed delete here is harmless.
    end

    start = seq * block_size
    start..(start + block_size - 1)
  rescue StandardError => e
    ShortCodeGenerator::Errors.unavailable!(e.message)
  end

  private

  def client
    @client ||= ZK.new(@hosts)
  end
end
