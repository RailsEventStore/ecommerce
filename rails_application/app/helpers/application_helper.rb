module ApplicationHelper
  def navigation_link(label, path)
    current_link_to label, path,
      class: class_names(
        "px-3 py-2 rounded-md text-sm font-medium",
        "bg-gray-900 text-white" => current_page?(path),
        "text-gray-300 hover:bg-gray-700 hover:text-white" => !current_page?(path)
      )
  end

  def stream_browser_path(stream_name)
    "/res/streams/#{stream_name}"
  end

  def stream_browser_link(link_name, stream_name, options = {})
    link_to link_name, stream_browser_path(stream_name),
      options.merge(data: { turbolinks: false })
  end

  def order_history_link(id, options = {})
    stream_browser_link("History", "Orders$#{id}", options)
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
