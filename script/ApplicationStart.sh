#!/bin/sh
cd /var/www/html
source /usr/local/rvm/scripts/rvm
RAILS_ENV=development bundle exec rails server > /dev/null 2> /dev/null < /dev/null &
