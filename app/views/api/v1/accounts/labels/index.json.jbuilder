json.payload do
  json.array! @labels do |label|
    json.id label.id
    json.title label.title
    json.description label.description
    json.color label.color
    json.show_on_sidebar label.show_on_sidebar
    json.position label.position
    json.hide_in_kanban label.hide_in_kanban
  end
end
