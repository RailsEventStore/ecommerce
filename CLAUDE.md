# Code Style
- NEVER add comments to code unless explicitly requested
- NEVER add comments to tests unless explicitly requested
- Write self-documenting code instead of adding explanatory comments

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

# Other

- Even though the project is event-driven, it's never async. All calls are synchronous, so no need to think about concurrency.

# Mutant

- we use mutation testing here - we run it with make mutate
- only 100% is accepted, in rare cases we add methods to the ignore list
- if after refactoring the score drops, we need to fix it before merging
- Dont add to ignore list too easily, it's last attempt
- There's no good excuse for dropping 100% mutant score

# How to run tests

- make test to run all tests
- rails test test/integration/ to run integration tests

# Events

- whenever we access event.data, we should use event.fetch(:product_id) instead of event[:product_id]

# Git

- Don't mention Claude in the git commit messages.