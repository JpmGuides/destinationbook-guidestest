#! /bin/bash

cd /var/www/local_guide
git pull origin server
touch tmp/restart.txt
ruby lib/listner.rb stop
sleep 1
ruby lib/listner.rb start
