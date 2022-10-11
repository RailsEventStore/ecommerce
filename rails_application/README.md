# Rails application

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/rails_application/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/rails_application.yml)

## Setup

### Postgresql

#### Docker

If you would like to use Docker image with PostgreSQL and Redis provided by us, run `docker-compose up -d`. Your done for this
step.

#### PostgreSQL installed in the system

If you have PostgreSQL installed directly in your system and prefer to use it, create

- `.env.development.local`
  containing:

  ```
  DATABASE_URL=postgresql:///cqrs-es-sample-with-res_development
  ```

* `.env.test.local` containing:

  ```
  DATABASE_URL=postgresql:///cqrs-es-sample-with-res_test
  ```

It should would work for most of the cases. If you have more sophisticated setup, you need to update `DATABASE_URL`
accordingly.

### Kickstart

- run `make dev` to install dependencies, create db, setup schema and seed data
- run `bin/dev` to start the web server with Tailwind in "watch" mode

## Testing

- run `make test` to run unit and integration tests
- run `make mutate` to perform mutation coverage
