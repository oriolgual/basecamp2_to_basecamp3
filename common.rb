require 'bundler'
Bundler.setup
require 'capybara'
require 'selenium-webdriver'
require 'bcx'
require 'byebug'


default_firefox_profile_name, username, password, basecamp_3_project_url = ARGV.take(4)

Capybara.register_driver :custom_selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox, :profile => default_firefox_profile_name)
end
Capybara.default_driver = :custom_selenium
