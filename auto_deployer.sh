#!/bin/bash

while true
do
  git pull
  jekyll build
  sudo rsync -r _site /var/www/html
  sleep 300
done
