module ApplicationHelper
  STATE_COLORS = {
    "submitted" => "bg-slate-100 text-slate-700",
    "risk evaluated" => "bg-amber-100 text-amber-800",
    "priced" => "bg-sky-100 text-sky-800",
    "accepted" => "bg-emerald-100 text-emerald-800",
    "issued" => "bg-sky-100 text-sky-800",
    "in force" => "bg-emerald-100 text-emerald-800",
    "terminated" => "bg-rose-100 text-rose-700",
    "reported" => "bg-amber-100 text-amber-800",
    "assessed" => "bg-sky-100 text-sky-800",
    "settled" => "bg-emerald-100 text-emerald-800"
  }.freeze

  def nav_link(label, path)
    active = current_page?(path)
    link_to label, path,
            class: "px-3 py-2 rounded-md text-sm font-medium #{active ? "bg-slate-700 text-white" : "text-slate-300 hover:bg-slate-800 hover:text-white"}"
  end

  def state_badge(state)
    tag.span(state, class: "inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium #{STATE_COLORS.fetch(state, "bg-slate-100 text-slate-700")}")
  end

  def short_uuid(uuid)
    tag.span(uuid.first(8), class: "font-mono text-xs text-slate-500", title: uuid)
  end
end
