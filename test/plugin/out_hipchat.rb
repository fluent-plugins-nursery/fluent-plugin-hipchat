require 'test_helper'
require 'fluent/plugin/out_hipchat'

class HipchatOutputTest < Test::Unit::TestCase
  include Fluent::Test::Helpers

  def setup
    super
    Fluent::Test.setup
  end

  CONFIG = %[
    type hipchat
    api_token testtoken
    default_room testroom
    default_from testuser
    default_color yellow
  ]

  CONFIG_FOR_PROXY = %[
    http_proxy_host localhost
    http_proxy_port 8080
    http_proxy_user user
    http_proxy_pass password
  ]

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Output.new(Fluent::Plugin::HipchatOutput) {
    }.configure(conf)
  end

  def test_configure_default
    d = create_driver %[
      type hipchat
      api_token testtoken
    ]
    assert_equal "yellow", d.instance.default_color
    assert_equal "fluentd", d.instance.default_from
    assert_equal 0, d.instance.default_notify
    assert_equal "html", d.instance.default_format
    assert_equal "message", d.instance.key_name
    assert_equal 1, d.instance.flush_interval
  end

  def test_format
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', 'testuser', 'foo', 0, 'red', 'html')
    assert_equal d.instance.hipchat.instance_variable_get(:@token), 'testtoken'
    time = event_time
    d.run(default_tag: "test") do
      d.feed(time, {'message' => 'foo', 'color' => 'red'})
    end
    assert_equal [time, {'message' => 'foo', 'color' => 'red'}].to_msgpack, d.formatted[0]
  end

  def test_default_message
    d = create_driver(<<-EOF)
                      type hipchat
                      api_token xxx
                      default_room testroom
                      EOF
    stub(d.instance.hipchat).rooms_message('testroom', 'fluentd', 'foo', 0, 'yellow', 'html')
    assert_equal d.instance.hipchat.instance_variable_get(:@token), 'xxx'
    d.run(default_tag: "test") do
      d.feed({'message' => 'foo'})
    end
  end

  def test_set_default_timeout
    d = create_driver(<<-EOF)
                      type hipchat
                      api_token xxx
                      default_timeout 5
                      EOF
    stub(d.instance.hipchat).set_timeout(5)
    d.run(default_tag: "test") do
      d.feed({'message' => 'foo'})
    end
  end

  def test_message
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', 'testuser', 'foo', 0, 'red', 'html')
    assert_equal d.instance.hipchat.instance_variable_get(:@token), 'testtoken'
    d.run(default_tag: "test") do
      d.feed({'message' => 'foo', 'color' => 'red'})
    end
  end

  def test_message_override
    d = create_driver
    stub(d.instance.hipchat).rooms_message('my', 'alice', 'aaa', 1, 'random', 'text')
    d.run(default_tag: "test") do
      d.feed(
        {
          'room' => 'my',
          'from' => 'alice',
          'message' => 'aaa',
          'notify' => true,
          'color' => 'random',
          'format' => 'text',
        }
      )
    end
  end

  def test_topic
    d = create_driver
    stub(d.instance.hipchat).rooms_topic('testroom', 'foo', 'testuser')
    d.run(default_tag: "test") do
      d.feed({'topic' => 'foo'})
    end
  end

  def test_set_topic_response_error
    d = create_driver
    stub(d.instance.hipchat).rooms_topic('testroom', 'foo', 'testuser') {
      {'error' => { 'code' => 400, 'type' => 'Bad Request', 'message' => 'Topic body must be between 1 and 250 characters.' } }
    }
    stub($log).error("HipChat Error:", error_class: StandardError, error: 'Topic body must be between 1 and 250 characters.')
    d.run(default_tag: "test") do
      d.feed({'topic' => 'foo'})
    end
  end

  def test_send_message_response_error
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', '<abc>', 'foo', 0, 'yellow', 'html') {
      {'error' => { 'code' => 400, 'type' => 'Bad Request', 'message' => 'From name may not contain HTML.' } }
    }
    stub($log).error("HipChat Error:", error_class: StandardError, error: 'From name may not contain HTML.')
    d.run(default_tag: "test") do
      d.feed({'from' => '<abc>', 'message' => 'foo'})
    end
  end

  def test_color_validate
    d = create_driver
    stub(d.instance.hipchat).rooms_message('testroom', 'testuser', 'foo', 0, 'yellow', 'html')
    d.run(default_tag: "test") do
      d.feed({'message' => 'foo', 'color' => 'invalid'})
    end
  end

  def test_http_proxy
    create_driver(CONFIG + CONFIG_FOR_PROXY)
    assert_equal 'localhost', HipChat::API.default_options[:http_proxyaddr]
    assert_equal '8080', HipChat::API.default_options[:http_proxyport]
    assert_equal 'user', HipChat::API.default_options[:http_proxyuser]
    assert_equal 'password', HipChat::API.default_options[:http_proxypass]
  end
end
