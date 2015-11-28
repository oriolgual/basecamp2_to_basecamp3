require 'bundler'
Bundler.setup
require 'capybara'
require 'selenium-webdriver'
require 'bcx'
require 'byebug'

def add_comment(session, comment)
  session.find('.thread--comments .collapsed_content button').click
  session.execute_script("$('#comment_content_trix_input_comment').val('#{comment}')")
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
      todo.comments.each do |comment|
        content = comment.content
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
default_firefox_profile_name = ARGV[0]

Capybara.register_driver :custom_selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => default_firefox_profile_name)
end
Capybara.default_driver = :custom_selenium

account_id = ARGV[1]
Bcx.configure do |config|
  config.account = account_id
  config.user_agent = 'Basecamp 2, to Basecamp 3 todo migrator'
end

username = ARGV[2]
password = ARGV[3]
project_id = ARGV[4]
todo_list_id = ARGV[5]
basecamp_3_project_url = ARGV[6]
usage = "ruby migrate_todo.rb firefox_profile_id account_id basecamp_2_username basecamp_2_password basecamp_2_project_id basecamp_2_todo_list_id basecamp_3_project_url"

raise "Missing Firefox profile id. Usage: #{usage}" unless default_firefox_profile_name
raise "Missing Basecamp 2 account. Usage: #{usage}" unless account_id
raise "Missing Basecamp 2 username. Usage: #{usage}" unless username
raise "Missing Basecamp 2 password. Usage: #{usage}" unless password
raise "Missing Basecamp 2 project_id. Usage: #{usage}" unless project_id
raise "Missing Basecamp 2 todo_list_id. Usage: #{usage}" unless todo_list_id
raise "Missing Basecamp 3 project url. Usage: #{usage}" unless basecamp_3_project_url

puts "Fetching data from Basecamp 2"
client = Bcx::Client::HTTP.new(login: username, password: password)

todos = client.projects(project_id).todolists(todo_list_id).todos!
todo_list_title = todos.first.todolist.name
todo_list_items = todos.sort_by(&:position).map do |todo|
  client.projects(project_id).todolists(todo_list_id).todos!(todo.id)
end

create_todo_list(todo_list_title, todo_list_items, basecamp_3_project_url)

puts 'Finished!'
