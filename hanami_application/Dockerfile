FROM ruby:3-alpine

RUN apk update && apk add build-base git sqlite-dev postgresql-dev

WORKDIR /app

COPY Gemfile* ./

RUN gem install bundler:2.2.16 && bundle install --jobs 4 --retry 5

COPY . .
