require 'test_helper'
require 'fluent/plugin/out_hipchat'

class HipchatOutputTest < Test::Unit::TestCase
  class OutputTestDriver < Fluent::Test::InputTestDriver
    def initialize(klass, tag='test', &block)
      super(klass, &block)
      @tag = tag
    end

    attr_accessor :tag

    def emit(record, time=Time.now)
      es = Fluent::OneEventStream.new(time.to_i, record)
      @instance.emit(@tag, es, nil)
    end
  end

  def setup
    super
    Fluent::Test.setup
    # any_instance_of(HipChat::Client, :redis= => lambda {}, :redis => @subject)
  end

  CONFIG = %[
    type hipchat
    api_token testtoken
    default_room testroom
    default_from testuser
    default_color yellow
  ]

#    default_notify 1
#        default_format html

  def create_driver(conf = CONFIG)
    OutputTestDriver.new(Fluent::HipchatOutput) {
    }.configure(conf)
  end

  def test_default_message
    d = create_driver(<<-EOF)
                      type hipchat
                      api_token xxx
                      default_room testroom
                      EOF
    stub(d.instance.hipchat).rooms_message('testroom', 'fluentd', 'foo', 0, 'yellow', 'html')
    assert_equal d.instance.hipchat.instance_variable_get(:@token), 'xxx'
    d.emit({'message' => 'foo'})
    d.run
  end

  def test_message
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', 'testuser', 'foo', 0, 'red', 'html')
    assert_equal d.instance.hipchat.instance_variable_get(:@token), 'testtoken'
    d.emit({'message' => 'foo', 'color' => 'red'})
    d.run
  end

  def test_message_override
    d = create_driver
    stub(d.instance.hipchat).rooms_message('my', 'alice', 'aaa', 1, 'random', 'text')
    d.emit(
      {
        'room' => 'my',
        'from' => 'alice',
        'message' => 'aaa',
        'notify' => true,
        'color' => 'random',
        'format' => 'text',
      }
    )
    d.run
  end

  def test_color_validate
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', 'testuser', 'foo', 0, 'yellow', 'html')
    d.emit({'message' => 'foo', 'color' => 'invalid'})
    d.run
  end
end
