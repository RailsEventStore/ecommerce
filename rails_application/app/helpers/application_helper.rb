module ApplicationHelper
  def navigation_link(label, path)
    options =
      if current_page?(path)
        { class: "bg-gray-900 text-white px-3 py-2 rounded-md text-sm font-medium", "aria-current": "page" }
      else
        { class: "text-gray-300 hover:bg-gray-700 hover:text-white px-3 py-2 rounded-md text-sm font-medium" }
      end
    link_to label, path, options
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
end
