require 'bundler'
Bundler.setup
require 'capybara'
require 'selenium-webdriver'
require 'bcx'
require 'byebug'

def add_comment(session, comment)
  session.find('.thread--comments .collapsed_content button').click
  encoded = URI.escape(comment, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  session.execute_script("document.querySelector('.trix_required_field').editor.insertHTML(decodeURIComponent(\"#{encoded}\"))")
  session.click_button "Add this comment"
end

def create_todo_list(todo_list_title, todo_list_items, basecamp_3_project_url)
  session = Capybara::Session.new(:custom_selenium)
  session.visit(basecamp_3_project_url)

  if session.has_link?('Make another list')
    session.click_link 'Make another list'
  else
    session.click_link 'Make the first list'
  end

  session.fill_in 'todolist_name', with: todo_list_title
  session.click_button 'Add this list'
  session.click_link todo_list_title
  todo_list_url = session.current_url

  todo_list_items.each do |todo|
    session.click_link 'Add a to-do' if session.has_link?('Add a to-do')
    session.fill_in 'todo_content', with: todo.content
    session.click_button 'Add this to-do'

    if todo.comments.any?
      session.click_link todo.content
      todo.comments.select(&:content).each do |comment|
        content = comment.content.to_s
        content += '<br>'
        content += "Originally posted by #{comment.creator.name} on #{Time.parse(comment.created_at).strftime("%Y-%m-%d %H:%M")}"

        add_comment(session, content)
      end

      session.visit(todo_list_url)
    end
  end
end

# How to get the profile name:
# 1. Run /Applications/Firefox.app/Contents/MacOS/firefox-bin -P
# 2. Click on rename
# 3. Copy the value
# 4. Close
default_firefox_profile_name, username, password, basecamp_3_project_url = ARGV.take(4)
urls = ARGV[4, ARGV.length]

Capybara.register_driver :custom_selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => default_firefox_profile_name)
end
Capybara.default_driver = :custom_selenium

urls.each do |url|
  account_id, project_id, todo_list_id = url.split('/').map(&:to_i).select {|i| i > 0}
  Bcx.configure do |config|
    config.account = account_id
    config.user_agent = 'Basecamp 2, to Basecamp 3 todo migrator'
  end

  usage = "ruby migrate_todo.rb firefox_profile_id basecamp_2_username basecamp_2_password basecamp_3_project_todos_url basecamp_2_todolist_urls"

  raise "Missing Firefox profile id. Usage: #{usage}" unless default_firefox_profile_name
  raise "Missing Basecamp 2 account. Usage: #{usage}" unless account_id
  raise "Missing Basecamp 2 username. Usage: #{usage}" unless username
  raise "Missing Basecamp 2 password. Usage: #{usage}" unless password
  raise "Missing Basecamp 2 project_id. Usage: #{usage}" unless project_id
  raise "Missing Basecamp 2 todo_list_id. Usage: #{usage}" unless todo_list_id
  raise "Missing Basecamp 3 project url. Usage: #{usage}" unless basecamp_3_project_url

  puts "Fetching data from Basecamp 2 for #{url}"
  client = Bcx::Client::HTTP.new(login: username, password: password)

  todos = client.projects(project_id).todolists(todo_list_id).todos!
  todo_list_title = todos.first.todolist.name
  todo_list_items = todos.sort_by(&:position).reject(&:completed).map do |todo|
    client.projects(project_id).todolists(todo_list_id).todos!(todo.id)
  end

  begin
    create_todo_list(todo_list_title, todo_list_items, basecamp_3_project_url)
  rescue Exception => e
    puts e.message
    byebug
  end

  puts "Finished importing #{url}"
end
puts 'Finished!'
