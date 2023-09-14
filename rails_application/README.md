# Rails application

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/rails_application/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/rails_application.yml)

## Setup

### Postgresql and Redis

#### Docker

If you would like to use Docker image with PostgreSQL and Redis provided by us,
run `docker-compose up -d`. You're done for this step.

#### Installed in the system

If you have PostgreSQL or Redis installed directly in your system and prefer
to use them, create

- `.env.development.local`
  containing:

  ```
  DATABASE_URL=postgresql:///ecommerce_development
  REDIS_URL=redis://localhost:6379/1
  ```

* `.env.test.local` containing:

  ```
  DATABASE_URL=postgresql:///ecommerce_test
  REDIS_URL=redis://localhost:6379/1
  ```

It should would work for most of the cases. If you have more sophisticated setup,
you need to update `DATABASE_URL` and `REDIS_URL` accordingly.

### Kickstart

- run `make dev` to install dependencies, create db, setup schema and seed data
- run `bin/dev` to start the web server with Tailwind in "watch" mode

## Testing

- run `make test` to run unit and integration tests
- run `make mutate` to perform mutation coverage
