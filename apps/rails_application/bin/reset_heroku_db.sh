#!/bin/sh

set -eu

heroku maintenance:on --app=res-ecommerce-rails
heroku ps:restart --app=res-ecommerce-rails
heroku pg:reset DATABASE --app=res-ecommerce-rails --confirm res-ecommerce-rails
heroku run --exit-code --no-tty --app=res-ecommerce-rails "cd apps/rails_application && bundle exec rake db:schema:load db:seed"
heroku ps:restart --app=res-ecommerce-rails
heroku maintenance:off --app=res-ecommerce-rails
