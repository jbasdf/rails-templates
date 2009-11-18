def file_append(file, data)
  log 'file_append', file
  append_file(file, data)
end

def file_inject(file_name, sentinel, string, before_after=:after)
  log 'file_inject', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match}\n#{string}"
    else
      "#{string}\n#{match}"
    end
  end
end

file_append 'config/environments/test.rb', test_rb

# /////////////////////////////////////////////
# Create test_helper.rb
#
file 'test/test_helper.rb', <<-CODE

$:.reject! { |e| e.include? 'TextMate' }
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
gem 'muck-engine'
require 'muck_test_helper'
require 'authlogic/test_case'

class ActiveSupport::TestCase
  include MuckTestMethods
  include Authlogic::TestCase
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  # For Selenium
  # setup do |session|
  #   session.host! "localhost:3001"
  # end

end
CODE

# /////////////////////////////////////////////
# Cucumber
#
run "script/generate cucumber"

file 'lib/tasks/cucumber.rake', <<-CODE
$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')
 
begin
  require 'cucumber/rake/task'
 
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "--format pretty"
  end
  task :features => 'db:test:prepare'
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
CODE

file 'features/support/env.rb', <<-CODE
# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
require 'cucumber/formatters/unicode' # Comment out this line if you don't want Cucumber Unicode support

require 'database_cleaner'
require 'database_cleaner/cucumber'
DatabaseCleaner.strategy = :truncation

Cucumber::Rails.use_transactional_fixtures

require 'webrat/rails'

# Comment out the next two lines if you're not using RSpec's matchers (should / should_not) in your steps.
require 'cucumber/rails/rspec'
require 'webrat/rspec-rails'

Webrat.configure do |config|
  config.mode = :rails
end

# Webrat.configure do |config|  
#   config.mode = :selenium  
#   config.application_environment = :test  
#   config.application_framework = :rails  
# end

# To enable selenium:
# 1. sudo gem install selenium-client
# 2. uncomment Webrat.configure that contains :selenium and then comment out the one that contains :rails above
# 3. set:  self.use_transactional_fixtures = false in test_helper.rb
# 4. uncomment in test_helper.rb:
      # setup do |session|
      #   session.host! "localhost:3001"
      # end
# 5. Be sure to apply the patch mentioned in the viget article below found here: http://gist.github.com/141590
      
# References:
# http://www.brynary.com/2009/4/6/switching-webrat-to-selenium-mode
# http://www.viget.com/extend/getting-started-with-webrat-selenium-rails-and-firefox-3/
CODE


file 'features/step_definitions/common_steps.rb', <<-CODE
def log_in_user(user, password)
  visit(login_url)
  fill_in("user_session_login", :with => user.login)
  fill_in("user_session_password", :with => password)
  click_button("Sign In")
end

def log_in_with_login_and_role(login, role)
  @user = Factory(:user, :login => login, :password => 'test')
  @user.add_to_role(role)
  log_in_user(@user, password)
end

Before do
  ActionMailer::Base.deliveries = []
end


# Assumes password is 'asdfasdf'
Given /I log in as "(.*)"/ do |login|
  password = "asdfasdf"
  @user = User.find_by_login(login)
  log_in_user(@user, password)
end

Given /I log in as new user "(.*)" with password "(.*)"/ do |login, password|
  @user = Factory(:user, :login => login, :password => password)
  log_in_user(@user, password)
end

Given /I log in as new user/ do
  password = 'asdfasdf'
  @user = Factory(:user, :password => password)
  log_in_user(@user, password)
end

Given /^I log in as "(.*)" with role "(.*)"$/ do |login, role|
  log_in_with_login_and_role(login, role)
end

Given /^I am not logged in$/ do
  post '/logout'
end

Then /^I should see the login$/ do
  response.body.should =~ /sign_in/m
  response.body.should =~ /user_session_login/m
  response.body.should =~ /user_session_password/m
end


#features/step_definitions/common_steps.rb
# On page/record
Given /^I am on "([^"]*)"$/ do |path|
  visit path
end

Then /^I should be on "([^"]*)"$/ do |path|
  current_path.should == path
end

Given /^I am on "([^"]*)" "([^"]*)"$/ do |model,number|
  visit polymorphic_path(record_from_strings(model,number))
end

Then /^I should be on "([^"]*)" "([^"]*)"$/ do |model,number|
   current_path.should == polymorphic_path(record_from_strings(model,number))
end

# Existing
Given /^a "([^"]*)" exists for "([^"]*)" "([^"]*)"$/ do |associated,model,number|
  record = record_from_strings(model,number)
  record.send(associated.underscore+'=',valid(associated))
  record.save!
end

# Support
def current_path
  response.request.request_uri
end

def record_from_strings(model,number)
  model.constantize.find(:first,:offset=>number.to_i-1)
end
CODE

file 'features/step_definitions/webrat_steps.rb', <<-CODE
# Commonly used webrat steps
# http://github.com/brynary/webrat

When /^I go to "(.+)"$/ do |page_name|
  visit page_name
end

When /^I press "(.*)"$/ do |button|
  click_button(button)
end

When /^I follow "(.*)"$/ do |link|
  click_link(link)
end

When /^I fill in "(.*)" with "(.*)"$/ do |field, value|
  fill_in(field, :with => value) 
end

When /^I select "(.*)" from "(.*)"$/ do |value, field|
  select(value, :from => field) 
end

# Use this step in conjunction with Rail's datetime_select helper. For example:
# When I select "December 25, 2008 10:00" as the date and time 
When /^I select "(.*)" as the date and time$/ do |time|
  select_datetime(time)
end

# Use this step when using multiple datetime_select helpers on a page or 
# you want to specify which datetime to select. Given the following view:
#   <%= f.label :preferred %><br />
#   <%= f.datetime_select :preferred %>
#   <%= f.label :alternative %><br />
#   <%= f.datetime_select :alternative %>
# The following steps would fill out the form:
# When I select "November 23, 2004 11:20" as the "Preferred" data and time
# And I select "November 25, 2004 10:30" as the "Alternative" data and time
When /^I select "(.*)" as the "(.*)" date and time$/ do |datetime, datetime_label|
  select_datetime(datetime, :from => datetime_label)
end

# Use this step in conjuction with Rail's time_select helper. For example:
# When I select "2:20PM" as the time
# Note: Rail's default time helper provides 24-hour time-- not 12 hour time. Webrat
# will convert the 2:20PM to 14:20 and then select it. 
When /^I select "(.*)" as the time$/ do |time|
  select_time(time)
end

# Use this step when using multiple time_select helpers on a page or you want to
# specify the name of the time on the form.  For example:
# When I select "7:30AM" as the "Gym" time
When /^I select "(.*)" as the "(.*)" time$/ do |time, time_label|
  select_time(time, :from => time_label)
end

# Use this step in conjuction with Rail's date_select helper.  For example:
# When I select "February 20, 1981" as the date
When /^I select "(.*)" as the date$/ do |date|
  select_date(date)
end

# Use this step when using multiple date_select helpers on one page or
# you want to specify the name of the date on the form. For example:
# When I select "April 26, 1982" as the "Date of Birth" date
When /^I select "(.*)" as the "(.*)" date$/ do |date, date_label|
  select_date(date, :from => date_label)
end

When /^I check "(.*)"$/ do |field|
  check(field) 
end

When /^I uncheck "(.*)"$/ do |field|
  uncheck(field) 
end

When /^I choose "(.*)"$/ do |field|
  choose(field)
end

When /^I attach the file at "(.*)" to "(.*)" $/ do |path, field|
  attach_file(field, path)
end

Then /^I should see "(.*)"$/ do |text|
  response.body.should =~ /\#{text}/m
end

Then /^I should not see "(.*)"$/ do |text|
  response.body.should_not =~ /\#{text}/m
end

Then /^the "(.*)" checkbox should be checked$/ do |label|
  field_labeled(label).should be_checked
end

Then /I should find '(.*)'/ do |text|
  response_body.should have_text(/\#{text}/m)
end

Then /I should see a "(.*)" flash message/ do |flash_type|
  response_body.should have_tag(".\#{flash_type}")
end

Then /dump response!/ do
  puts response_body
end
CODE