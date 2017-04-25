# Fluent event to hipchat plugin.

[![Build Status](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-hipchat.svg?branch=master)](https://travis-ci.org/fluent-plugins-nursery/fluent-plugin-hipchat)

# Installation

    $ fluent-gem install fluent-plugin-hipchat

# Usage

    <match hipchat>
      type hipchat
      api_token XXX
      default_room my_room
      default_from fluentd
      default_color yellow
      default_notify 0
      default_format html
      default_timeout 3  # HipChat API Request Timeout Seconds (default 3)
      key_name message
      
      # proxy settings
      # http_proxy_host localhost
      # http_proxy_port 8080
      # http_proxy_user username
      # http_proxy_pass password
    </match>

    fluent_logger.post('hipchat', {
      :from     => 'alice',
      :message  => 'Hello<br>World!',
      :color    => 'red',
      :room     => 'my_room',
      :notify   => 1,
      :format   => 'text',
    })

    # set topic
    fluent_logger.post('hipchat', {
      :from     => 'alice',
      :topic    => 'new topic',
      :room     => 'my_room',
    })


# Copyright

Copyright (c) 2012- Yuichi Tateno

# License

Apache License, Version 2.0
