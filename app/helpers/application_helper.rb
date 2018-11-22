module ApplicationHelper
  def stream_browser_path(stream_name)
    "/res#streams/#{stream_name}"
  end

  def stream_browser_link(link_name, stream_name)
    link_to link_name, stream_browser_path(stream_name), data: { turbolinks: false }
  end

  def order_history_link(id)
    stream_browser_link("History", "Ordering::Order$#{id}")
  end
end
