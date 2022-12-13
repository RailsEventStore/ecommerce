module ApplicationHelper
  def navigation_link(label, path)
    current_link_to label, path,
      class: class_names(
        "px-3 py-2 rounded-md text-sm font-medium",
        "bg-gray-900 text-white" => current_page?(path),
        "text-gray-300 hover:bg-gray-700 hover:text-white" => !current_page?(path)
      )
  end

  def action_button(css_classes, type: "button", form: nil)
    content_tag "span", class: "sm:ml-3" do
      content_tag "button", type: type, form: form, class: class_names(
        "inline-flex items-center px-4 py-2 border rounded-md shadow-sm text-sm font-medium",
        "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
        css_classes
      ) do
        yield
      end
    end
  end

  def primary_form_action_button(&block)
    action_button(
      "border-transparent text-white bg-blue-600 hover:bg-blue-700",
      type: "submit",
      form: "form",
      &block
    )
  end

  def primary_action_button(type: "button", &block)
    action_button(
      "border-transparent text-white bg-blue-600 hover:bg-blue-700",
      type: type,
      &block
    )
  end

  def secondary_action_button(type: "button", form: nil, &block)
    action_button(
      "border-gray-300 text-gray-700 bg-white hover:bg-gray-50",
      &block
    )
  end

  def primary_button_to(action, &block)
    content_tag("form", action: action, method: :post) do
      concat primary_action_button(type: "submit", &block)
      concat tag.input type: "hidden", authenticity_token: form_authenticity_token
    end
  end

  def stream_browser_path(stream_name)
    File.join(ruby_event_store_browser_app_path, "streams", stream_name)
  end

  def stream_browser_link(link_name, stream_name, options = {})
    link_to link_name, stream_browser_path(CGI.escape(stream_name)),
            options.merge(data: { turbo: false })
  end

  def order_history_link(id)
    stream_browser_link("History", "Ordering::Order$#{id}")
  end

  def current_link_to(label, path, **kwargs)
    link_to(label, path,
      **kwargs.merge(Hash(({ "aria-current": "page" } if current_page?(path))))
    )
  end

  def class_names(*unconditional_classes, **conditional_classes)
    [
      *unconditional_classes,
      *conditional_classes.filter_map { |k, v| k if v }
    ].join(" ")
  end
end
