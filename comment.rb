require_relative 'trix_field'

class Comment
  attr_reader :session, :comment

  def initialize(session, comment)
    @session = session
    @comment = comment
  end

  def create
    session.find('.thread--comments .collapsed_content button').click
    TrixField.new(session, content).save('Add this comment')
  end

  def content
    content = comment.content.to_s
    content += '<br>'
    content += "Originally posted by #{comment.creator.name} on #{Time.parse(comment.created_at).strftime("%Y-%m-%d %H:%M")}"
  end
end
