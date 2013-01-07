#! /bin/bash

cd /var/www/local_guide
ps -w | grep r[a]ke | cut -c-9 | xargs env kill
sleep 5
git pull origin server
touch tmp/restart.txt
rake listner:start
