To ensure maximum use of the time during the workshop, please set up the project before it.
We use Makefile to make the setup simple. However, if you run into a problem
during setup, please reach us so we can help you set it up before the workshop.

You have to have ruby installed. Version 3.2 or 3.1 would be OK.

1. Clone the project `git clone git@github.com:RailsEventStore/ecommerce.git`
2. `cd ecommerce`
3. Ensure you have `postgresql` and `redis` services configured, up and running;
   see Setup section in [rails_application/README.md](rails_application/README.md)
4. run `make install`
5. run `make dev` - the app should be up and running. Take a look around
6. run `make test` to make sure the tests are running. Tests will be important
part of the workshop
7. Take a look at `README.md`. It explains how the app is structured and the goal
of this repository

See you at the workshop 👋

