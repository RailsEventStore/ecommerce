# Rails application
# MyCommerce.md — E-commerce Backend Platform на Ruby on Rails

MyCommerce.md — это модульная и масштабируемая e-commerce платформа, построенная на Ruby on Rails с использованием архитектурных подходов CQRS и Event Sourcing.

Проект задуман как надёжная основа для построения интернет-магазинов и B2B решений с высокой гибкостью, расширяемостью и интеграцией с современными технологиями.

## Особенности

- Поддержка заказов, продуктов, доставок, клиентов и купонов
- Чистая архитектура: CQRS (Command Query Responsibility Segregation)
- Event Sourcing с использованием Rails Event Store
- Авторизация пользователей
- RSpec + тесты на бизнес-логику
- Кастомизированный интерфейс и бренд MyCommerce.md
- Добавлен логотип и навигация
- Инициализация данных через `db/seeds.rb`

## Установка и запуск

### Зависимости

- Ruby 3.3.7
- PostgreSQL
- Redis
- Node.js & Yarn (для frontend-части)

### Kickstart

- run `make install` to install dependencies, create db, setup schema and seed data
- run `make dev` to start the rails server and tailwindcss watcher

## Testing

- run `make test` to run unit and integration tests
- run `make mutate` to perform mutation coverage

The script is called `big_picture.rb`, and you can execute it like this:

```shell
bin/rails r script/big_picture.rb
```
