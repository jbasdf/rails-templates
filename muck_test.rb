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


# /////////////////////////////////////////////
# Modify test.rb to include testing gems
#
test_rb = <<-CODE
config.gem 'mocha', :version => '>= 0.9.5'
config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
# config.gem 'rspec', :version => '>=1.1.12', :lib => 'spec'
# config.gem 'rspec-rails', :version => '>=1.1.12', :lib => 'spec/rails'
config.gem 'treetop', :version => '>=1.2.4'
config.gem 'term-ansicolor', :version => '>=1.0.3', :lib => 'term/ansicolor'
config.gem 'cucumber', :version => '>=0.1.13', :lib => 'cucumber'
config.gem 'polyglot', :version => '>=0.2.4'
config.gem "rcov", :version => '>=0.8.1.2.0'
config.gem "webrat", :version => '>=0.4.4'

# only required if you want to use selenium for testing
#config.gem 'selenium-client', :lib => 'selenium/client'
#config.gem 'bmabey-database_cleaner', :lib => 'database_cleaner', :source => 'http://gems.github.com'

require 'factory_girl'
require 'mocha'
begin require 'redgreen'; rescue LoadError; end
CODE

file_append 'config/environments/test.rb', test_rb

# /////////////////////////////////////////////
# Create test_helper.rb
#
file 'test/test_helper.rb', <<-CODE
$:.reject! { |e| e.include? 'TextMate' }
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require 'ruby-debug'
gem 'thoughtbot-factory_girl' # from github
require 'factory_girl'
require 'mocha'
require 'authlogic/test_case'
require 'redgreen' rescue LoadError
require File.expand_path(File.dirname(__FILE__) + '/factories')
require File.join(File.dirname(__FILE__), 'shoulda_macros', 'controller')
require File.join(File.dirname(__FILE__), 'shoulda_macros', 'models')

class ActiveSupport::TestCase 
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  include Authlogic::TestCase
  
  def login_as(user)
    success = UserSession.create(user)
    if !success
      errors = user.errors.full_messages.to_sentence
      message = 'User has not been activated' if !user.active?
      raise "could not login as \#{user.to_param}.  Please make sure the user is valid. \#{message} \#{errors}"
    end
    UserSession.find
  end
  
  def assure_logout
    user_session = UserSession.find
    user_session.destroy if user_session
  end
  
  def ensure_flash(val)
    assert_contains flash.values, val, ", Flash: \#{flash.inspect}"
  end
  
  # For Selenium
  # setup do |session|
  #   session.host! "localhost:3001"
  # end
    
end

# turn off solr for tests
class ActsAsSolr::Post
  def self.execute(request)
    true
  end
end
CODE

# /////////////////////////////////////////////
# Create shoulda macros
#
file 'test/shoulda_macros/plugins.rb', <<-CODE
module ShouldaPluginMacros

  def self.should_act_as_taggable_on_steroids
    klass = self.name.gsub(/Test$/, '').constantize

    should "include ActsAsTaggableOnSteroids methods" do
      assert klass.extended_by.include?(ActiveRecord::Acts::Taggable::ClassMethods)
      assert klass.extended_by.include?(ActiveRecord::Acts::Taggable::SingletonMethods)
      assert klass.include?(ActiveRecord::Acts::Taggable::InstanceMethods)
    end

    should_have_many :taggings, :tags
  end


  def self.should_act_as_list
    klass = self.name.gsub(/Test$/, '').constantize

    context "To support acts_as_list" do
      should_have_db_column('position', :type => :integer)
    end

    should "include ActsAsList methods" do
      assert klass.include?(ActiveRecord::Acts::List::InstanceMethods)
    end

    should_have_instance_methods :acts_as_list_class, :position_column, :scope_condition
  end

end

ActiveSupport::TestCase.extend(ShouldaPluginMacros)
Test::Unit::TestCase.extend(ShouldaPluginMacros)
ActionController::TestCase.extend(ShouldaPluginMacros)
CODE

file 'test/shoulda_macros/pagination.rb', <<-CODE
module ShouldaPaginationMacros
  # Example:
  #  context "a GET to index logged in as admin" do
  #    setup do
  #      login_as_admin 
  #      get :index
  #    end
  #    should_paginate_collection :users
  #    should_display_pagination
  #  end
  def self.should_paginate_collection(collection_name)
    should "paginate \#{collection_name}" do
      assert collection = assigns(collection_name), 
        "Controller isn't assigning to @\#{collection_name.to_s}."
      assert_kind_of WillPaginate::Collection, collection, 
        "@\#{collection_name.to_s} isn't a WillPaginate collection."
    end
  end
  
  def self.should_display_pagination
    should "display pagination" do
      assert_select "div.pagination", { :minimum => 1 }, 
        "View isn't displaying pagination. Add <%= will_paginate @collection %>."
    end
  end
  
  # Example:
  #  context "a GET to index not logged in as admin" do
  #    setup { get :index }
  #    should_not_paginate_collection :users
  #    should_not_display_pagination
  #  end
  def self.should_not_paginate_collection(collection_name)
    should "not paginate \#{collection_name}" do
      assert collection = assigns(collection_name), 
        "Controller isn't assigning to @\#{collection_name.to_s}."
      assert_not_equal WillPaginate::Collection, collection.class, 
        "@\#{collection_name.to_s} is a WillPaginate collection."
    end
  end
  
  def self.should_not_display_pagination
    should "not display pagination" do
      assert_select "div.pagination", { :count => 0 }, 
        "View is displaying pagination. Check your logic."
    end
  end
end


class ActiveSupport::TestCase
  extend ShouldaPaginationMacros
end
CODE

file 'test/shoulda_macros/models.rb', <<-CODE
module ShouldaModelMacros

  def should_sanitize(*attributes)
    bad_scripts = [
      %|';alert(String.fromCharCode(88,83,83))//\';alert(String.fromCharCode(88,83,83))//";alert(String.fromCharCode(88,83,83))//\";alert(String.fromCharCode(88,83,83))//--></SCRIPT>">'><SCRIPT>alert(String.fromCharCode(88,83,83))</SCRIPT>|,
      %|'';!--"<XSS>=&{()}|,
      %|<SCRIPT SRC=http://ha.ckers.org/xss.js></SCRIPT>|,
      %|<IMG SRC="javascript:alert('XSS');">|,
      %|<IMG SRC=javascript:alert('XSS')>|,
      %|<IMG SRC=JaVaScRiPt:alert('XSS')>|,
      %|<IMG SRC=JaVaScRiPt:alert('XSS')>|,
      %|<IMG SRC=`javascript:alert("RSnake says, 'XSS'")`>|,
      %|<IMG """><SCRIPT>alert("XSS")</SCRIPT>">|,
      %|<IMG SRC=javascript:alert(String.fromCharCode(88,83,83))>|,
      %|<A HREF="h
      tt	p://6&#9;6.000146.0x7.147/">XSS</A>|,
      %|<script>alert('message');</script>| ]
      
    klass = model_class
    attributes.each do |attribute|
      attribute = attribute.to_sym
      should "white list \#{attribute}" do
        assert object = klass.find(:first), "Can't find first \#{klass}"
        bad_scripts.each do |bad_value|
          object.send("\#{attribute}=", bad_value)
          object.save
          clean_value = object.send("\#{attribute}")
          assert !clean_value.include?(bad_value), "\#{attribute} is not white listed. \#{bad_value} made it through"
        end
      end
    end
  end

  def should_accept_nested_attributes_for(*attr_names)
    klass = self.name.gsub(/Test$/, '').constantize
 
    context "\#{klass}" do
      attr_names.each do |association_name|
        should "accept nested attrs for \#{association_name}" do
          assert  klass.instance_methods.include?("\#{association_name}_attributes="),
                  "\#{klass} does not accept nested attributes for \#{association_name}"
        end
      end
    end
  end
end

class ActiveSupport::TestCase
  extend ShouldaModelMacros
end
CODE

file 'test/shoulda_macros/forms.rb', <<-CODE
module ShouldaFormMacros
  def self.should_have_form(opts)
    model = self.name.gsub(/ControllerTest$/, '').singularize.downcase
    model = model[model.rindex('::')+2..model.size] if model.include?('::')
    http_method, hidden_http_method = form_http_method opts[:method]
    should "have a \#{model} form" do
      assert_select "form[action=?][method=\#{http_method}]", eval(opts[:action]) do
        if hidden_http_method
          assert_select "input[type=hidden][name=_method][value=\#{hidden_http_method}]"
        end
        opts[:fields].each do |attribute, type|
          attribute = attribute.is_a?(Symbol) ? "\#{model}[\#{attribute.to_s}]" : attribute
          assert_select "input[type=\#{type.to_s}][name=?]", attribute
        end
        assert_select "input[type=submit]"
      end
    end
  end

  def self.form_http_method(http_method)
    http_method = http_method.nil? ? 'post' : http_method.to_s
    if http_method == "post" || http_method == "get"
      return http_method, nil
    else
      return "post", http_method
    end
  end  
end

class ActiveSupport::TestCase
  extend ShouldaFormMacros
end
CODE

file 'test/shoulda_macros/controller.rb', <<-CODE
module MuckControllerMacros

  def should_require_login(*args)
    args = Hash[*args]
    login_url = args.delete :login_url
    args.each do |action, verb|
      should "Require login for '\#{action}' action" do
        if [:put, :delete].include?(verb) # put and delete require an id even if it is a bogus one
          send(verb, action, :id => 1)
        else
          send(verb, action)
        end
        assert_redirected_to(login_url)
      end
    end
  end

  def should_require_role(role, redirect_url, *actions)
    actions.each do |action|
      should "require role for '\#{action}' action" do
        get(action)
        ensure_flash(/permission/i)
        assert_response :redirect
      end
    end
  end
  
  #from: http://blog.internautdesign.com/2008/9/11/more-on-custom-shoulda-macros-scoping-of-instance-variables
  def should_not_allow action, object, url= "/login", msg=nil
    msg ||= "a \#{object.class.to_s.downcase}" 
    should "not be able to \#{action} \#{msg}" do
      object = eval(object, self.send(:binding), __FILE__, __LINE__)
      get action, :id => object.id
      assert_redirected_to url
    end
  end

  def should_allow action, object, msg=nil
    msg ||= "a \#{object.class.to_s.downcase}" 
    should "be able to \#{action} \#{msg}" do
      object = eval(object, self.send(:binding), __FILE__, __LINE__)
      get action, :id => object.id
      assert_response :success
    end
  end

end

ActionController::TestCase.extend(MuckControllerMacros)
CODE


# /////////////////////////////////////////////
# Test Definitions
#
file 'test/test_definitions.rb',
%q{module TestDefinitions
  NOT_LOGGED_IN_MSG = /You must be logged in to access this feature/i
  PERMISSION_DENIED_MSG = /You don't have permission to do that/i
end
}

# /////////////////////////////////////////////
# Create factories
#
file 'test/factories.rb', <<-CODE
Factory.sequence :email do |n|
  "somebody\#{n}@example.com"
end

Factory.sequence :login do |n|
  "inquire\#{n}"
end

Factory.sequence :name do |n|
  "a_name\#{n}"
end

Factory.sequence :abbr do |n|
  "abbr\#{n}"
end

Factory.sequence :description do |n|
  "This is the description: \#{n}"
end

Factory.sequence :uri do |n|
  "n\#{n}.example.com"
end

Factory.define :state do |f|
  f.name { Factory.next(:name) }
  f.abbreviation { Factory.next(:abbr) }
  f.country {|a| a.association(:country) }
end

Factory.define :country do |f|
  f.name { Factory.next(:name) }
  f.abbreviation { Factory.next(:abbr) }
end

Factory.define :user do |f|
  f.login { Factory.next(:login) }
  f.email { Factory.next(:email) }
  f.password 'inquire_pass'
  f.password_confirmation 'inquire_pass'
  f.first_name 'test'
  f.last_name 'guy'
  f.terms_of_service true
  f.activated_at DateTime.now
end

Factory.define :content_page do |f|
  f.creator {|a| a.association(:user)}
  f.title { Factory.next(:name) }
  f.body_raw { Factory.next(:description) }
end

Factory.define :permission do |f|
  f.role {|a| a.association(:role)}
  f.user {|a| a.association(:user)}
end

Factory.define :role do |f|
  f.rolename 'administrator'
end

Factory.define :comment do |f|
  f.body { Factory.next(:name) }
  f.user {|a| a.association(:user)}
end

Factory.define :domain_theme do |f|
  f.name { Factory.next(:name) }
  f.uri { Factory.next(:uri) }
end

Factory.define :theme do |f|
  f.name { Factory.next(:name) }
end

Factory.define :feed do |f|
  f.contributor { |a| a.association(:user) }
  f.uri { Factory.next(:uri) }
  f.display_uri { Factory.next(:uri) }
  f.title { Factory.next(:title) }
  f.short_title { Factory.next(:title) }
  f.description { Factory.next(:description) }
  f.top_tags { Factory.next(:name) }
  f.priority 1
  f.status 1
  f.last_requested_at DateTime.now
  f.last_harvested_at DateTime.now
  f.harvest_interval 86400
  f.failed_requests 0
  f.harvested_from_display_uri { Factory.next(:uri) }
  f.harvested_from_title { Factory.next(:title) }
  f.harvested_from_short_title { Factory.next(:title) }
  f.entries_count 0
  f.default_language { |a| a.association(:language) }
  f.default_grain_size 'unknown'
end

Factory.define :entry do |f|
  f.feed { |a| a.association(:feed) }
  f.permalink { Factory.next(:uri) }
  f.author { Factory.next(:name) }
  f.title { Factory.next(:title) }
  f.description { Factory.next(:description) }
  f.content { Factory.next(:description) }
  f.unique_content { Factory.next(:description) }
  f.published_at DateTime.now
  f.entry_updated_at DateTime.now
  f.harvested_at DateTime.now
  f.language { |a| a.association(:language) }
  f.direct_link { Factory.next(:uri) }
  f.grain_size 'unknown'
end


Factory.define :content do |f|
  f.creator { |a| a.association(:user) }
  f.title { Factory.next(:title) }
  f.body_raw { Factory.next(:description) }
  f.is_public true
  f.locale 'en'
end

Factory.define :content_translation do |f|
  f.content { |a| a.association(:content) }
  f.title { Factory.next(:title) }
  f.body { Factory.next(:description) }
  f.locale 'en'
end

Factory.define :content_permission do |f|
  f.content { |a| a.association(:content) }
  f.user {|a| a.association(:user)}
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