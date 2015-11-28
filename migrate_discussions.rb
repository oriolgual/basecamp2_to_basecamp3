require "net/https"
require "uri"
require_relative 'common'
require_relative 'discussions_import'

# How to get the profile name:
# 1. Run /Applications/Firefox.app/Contents/MacOS/firefox-bin -P
# 2. Click on rename
# 3. Copy the value
# 4. Close
default_firefox_profile_name, username, password, basecamp_3_project_url, basecamp_2_project_url = ARGV.take(5)

account_id, project_id = basecamp_2_project_url.split('/').map(&:to_i).select {|i| i > 0}

usage = "ruby migrate_discussions.rb firefox_profile_id basecamp_2_username basecamp_2_password basecamp_3_project_url basecamp_2_project_url"

raise "Missing Firefox profile id. Usage: #{usage}" unless default_firefox_profile_name
raise "Missing Basecamp 2 account. Usage: #{usage}" unless account_id
raise "Missing Basecamp 2 username. Usage: #{usage}" unless username
raise "Missing Basecamp 2 password. Usage: #{usage}" unless password
raise "Missing Basecamp 2 project_id. Usage: #{usage}" unless project_id
raise "Missing Basecamp 3 project url. Usage: #{usage}" unless basecamp_3_project_url

DiscussionsImport.new(username, password, account_id, project_id, basecamp_3_project_url).import
puts 'Finished!'
