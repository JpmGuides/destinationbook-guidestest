#! /bin/bash

cd /var/www/local_guide
ruby script/listner.rb stop
sleep 1
git pull origin server
bundle install
touch tmp/restart.txt
ruby script/listner.rb start
