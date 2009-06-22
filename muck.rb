app_name = ask("What do you want to call your application? (ie George The App)")
app_safe_name = ask("Application safe name? (ie george_the_app)")
domain_name = ask("What domain name would you like for your application? (ie example.com)")
install_tagging = true if yes?('Install Tagging? (y/n)')
install_gems = false #true if yes?('Install gems on local system? (y/n)')
unpack_gems = false #true if yes?('Unpack gems into vendor directory? (y/n)')
install_capistrano = false #true if yes?('Install capistrano? (y/n)')

setup_submodules_for_development = true if ask('Setup submodules for development?  You must have dev access to muck to do this. (y/n)') 

#====================
# Setup git.  Without this submodules wont' work
#====================
git :init

#====================
# plugins 
#====================
plugin 'hoptoad_notifier', :git => "git://github.com/thoughtbot/hoptoad_notifier.git"
plugin 'recaptcha', :git => "git://github.com/ambethia/recaptcha.git"
plugin 'ssl_requirement', :git => 'git://github.com/rails/ssl_requirement.git'
plugin 'jquery', :svn => "http://ennerchi.googlecode.com/svn/trunk/plugins/jrails"
plugin 'validation_reflection', :git => "git://github.com/redinger/validation_reflection.git"
plugin 'validate_attributes', :git => "git://github.com/jbasdf/validate_attributes.git"
plugin 'friendly_id', :git => "git://github.com/norman/friendly_id.git"

# muck engines
plugin 'muck_engine', :git => "git://github.com/jbasdf/muck_engine.git", :submodule => true
plugin 'muck_users_engine', :git => "git://github.com/jbasdf/muck_users_engine.git", :submodule => true

#====================
# gems 
#====================
gem 'authlogic', :version => '>=2.0.13'
gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'
gem 'bcrypt-ruby', :lib => 'bcrypt', :version => '>=2.0.5'
gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
gem 'mbleigh-acts-as-taggable-on', :source => "http://gems.github.com", :lib => "acts-as-taggable-on" if install_tagging
gem "binarylogic-searchlogic", :lib => 'searchlogic', :source => 'http://gems.github.com', :version => '~> 2.0.0'
    
# Install gems on local system
rake('gems:install', :sudo => true) if install_gems 
rake('gems:unpack:dependencies') if unpack_gems

# setup migrations

run "script/generate acts_as_taggable_on_migration" if install_tagging

#==================== 
# Install and configure capistrano 
#====================
run "sudo gem install capistrano" if install_capistrano

#==================== 
# build application files 
#====================

file 'db/migrate/20090327231918_create_users.rb',
%q{class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string   :login
      t.string   :email
      t.string   :first_name
      t.string   :last_name
      t.string   :crypted_password
      t.string   :password_salt
      t.string   :persistence_token,   :null => false
      t.string   :single_access_token, :null => false
      t.string   :perishable_token,    :null => false
      t.integer  :login_count,         :null => false, :default => 0
      t.integer  :failed_login_count,  :null => false, :default => 0
      t.datetime :last_request_at                                   
      t.datetime :current_login_at                                  
      t.datetime :last_login_at                                     
      t.string   :current_login_ip                                  
      t.string   :last_login_ip
      t.boolean  :terms_of_service,          :default => false, :null => false
      t.string   :time_zone,                 :default => "UTC"
      t.datetime :disabled_at
      t.datetime :created_at
      t.datetime :activated_at
      t.datetime :updated_at
      t.string   :identity_url
      t.string   :url_key
    end

    add_index :users, :login
    add_index :users, :email
    add_index :users, :persistence_token
    add_index :users, :last_request_at

  end

  def self.down
    drop_table :users
  end
end  
}


file 'config/environment.rb',
%q{# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'ostruct'
require 'yaml'
::GlobalConfig = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/global_config.yml")[RAILS_ENV])

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem "authlogic"
  config.gem "bcrypt-ruby", :lib => "bcrypt", :version => ">=2.0.5"
  config.gem 'thoughtbot-paperclip', :lib => 'paperclip', :source => 'http://gems.github.com'
} + 
%Q{ #{" config.gem 'mbleigh-acts-as-taggable-on', :lib => 'acts-as-taggable-on', :source => 'http://gems.github.com'" if install_tagging} } +
%q{# Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
end
}

file 'config/environments/test.rb',
%q{
# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false
config.action_view.cache_template_loading            = true

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection    = false

# Tell Action Mailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

# Use SQL instead of Active Record's schema dumper when creating the test database.
# This is necessary if your schema can't be completely dumped by the schema dumper,
# like if you have constraints or database-specific column types
# config.active_record.schema_format = :sql

config.gem 'mocha', :version => '>= 0.9.5'
config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'

require 'factory_girl'
require 'mocha'
begin require 'redgreen'; rescue LoadError; end

}

file 'config/global_config.yml',
%Q{default: &DEFAULT

  # Sent in emails to users
  application_name: '#{app_name}'
  from_email: 'support@#{domain_name}'
  support_email: 'support@#{domain_name}'
  admin_email: 'admin@#{domain_name}'
  customer_service_number: '1-800-'
  
  # Email charset
  mail_charset: 'utf-8'

  automatically_activate: true
  automatically_login_after_account_create: true
  send_welcome: true

  # if you use recaptcha you will need to also provide a public and private
  # key available from http://recaptcha.net.
  use_recaptcha: true
  recaptcha_pub_key: GET_A_RECAPTCHA_KEY(TODO)
  recaptcha_priv_key: GET_A_RECAPTCHA_KEY(TODO)
  
  # jgrowl related settings
  growl_enabled: true
  growl_flash_messages: false
  growl_ar_errors: false
  
  # application configuration
  let_users_delete_their_account: false  # turn on/off ability for users to delete their own account
  enable_live_activity_updates: true # Turns on polling inside the user's activity feed so they constantly get updates from the site

  
production:
  <<: *DEFAULT

  # Sent in emails to users
  application_url: 'www.#{domain_name}'

  # Source address for user emails
  email_from: 'support@#{domain_name}'

staging:
  <<: *DEFAULT

  # Sent in emails to users
  application_url: 'staging.#{domain_name}'
    
development:
  <<: *DEFAULT

  application_url: 'localhost:3000'
  
test:
  <<: *DEFAULT

  # controls account activation and automatic login
  automatically_activate: false
  automatically_login_after_account_create: false
  
  # turn off for testing
  use_recaptcha: false
  
  application_url: 'localhost:3000'
}

file 'app/controllers/application_controller.rb',
%Q{class ApplicationController < ActionController::Base
  
  include SslRequirement
  layout 'default'
    
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
   
  before_filter :set_body_class
  
  protected
  
  # only require ssl if we are in production
  def ssl_required?
    return ENV['SSL'] == 'on' ? true : false if defined? ENV['SSL']
    return false if local_request?
    return false if RAILS_ENV == 'test'
    ((self.class.read_inheritable_attribute(:ssl_required_actions) || []).include?(action_name.to_sym)) && (RAILS_ENV == 'production' || RAILS_ENV == 'staging')
  end
  
  def setup_paging
    @page = (params[:page] || 1).to_i
    @page = 1 if @page < 1
    @per_page = (params[:per_page] || (Rails.env=='test' ? 1 : 40)).to_i
  end

  # Automatically respond with 404 for ActiveRecord::RecordNotFound
  def record_not_found
    render :file => File.join(RAILS_ROOT, 'public', '404.html'), :status => 404
  end

  private
  def set_body_class
    @body_class ||= "body"
  end 

end
}

file 'app/helpers/application_helper.rb',
%Q{module ApplicationHelper
  #{'include TagsHelper' if install_tagging }
end
}

file 'app/views/layouts/default.html.erb',
%q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
  	<head>
  		<title><%= @page_title || GlobalConfig.application_name %></title>
  		<meta http-equiv="content-type" content="text/xhtml; charset=utf-8" />
  		<meta http-equiv="imagetoolbar" content="no" />
  		<meta name="distribution" content="all" />
  		<meta name="robots" content="all" />	
  		<meta name="resource-type" content="document" />
  		<meta name="MSSmartTagsPreventParsing" content="true" />
      <%= stylesheet_link_tag %w{
            reset
            blueprint/screen
            styles
          }, :cache => true %>
      <%= stylesheet_link_tag 'blueprint/print.css', :media => "print" %>
      <!--[if IE]><%= stylesheet_link_tag "blueprint/ie.css", :media => "screen, projection" %><![endif]-->
      <%= javascript_include_tag %w{
            jquery/jquery.js
            jquery/jquery-ui.js
            jquery/jrails.js
            jquery/jquery.jgrowl.js
            jquery/jquery.tips.js
            application.js
          }, :cache => 'all_js_cached' %>
      <%= javascript_tag %[const AUTH_TOKEN = #{form_authenticity_token.inspect};] if protect_against_forgery? %>
      <%= yield :head -%>
  	</head>
  	<body>
  	  <div id="wrapper">
  	    <div id="header">

        </div>
        <div id="content-wrapper">
          <div id="content">
  		      <%= yield :layout %>
  		    </div>
  		  </div>
  		</div>
  		<script type="text/javascript" language="JavaScript">
      jQuery(document).ready(function(){
        <%= yield :ready %>
      });
      </script>  
  	</body>
  </html>
}


file 'Capfile',
%Q{load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'  
}


file 'config/database.yml',
%Q{development:
  adapter: mysql
  database: #{app_safe_name}_development
  username: root
  password:
  host: localhost
  encoding: utf8

test:
  adapter: mysql
  database: #{app_safe_name}_test
  username: root
  password:
  host: localhost
  encoding: utf8

staging:
  adapter: mysql
  database: #{app_safe_name}_staging
  username: #{app_safe_name}
  password: 
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock

production:
  adapter: mysql
  database: #{app_safe_name}_production
  username: #{app_safe_name}
  password: 
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock
}

initializer 'time_formats.rb',
%q{# Example time formats
{ :short_date => "%x", :long_date => "%a, %b %d, %Y" }.each do |k, v|
  ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.update(k => v)
end
}

initializer 'caching.rb',
%q{ActionController::Base.cache_store = :file_store, RAILS_ROOT + 'system/tmp/cache/'}

initializer 'hoptoad.rb',
%Q{HoptoadNotifier.configure do |config|
  config.api_key = 'GET A HOPTOAD KEY(TODO)'
end  
}

initializer 'recaptcha.rb',
%q{if GlobalConfig.use_recaptcha
  ENV['RECAPTCHA_PUBLIC_KEY'] = GlobalConfig.recaptcha_pub_key
  ENV['RECAPTCHA_PRIVATE_KEY'] = GlobalConfig.recaptcha_priv_key
end}

initializer 'protect_attributes.rb',
%q{module ActiveRecord
  class Base
    private
      def attributes_protected_by_default
        default = [ self.class.primary_key, self.class.inheritance_column ]
        default.concat ['created_at', 'created_on', 'updated_at', 'updated_on']
        default << 'id' unless self.class.primary_key.eql? 'id'
        default
      end
  end
end}

#==================== 
# Build custom application files
#====================

file 'app/models/user.rb',
%Q{class User < ActiveRecord::Base
  
  acts_as_authentic
  acts_as_muck_user
  #{ 'acts_as_tagger' if install_tagging }
  
  has_friendly_id :login

  def short_name
    self.first_name || login
  end
  
  def full_name
    if self.first_name.blank? && self.last_name.blank?
      self.login rescue 'Deleted user'
    else
      ((self.first_name || '') + ' ' + (self.last_name || '')).strip
    end
  end

  def display_name
    h(self.login)
  end
  
end
}

file 'app/models/user_session.rb',
%Q{class UserSession < Authlogic::Session::Base
end
}

file 'app/controllers/default_controller.rb',
%q{class DefaultController < ApplicationController

  def index
    respond_to do |format|
      format.html { render }
    end
  end

  def contact
    return unless request.post?
    body = []
    params.each_pair { |k,v| body << "#{k}: #{v}"  }
    HomeMailer.deliver_mail(:subject => I18n.t("contact.contact_response_subject", :application_name => GlobalConfig.application_name), :body=>body.join("\n"))
    flash[:notice] = I18n.t('general.thank_you_contact')
    redirect_to contact_url    
  end

  def sitemap
    respond_to do |format|
      format.html { render }
    end
  end

  def ping
    user = User.first
    render :text => 'we are up'
  end
  
end
}


file 'app/views/default/index.html.erb',
%q{Welcome home}


file 'app/views/default/contact.html.erb',
%q{<div id="contact">

	<h2><%= I18n.t('contact.contact_us') %></h2>

	<form action="/contact/" method="post">
	
	  <div class="row clear">
	    <label for="form_name"><%= I18n.t('contact.name') %></label>
	    <div class="formHelp"><%= I18n.t('contact.name_help') %></div>
	    <input type="text" id="form_name" name="name" />
	  </div>

	  <div class="row clear">
	    <label for="form_phone"><%= I18n.t('contact.phone') %></label>
			<div class="formHelp"><%= I18n.t('contact.phone_help') %></div>
	    <input type="text" id="form_phone" name="phone" />
	  </div>

	  <div class="row clear">
	    <label for="form_email"><%= I18n.t('contact.email') %></label>
			<div class="formHelp"><%= I18n.t('contact.email_help') %></div>
	    <input type="text" id="form_email" name="email" />
	  </div>

	  <div class="row clear">
	    <label for="form_message"><%= I18n.t('contact.subject') %></label>
			<div class="formHelp"><%= I18n.t('contact.subject_help') %></div>
	    <input type="text" id="form_email" name="email" />
	  </div>
	
	  <div class="row clear">
	    <label for="form_message"><%= I18n.t('contact.question') %></label>
	    <div class="formHelp"><%= I18n.t('contact.question_help') %></div>
			<textarea id="form_message" name="message"></textarea>
	  </div>

	  <input type="submit" value="<%= I18n.t('general.send') %>" class="button"/>
  
	  <div class="clear"></div>

	</form>
		
</div>}

file 'config/locales/en.yml',
%q{en:
  contact: 
    contact_us: 'Contact Us'
    name: 'Your name:'
    name_help: 'Please provide us with your name.'
    phone: 'Your phone number:'
    phone_help: 'Your phone number is optional but will help us contact you if necessary.'
    email: 'Your email:'
    email_help: 'Please provide us with your email so that we can contact you if necessary.'
    subject: 'Subject:'
    subject_help: 'A simple statement indicating the nature of your feedback.'
    question: 'Your message/question:'
    question_help: 'Please include any comments you would like us to hear.'
    contact_response_subject: 'Thanks for your inquiry from {{application_name}}!'
  general:
    thank_you_contact: 'Thank you for your message.  A member of our team will respond to you shortly.'
    send: 'Send'
}

#==================== 
# Build routes file
#====================
file 'config/routes.rb',
%Q{ActionController::Routing::Routes.draw do |map|

  map.home '', :controller => 'default', :action => 'index'
  map.root :controller => 'default', :action => 'index'

  # top level pages
  map.contact '/contact', :controller => 'default', :action => 'contact'
  map.sitemap '/sitemap', :controller => 'default', :action => 'sitemap'
  map.ping '/ping', :controller => 'default', :action => 'ping'
  
end
}


# ====================
# Test files
# ====================
 
file 'test/shoulda_macros/forms.rb',
%q{class Test::Unit::TestCase
  def self.should_have_form(opts)
    model = self.name.gsub(/ControllerTest$/, '').singularize.downcase
    model = model[model.rindex('::')+2..model.size] if model.include?('::')
    http_method, hidden_http_method = form_http_method opts[:method]
    should "have a #{model} form" do
      assert_select "form[action=?][method=#{http_method}]", eval(opts[:action]) do
        if hidden_http_method
          assert_select "input[type=hidden][name=_method][value=#{hidden_http_method}]"
        end
        opts[:fields].each do |attribute, type|
          attribute = attribute.is_a?(Symbol) ? "#{model}[#{attribute.to_s}]" : attribute
          assert_select "input[type=#{type.to_s}][name=?]", attribute
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
}
 
file 'test/shoulda_macros/pagination.rb',
%q{class Test::Unit::TestCase
  # Example:
  # context "a GET to index logged in as admin" do
  # setup do
  # login_as_admin
  # get :index
  # end
  # should_paginate_collection :users
  # should_display_pagination
  # end
  def self.should_paginate_collection(collection_name)
    should "paginate #{collection_name}" do
      assert collection = assigns(collection_name),
      "Controller isn't assigning to @#{collection_name.to_s}."
      assert_kind_of WillPaginate::Collection, collection,
      "@#{collection_name.to_s} isn't a WillPaginate collection."
    end
  end
  def self.should_display_pagination
    should "display pagination" do
      assert_select "div.pagination", { :minimum => 1 },
      "View isn't displaying pagination. Add <%= will_paginate @collection %>."
    end
  end
  # Example:
  # context "a GET to index not logged in as admin" do
  # setup { get :index }
  # should_not_paginate_collection :users
  # should_not_display_pagination
  # end
  def self.should_not_paginate_collection(collection_name)
    should "not paginate #{collection_name}" do
      assert collection = assigns(collection_name),
      "Controller isn't assigning to @#{collection_name.to_s}."
      assert_not_equal WillPaginate::Collection, collection.class,
      "@#{collection_name.to_s} is a WillPaginate collection."
    end
  end
  def self.should_not_display_pagination
    should "not display pagination" do
      assert_select "div.pagination", { :count => 0 },
      "View is displaying pagination. Check your logic."
    end
  end
end
}
 
file 'test/test_helper.rb',
%q{$:.reject! { |e| e.include? 'TextMate' }
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require File.expand_path(File.dirname(__FILE__) + '/test_definitions')
require 'test_help'
require 'factory_girl'
require File.expand_path(File.dirname(__FILE__) + '/factories')
class ActiveSupport::TestCase
  
  include TestDefinitions
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  self.backtrace_silencers << :rails_vendor
  self.backtrace_filters << :rails_root
  fixtures :all
end
}


file 'test/factories.rb',
%q{
}

file 'test/test_definitions.rb',
%q{module TestDefinitions
  NOT_LOGGED_IN_MSG = /You must be logged in to access this feature/i
  PERMISSION_DENIED_MSG = /You don't have permission to do that/i
end
}

#==================== 
# Muck sync tasks
#==================== 
rake('muck:base:sync')
rake('muck:users:sync')

#==================== 
# Setup database
#==================== 

# create sessions
rake('db:sessions:create') # Use database (active record) session store

# make the db
rake('db:create:all')

# initial migration
rake('db:migrate')
rake('db:test:prepare')

#==================== 
# muck db tasks
#==================== 
rake('muck:db:populate_states_and_countries')
rake('muck:users:create_admin')

#==================== 
# remove default files 
#====================
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run 'rm public/images/rails.png'

#==================== 
# clean up javascript 
#====================
run "rm public/javascripts/jquery.js"
run "rm public/javascripts/jquery-ui.js"
run "mv public/javascripts/jrails.js public/javascripts/jquery/jrails.js"

#==================== 
# Setup git
#====================
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
  
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
.DS_Store
coverage/*
log/*.log
tmp/**/*
db/*.db
db/*.sqlite3
db/schema.rb
config/database.yml
db/*.sqlite3
doc/api
doc/app
END
 
# Commit all work so far to the repository
git :add => '.'
git :commit => "-a -m 'Initial commit'"

# Initialize submodules
git :submodule => "init"

if setup_submodules_for_development
  inside ('vendor/plugins/muck_engine') do
    run "git remote add my git@github.com:jbasdf/muck_engine.git"
  end
  inside ('vendor/plugins/muck_users_engine') do
    run "git remote add my git@github.com:jbasdf/muck_users_engine.git"
  end
end
 
# Success!
puts "SUCCESS!"
puts "Search for 'TODO' to find specific items that need to be configured"
