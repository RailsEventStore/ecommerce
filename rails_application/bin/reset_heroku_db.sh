#!/bin/sh

heroku restart --app=res-ecommerce-rails
heroku pg:reset DATABASE --app=res-ecommerce-rails --confirm res-ecommerce-rails
heroku run rake db:migrate --app=res-ecommerce-rails
heroku run rake db:seed --app=res-ecommerce-rails
