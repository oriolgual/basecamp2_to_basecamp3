require_relative 'message'

class DiscussionsImport
  attr_reader :username, :password, :account_id, :project_id, :url

  def initialize(username, password, account_id, project_id, basecamp_3_url)
    @username = username
    @password = password
    @account_id = account_id
    @project_id = project_id
    @url = basecamp_3_url
  end

  def import
    puts 'Fetching messages'
    puts "Found #{topics.length} topics from #{messages.length} messages"

    session.visit(url)
    message_board_url = session.find('.card--message_board a')['href']
    session.visit(message_board_url)

    messages.each do |message|
      if session.has_link?('Post a message')
        session.click_link 'Post a message'
      else
        session.click_link 'Post the first message'
      end

      Message.new(session, message).create

      session.visit(message_board_url)
    end
  end

  private

  def session
    @session ||= Capybara::Session.new(:custom_selenium)
  end

  def messages
    @messages ||= message_ids.map do |id|
      url = "https://basecamp.com/#{account_id}/api/v1/projects/#{project_id}/messages/#{id}.json"
      api_request(url)
    end.flatten(1).sort_by{|m| Time.parse(m.created_at)}
  end

  def message_ids
    topics.select do |topic|
      topic.topicable.type == 'Message'
    end.map do |topic|
      topic.topicable.id
    end
  end

  def topics
    return @topics if defined?(@topics)
    url = "https://basecamp.com/#{account_id}/api/v1/projects/#{project_id}/topics.json"
    @topics = api_request(url)
  end

  def api_request(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(username, password)
    response = http.request(request)

    resources = JSON.parse(response.body)
    resources = [resources] unless resources.is_a?(Array)
    resources.map do |hash|
      Hashie::Mash.new hash
    end
  end
end
