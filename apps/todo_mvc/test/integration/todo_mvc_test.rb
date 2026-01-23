require_relative "../test_helper"

class TodoMvcTest < InMemoryRESIntegrationTestCase
  def test_full_todo_workflow
    get root_path
    assert_response :success

    post todos_path, params: { description: "Buy milk" }
    follow_redirect!
    assert_response :success
    assert_select "input[value='Buy milk']"
    assert_select "span", text: "1 item left"

    post todos_path, params: { description: "Buy bread" }
    follow_redirect!
    assert_response :success
    assert_select "span", text: "2 items left"

    todo_id = response.body.scan(/\/todos\/([a-f0-9-]+)\/complete/).first.first
    post "/todos/#{todo_id}/complete"
    follow_redirect!
    assert_select "span", text: "1 item left"

    get active_path
    assert_response :success

    get completed_path
    assert_response :success

    delete clear_completed_todos_path
    follow_redirect!
    assert_response :success
  end

  def test_add_todo
    post todos_path, params: { description: "Test todo" }
    follow_redirect!

    assert_response :success
    assert_select "input[value='Test todo']"
  end

  def test_shows_item_count
    post todos_path, params: { description: "Todo 1" }
    post todos_path, params: { description: "Todo 2" }

    get root_path
    assert_response :success
    assert_select "span", text: "2 items left"
  end

  def test_shows_clear_completed_button_when_todos_completed
    post todos_path, params: { description: "Test todo" }
    follow_redirect!

    assert_select "button", text: "Clear completed", count: 0

    todo_id = response.body.scan(/\/todos\/([a-f0-9-]+)\/complete/).first.first
    post "/todos/#{todo_id}/complete"
    follow_redirect!

    assert_select "button", text: "Clear completed"
  end

  def test_filter_links_work
    get root_path
    assert_response :success

    get active_path
    assert_response :success

    get completed_path
    assert_response :success
  end
end
