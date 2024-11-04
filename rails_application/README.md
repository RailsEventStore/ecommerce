# Rails application

[![Build Status](https://github.com/RailsEventStore/cqrs-es-sample-with-res/workflows/rails_application/badge.svg)](https://github.com/RailsEventStore/cqrs-es-sample-with-res/actions/workflows/rails_application.yml)

## Setup

### Postgresql

#### Docker

If you would like to use Docker image with PostgreSQL provided by us,
run `docker-compose up -d`. You're done for this step.

#### Installed in the system

If you have PostgreSQL installed directly in your system and prefer
to use it, create

- `.env.development.local`
  containing:

  ```
  DATABASE_URL=postgresql:///ecommerce_development
  ```

* `.env.test.local` containing:

  ```
  DATABASE_URL=postgresql:///ecommerce_test
  ```

It should would work for most of the cases. If you have more sophisticated setup,
you need to update `DATABASE_URL`.

### Kickstart

- run `make dev` to install dependencies, create db, setup schema and seed data
- run `bin/dev` to start the web server with Tailwind in "watch" mode

## Testing

- run `make test` to run unit and integration tests
- run `make mutate` to perform mutation coverage

## Big Picture

In event-driven architectures, navigation between events and handlers can be 
challenging, so we've created a script that generates two classes:

- `EventToHandlers`
- `HandlerToEvents`

They contain mappings between events and handlers, so it should help you with 
navigation during the development.

The script is called `big_picture.rb`, and you can execute it like this:

```shell
bin/rails r script/big_picture.rb
```