#! /bin/bash

cd /var/www/local_guide
git pull origin server
touch tmp/restart.txt
killall rake
rake listner:start
