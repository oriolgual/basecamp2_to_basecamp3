require_relative 'comment'

class Todo
  attr_reader :session, :todo
  def initialize(session, todo)
    @session = session
    @todo = todo
  end

  def create
    session.click_link 'Add a to-do' if session.has_link?('Add a to-do')
    session.fill_in 'todo_content', with: todo.content
    session.click_button 'Add this to-do'

    return unless comments.any?
    session.click_link todo.content

    comments.each do |comment|
      Comment.new(session, comment).create
    end
  end

  def comments
    return [] unless todo.comments

    @comments ||= todo.comments.select(&:content)
  end
end
