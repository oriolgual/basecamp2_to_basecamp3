require_relative 'todo'

class TodoList
  attr_reader :title, :todos, :url, :todo_list_url

  def initialize(title, todos, url)
    @title = title
    @todos = todos
    @url = url
  end

  def create
    session.visit(url)
    if session.has_link?('To-dos')
      session.click_link 'To-dos'
    end

    if session.has_link?('Make another list')
      session.click_link 'Make another list'
    else
      session.click_link 'Make the first list'
    end

    unless session.has_link?(title)
      session.fill_in 'todolist_name', with: title
      session.click_button 'Add this list'
    end

    session.click_link title
    @todo_list_url = session.current_url

    todos.each do |todo|
      Todo.new(session, todo).create
      session.visit(@todo_list_url)
    end
  end

  def session
    @session ||= Capybara::Session.new(:custom_selenium)
  end
end
