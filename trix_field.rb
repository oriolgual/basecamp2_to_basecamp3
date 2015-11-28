class TrixField
  attr_reader :session, :content

  def initialize(session, content)
    @session = session
    @content = content
  end

  def save(button_text)
    session.execute_script("document.querySelector('trix-editor').editor.insertHTML(decodeURIComponent(\"#{encoded_content}\"))")
    session.click_button button_text
  end

  def encoded_content
    URI.escape(content, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end
end
