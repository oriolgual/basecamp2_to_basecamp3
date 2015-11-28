require_relative 'common'
require_relative 'todos_import'

# How to get the profile name:
# 1. Run /Applications/Firefox.app/Contents/MacOS/firefox-bin -P
# 2. Click on rename
# 3. Copy the value
# 4. Close
default_firefox_profile_name, username, password, basecamp_3_project_url = ARGV.take(4)
urls = ARGV[4, ARGV.length]

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

  TodosImport.new(client, project_id, todo_list_id, basecamp_3_project_url).import

  puts "Finished importing #{url}"
end
puts 'Finished!'

# "https://basecamp.com/1877017/api/v1/projects/10637066/topics.json"
