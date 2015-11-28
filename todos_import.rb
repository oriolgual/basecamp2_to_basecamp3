require_relative 'todo_list'

class TodosImport
  attr_reader :client, :project_id, :todo_list_id, :basecamp_3_project_url

  def initialize(client, project_id, todo_list_id, basecamp_3_project_url)
    @client = client
    @project_id = project_id
    @todo_list_id = todo_list_id
    @basecamp_3_project_url = basecamp_3_project_url
  end

  def import
    TodoList.new(todo_list_title, todo_list_items, basecamp_3_project_url).create
  end

  def todos
    @todos ||= client.projects(project_id).todolists(todo_list_id).todos!
  end

  def todo_list_title
    todos.first.todolist.name
  end

  def todo_list_items
    @items ||= todos.sort_by(&:position).reject(&:completed).map do |todo|
      client.projects(project_id).todolists(todo_list_id).todos!(todo.id)
    end
  end
end
