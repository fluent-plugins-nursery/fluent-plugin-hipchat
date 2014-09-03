
module Fluent
  class HipchatOutput < BufferedOutput
    COLORS = %w(yellow red green purple gray random)
    FORMAT = %w(html text)
    Fluent::Plugin.register_output('hipchat', self)

    config_param :api_token, :string
    config_param :default_room, :string, :default => nil
    config_param :default_color, :string, :default => nil
    config_param :default_from, :string, :default => nil
    config_param :default_notify, :bool, :default => nil
    config_param :default_format, :string, :default => nil
    config_param :key_name, :string, :default => 'message'
    config_param :default_timeout, :time, :default => nil
    config_param :http_proxy_host, :string, :default => nil
    config_param :http_proxy_port, :integer, :default => nil
    config_param :http_proxy_user, :string, :default => nil
    config_param :http_proxy_pass, :string, :default => nil
    config_param :flush_interval, :time, :default => 1
    config_param :mention_to, :string, :default => nil

    attr_reader :hipchat

    def initialize
      super
      require 'hipchat-api'
    end

    def configure(conf)
      super

      @hipchat = HipChat::API.new(conf['api_token'])
      @default_room = conf['default_room']
      @default_from = conf['default_from'] || 'fluentd'
      @default_notify = conf['default_notify'] || 0
      @default_color = conf['default_color'] || 'yellow'
      @default_format = conf['default_format'] || 'html'
      @default_timeout = conf['default_timeout']
      @mention_to = conf['mention_to']
      if conf['http_proxy_host']
        HipChat::API.http_proxy(
          conf['http_proxy_host'],
          conf['http_proxy_port'],
          conf['http_proxy_user'],
          conf['http_proxy_pass'])
      end
    end

    def format(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each do |(tag,time,record)|
        begin
          send_message(record) if record[@key_name]
          set_topic(record) if record['topic']
        rescue => e
          $log.error("HipChat Error:", :error_class => e.class, :error => e.message)
        end
      end
    end

    def send_message(record)
      room = record['room'] || @default_room
      from = record['from'] || @default_from
      message = record[@key_name]
      message = @mention_to + ' ' + message unless @mention_to.nil?
      if record['notify'].nil?
        notify = @default_notify
      else
        notify = record['notify'] ? 1 : 0
      end
      color = COLORS.include?(record['color']) ? record['color'] : @default_color
      message_format = FORMAT.include?(record['format']) ? record['format'] : @default_format
      @hipchat.set_timeout(@default_timeout.to_i) unless @default_timeout.nil?
      response = @hipchat.rooms_message(room, from, message, notify, color, message_format)
      raise StandardError, response['error'][@key_name].to_s if defined?(response['error'][@key_name])
    end

    def set_topic(record)
      room = record['room'] || @default_room
      from = record['from'] || @default_from
      topic = record['topic']
      response = @hipchat.rooms_topic(room, topic, from)
      raise StandardError, response['error'][@key_name].to_s if defined?(response['error'][@key_name])
    end
  end
end
