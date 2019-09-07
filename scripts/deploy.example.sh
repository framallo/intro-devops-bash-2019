#!/bin/bash
set -e

cd "$(dirname "$0")"
cd app
source .env.local
# this part updates our repository
rbenv rehash

git checkout "$APP_BRANCH"
git pull origin "$APP_BRANCH"
git reset --hard HEAD

# this other part boots our server
mkdir -p shared/pids shared/sockets shared/log

bundle install --without development test --deployment

bundle exec rake db:migrate assets:clean assets:precompile

[ -f shared/pids/puma.pid ] && [ -e /proc/"$(cat shared/pids/puma.pid)" ] && kill "$(cat shared/pids/puma.pid)"
bundle exec puma -C config/puma.rb -d -p "$RAILS_PORT"


echo "deployment completed"
