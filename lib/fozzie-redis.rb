require 'redis'

module FozzieRedis
  extend self

  INTERESTING_KEYS_REGEX = %w(used_memory mem_fragmentation_ratio total_connections_received total_commands_processed expired _keys keyspace ^db memory$ memory_rss$ memory_peak$ )

  # DEPRECATED
  SKIP_KEYS_REGEX = ['gcc_version', 'master_host', 'master_link_status',
    'master_port', 'mem_allocator', 'multiplexing_api', 'process_id',
    'redis_git_dirty', 'redis_git_sha1', 'redis_version', '^role',
    'run_id', '^slave', 'used_memory_human', 'used_memory_peak_human', 'cpu']

  def run
    bucket_prefix = ENV['REDIS_NAME']
    redis         = Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], password: ENV['REDIS_PASSWORD'])

    redis.info.each do |k, v|
      next unless INTERESTING_KEYS_REGEX.map { |re| k.match(/#{re}/)}.compact.any?

      if k =~ /^db/ # "db0"=>"keys=123,expires=12"
        keys, expires = v.split(',')
        keys.gsub!('keys=', '')
        expires.gsub!('expires=', '')

        gauge "#{bucket_prefix}.keys", keys
        gauge "#{bucket_prefix}.expires", expires
      else
        gauge "#{bucket_prefix}.#{k}", v
      end
    end
  end

  def gauge(key, value)
    puts "#{key} => #{value}"
  end
end
