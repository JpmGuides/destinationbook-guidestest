#! /bin/bash

cd $(dirname $0)
bundle exec ruby svg_transform.rb stop
sleep 1
git pull origin svg_transform > /dev/null  2>/dev/null
bundle install > /dev/null  2>/dev/null
bundle exec ruby svg_transform.rb start
