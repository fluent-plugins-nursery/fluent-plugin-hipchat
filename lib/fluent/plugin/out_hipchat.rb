
module Fluent
  class HipchatOutput < Output
    COLORS = %w(yellow green purple random)
    Fluent::Plugin.register_output('hipchat', self)

    config_param :api_token, :string
    config_param :default_room, :string, :default => nil
    config_param :default_color, :string, :default => nil
    config_param :default_from, :string, :default => nil

    attr_reader :hipchat

    def initialize
      super
      require 'hipchat-api'
    end

    def configure(conf)
      super

      @hipchat = HipChat::API.new(conf['api_token'])
      @default_from = conf['default_from'] || 'fluentd'
      @default_room = conf['default_room']
      @default_color = conf['default_color'] || 'yellow'
    end

    def emit(tag, es, chain)
      es.each {|time, record|
        begin
          send_message(record)
        rescue => e
          $log.error("HipChat Error: #{e} / #{e.message}")
        end
      }
    end

    def send_message(record)
      room = record['room'] || @default_room
      from = record['from'] || @default_from
      message = record['message'] || ''
      notify = record['notify'] ? 1 : 0
      color = COLORS.include?(record['color']) ? record['color'] : @default_color
      @hipchat.rooms_message(room, from, message, notify, color)
    end
  end
end
