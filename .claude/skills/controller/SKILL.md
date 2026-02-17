---
name: controller
description: Create a controller with commands, read model queries, routes, and integration tests
---

# Controller Builder

## When to use

Use this skill when asked to create a new controller or add actions to an existing controller in any Rails app under `apps/`.

## Working Directory

Determine which app the controller belongs to. Default is `apps/rails_application/` unless specified.

## Step-by-step process

### 1. Gather requirements

Before writing any code, clarify:
- Which **read model** the controller queries (must already exist)
- Which **domain commands** the controller dispatches (must already exist)
- What **actions** are needed (index, show, new, create, edit, update, destroy, custom)
- Whether it lives in a **namespace** (e.g. `admin/`, `client/`)

### 2. Write integration tests first (TDD)

Create a test file at `test/integration/{controller_name}_test.rb`.

```ruby
require "test_helper"

class ResourceNameTest < InMemoryRESIntegrationTestCase
  def test_list_resources
    get "/resources"
    assert_response :success
  end

  def test_create_resource
    post "/resources", params: { name: "Test" }
    follow_redirect!
    assert_select("td", "Test")
  end

  def test_update_resource
    resource_id = create_resource("Original")

    patch "/resources/#{resource_id}", params: { name: "Updated" }
    follow_redirect!
    assert_select("td", "Updated")
  end

  private

  def create_resource(name)
    post "/resources", params: { name: name }
    follow_redirect!
    # extract ID from page or use read model facade
    ReadModel.all.last.uid
  end
end
```

**Integration test conventions:**
- Inherit from `InMemoryRESIntegrationTestCase`
- Use HTTP verbs: `get`, `post`, `patch`, `delete`
- Use `follow_redirect!` after redirecting actions
- Assert with `assert_response`, `assert_select`
- Extract setup into private helper methods
- Never dispatch commands directly — always go through HTTP
- Never access AR models directly — use read model facade methods if needed

### 3. Add routes

Add to `config/routes.rb`:

```ruby
resources :resources, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
  member do
    post :custom_action
  end
  collection do
    delete :clear_all
  end
end
```

**Route conventions:**
- Use RESTful `resources` with `only:` to limit actions
- Custom actions go in `member do` (operates on one record) or `collection do` (operates on many)
- Namespace for grouped controllers:
  ```ruby
  namespace :admin do
    resources :stores, only: [:index, :new, :create]
  end
  ```

### 4. Create the controller

```ruby
class ResourcesController < ApplicationController
  def index
    @resources = ReadModel.all
  end

  def show
    @resource = ReadModel.find_by_uid(params[:id])
  end

  def new
    @resource_id = SecureRandom.uuid
  end

  def create
    ActiveRecord::Base.transaction do
      command_bus.call(Domain::CreateResource.new(
        resource_id: params[:resource_id],
        name: params[:name]
      ))
    end
    redirect_to resources_path, notice: "Resource was successfully created"
  end

  def edit
    @resource = ReadModel.find_by_uid(params[:id])
  end

  def update
    command_bus.call(Domain::UpdateResource.new(
      resource_id: params[:id],
      name: params[:name]
    ))
    redirect_to resource_path(params[:id]), notice: "Resource was successfully updated"
  end

  def destroy
    command_bus.call(Domain::RemoveResource.new(resource_id: params[:id]))
    redirect_to resources_path, notice: "Resource was successfully removed"
  end
end
```

### 5. Controller conventions

**Command dispatch:**
- Use `command_bus.call(Command.new(...))` to dispatch commands
- Wrap multiple commands in `ActiveRecord::Base.transaction do ... end`
- Generate UUIDs before dispatch: `id = SecureRandom.uuid`

**Read model queries:**
- Always use facade methods: `ReadModel.all`, `ReadModel.find_by_uid(id)`
- Never access ActiveRecord models directly

**Redirects:**
- After successful writes: `redirect_to path, notice: "..."`
- After errors: `redirect_to path, alert: "..."`

**Error handling:**
- Use `rescue`/`else` for domain exceptions:
  ```ruby
  def submit
    SomeService.new(params[:id]).call
  rescue Domain::SomeError => e
    redirect_to edit_path(params[:id]), alert: e.message
  else
    redirect_to show_path(params[:id]), notice: "Success"
  end
  ```

**Before actions:**
- Use for authorization, ownership checks, loading shared data:
  ```ruby
  before_action :load_resource, only: [:show, :edit, :update]

  private

  def load_resource
    @resource = ReadModel.find_by_uid(params[:id])
  end
  ```

### 6. Form objects (when validation is needed)

For non-trivial forms, create a form object in the controller file or a separate file:

```ruby
class ResourceForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :name, :string
  attribute :price, :decimal
  attribute :resource_id, :string

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
```

Use in the controller:

```ruby
def create
  form = ResourceForm.new(**resource_params)
  unless form.valid?
    return render "new", locals: { errors: form.errors }, status: :unprocessable_entity
  end

  ActiveRecord::Base.transaction do
    command_bus.call(Domain::CreateResource.new(resource_id: form.resource_id, name: form.name))
  end
  redirect_to resources_path, notice: "Created"
end
```

### 7. Service objects (when logic is complex)

When a controller action involves complex coordination (multiple commands, event subscriptions, error handling), extract to a service:

```ruby
# app/services/{namespace}/submit_service.rb
module Namespace
  class SubmitService
    def initialize(id)
      @id = id
    end

    def call
      ActiveRecord::Base.transaction do
        command_bus.call(Domain::Submit.new(id: @id))
      end
    end

    private

    def command_bus
      Rails.configuration.command_bus
    end
  end
end
```

### 8. Namespaced controllers

For controllers under a namespace (e.g. `admin/`, `client/`):

```ruby
# app/controllers/admin/resources_controller.rb
module Admin
  class ResourcesController < ApplicationController
    def index
      @resources = ReadModel.all
    end
  end
end
```

With a base controller for shared behavior:

```ruby
# app/controllers/client/base_controller.rb
module Client
  class BaseController < ApplicationController
    layout "client_panel"
    before_action :ensure_logged_in

    private

    def ensure_logged_in
      # auth check
    end
  end
end

# app/controllers/client/orders_controller.rb
module Client
  class OrdersController < BaseController
    def index
      @orders = ClientOrders.orders_for_client(current_client_id)
    end
  end
end
```

### 9. Create views

Create ERB views in `app/views/{controller_name}/`:
- `index.html.erb` — list view
- `show.html.erb` — detail view
- `new.html.erb` — form for creating
- `edit.html.erb` — form for editing

Views query data via instance variables set in controller (`@resources`, `@resource`).

### 10. Run verification

1. `rails test test/integration/{test_file}.rb` — integration tests pass
2. `make test` — all tests green

## Key conventions

- Controllers are thin — dispatch commands and query read models
- Complex logic goes into service objects
- Multiple commands wrapped in transactions
- UUIDs generated in controller before command dispatch
- Read model facade methods for all queries
- Integration tests exercise the full HTTP stack
- Test-first TDD
