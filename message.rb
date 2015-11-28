require_relative 'trix_field'
require_relative 'comment'

class Message
  attr_reader :session, :message

  def initialize(session, message)
    @session = session
    @message = message
  end

  def create
    session.fill_in 'message_subject', with: message.subject
    TrixField.new(session, content).save('Post this message')

    return unless comments.any?

    comments.each do |comment|
      Comment.new(session, comment).create
    end
  end

  def content
    content = message.content.to_s
    content += '<br>'
    content += "Originally posted by #{message.creator.name} on #{Time.parse(message.created_at).strftime("%Y-%m-%d %H:%M")}"
  end

  def comments
    return [] unless message.comments

    @comments ||= message.comments.select(&:content).sort_by{|c| Time.parse(c.created_at)}
  end
end
