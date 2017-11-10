#!/bin/sh
cd /var/www/html
lsof -ti:3000 | xargs kill
cd /var/www
rm -fr html
mkdir html
