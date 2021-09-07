#!/bin/sh

heroku restart --app=cqrs-es-sample-with-res
heroku pg:reset DATABASE --app=cqrs-es-sample-with-res --confirm cqrs-es-sample-with-res
heroku run rake db:migrate --app=cqrs-es-sample-with-res
heroku run rake db:seed --app=cqrs-es-sample-with-res
