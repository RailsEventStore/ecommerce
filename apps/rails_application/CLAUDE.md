# Code Style
- NEVER add comments to code unless explicitly requested
- NEVER add comments to tests unless explicitly requested
- Write self-documenting code instead of adding explanatory comments
- Dont use local variables, prefer method calls
- Dont use named params in method calls, unless required
- Dont add defensive checks if right params are passed, instead make sure with tests that the code is called correctly

# Process of working during refactoring

- Aim for smallest possible code transformations
- Make sure tests are always green (make test - runs both unit and integration tests)
- During refactoring it's crucial that integration tests are always working, don't make changes which fail them
- Always suggest tests first, we practice test-first TDD
- First run integration tests to ensure the behaviour hasnt changed and report that to me
- Then run unit tests and report coverage
- If coverage has dropped, add tests to restore it
- If coverage is 100% but mutant score has dropped, fix it before merging
- If 2 classes are merged then tests should be merged too

# Process managers

- Process managers are tested via asserting that specific commands are issued, when certain events input is given

# Read models 

- Testing read models should be done via calling event_store.publish(event)
- Use Arbre for implementing read models. Example is ClientInbox
- Each type of event should have separate event handler. This way we avoid if statements in handlers.
- Read model should have private_contant for ActiveRecord classes and expose facade methods
- In read model tests, we should not test against the ActiveRecord. Use the facade methods for that.
- Read models should not access other read models. 

# Other

- Even though the project is event-driven, it's never async. All calls are synchronous, so no need to think about concurrency.

# Mutant

- avoid running full "make mutate" when testing read models. Instead run it like this: RAILS_ENV=test bundle exec mutant run "Invoices*" - so with proper namespace. 
- only 100% is accepted, in rare cases we add methods to the ignore list
- if after refactoring the score drops, we need to fix it before merging
- Dont add to ignore list too easily, it's last attempt
- There's no good excuse for dropping 100% mutant score
- when you see some module (read model, process, bounded context, controller too) missing from mutation testing, suggest adding it
- in case you really need to run "make mutate" for the whole rails_application, then ask after 1 minute or so, if the mutant jobs should be killed. 

# Tests

- always use brackets in calls to assert_equal(foo, bar) or all other assertions (also assert(..))
- "make test" to run all tests
- rails test test/integration/ to run integration tests
- In integration tests, we simulate the user behaviour. 
- Dont use ActiveRecord in integration tests. 
- Also we avoid sending commands. But if there is no UI yet, then sending command is temporarily fine.
- In integration tests, we dont use event_store.
- If you discover sending commands in integration test, see if there maybe is a better way already.

# Events

- whenever we access event.data, we should use event.fetch(:product_id) instead of event[:product_id]

# Migrations

- we use uuid type for columns which store uuid

# Controllers

- when controller action is becoming non trivial, refactor to a service object
- when controller issues more than one command, remember about wrapping it in a transaction

# Commands

- when new commands appear, make sure if db/seeds reflect them now

# Git

Don't mention Claude in the git commit messages.
