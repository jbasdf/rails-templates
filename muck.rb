# TemplateRunner docs:
# http://apidock.com/rails/Rails/TemplateRunner

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

app_name = ask("What do you want to call your application? (ie George The App)")
app_safe_name = ask("Application safe name? (ie george_the_app)")
domain_name = ask("What domain name would you like for your application? (ie example.com)")
install_capistrano = false #true if yes?('Install capistrano? (y/n)')

#====================
# Setup git.  Without this submodules wont' work
#====================
git :init

#==================== 
# Write Gemfile
#==================== 
file 'Gemfile', <<-CODE
source 'http://rubygems.org'

gem 'rails', '3.0.1'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

if RUBY_VERSION < '1.9'
  gem "ruby-debug"
end

CODE

gem 'mysql'

gem "authlogic"
gem "will_paginate"
gem "bcrypt-ruby", ">=2.1.1", :require => "bcrypt"
gem "paperclip"
gem "friendly_id"
gem "hoptoad_notifier"
gem "recaptcha", :require => "recaptcha/rails"
gem 'jquery-rails', '>= 0.2.6'

gem "muck-engine", ">=3.2.0"
gem "muck-users", ">=3.1.0"
gem "muck-resources", ">=3.0.0"

#==================== 
# Run bundler to install the required gems.
#==================== 
run('bundle install')


#==================== 
# Install and configure capistrano 
#====================
run "sudo gem install capistrano" if install_capistrano

#==================== 
# build application files 
#====================

file_inject 'config/application.rb', "Bundler.require(:default, Rails.env) if defined?(Bundler)", <<-CODE

require 'ostruct'
require 'yaml'
::Secrets = OpenStruct.new(YAML.load_file(File.expand_path('../secrets.yml', __FILE__))[Rails.env])
CODE

initializer 'muck.rb',
%Q{
#
# Replace #{domain_name} in this file with your website's domain name
#
  
MuckEngine.configure do |config|

  # Environment sensitive values
  if Rails.env.production?
    config.application_url = 'www.#{domain_name}'     # Url of the application in production
  elsif Rails.env.staging?
    config.application_url = 'www.#{domain_name}'     # Url of the application on staging
  else
    config.application_url = 'localhost:3000'         # Url of the application for test or development
  end
  
  # Global application values.  These are used to display the app name, send emails, and configure where system emails go.
  config.application_name = '#{app_name}'       # Common name for your application.  i.e. My App, Billy Bob, etc
  config.from_email = 'support@#{domain_name}'  # Emails will come from this address i.e. noreply@example.com, support@example.com, system@example.com, etc
  config.from_email_name = 'TODO Name'          # This will show up as the name on emails.  i.e. support@example.com <Example>
  config.support_email = 'support@#{domain_name}'  # Support email for your application.  This is used for contact us etc.
  config.admin_email = 'admin@#{domain_name}'      # Admin email for your application
  config.customer_service_number = '1-800-'     # Phone number if you have one (optional)

  # Email charset.  No need to change this unless you have a good reason to change the encoding.
  config.mail_charset = 'utf-8'

  # Application settings
  config.local_jquery = false         # If true jquery will be loaded from the local directory. If false then it will be loaded from Google's CDN
  config.growl_enabled = false        # If true then notifications and errors will popup in an overlay div similar to 'growl' on the mac. This uses jGrowl which must be included in your layout

  # Email server configuration
  # Sendgrid is easy: https://sendgrid.com/user/signup
  config.email_server_address = "smtp.sendgrid.net"    # Email server address.  'smtp.sendgrid.net' works for sendgrid
  config.email_user_name = Secrets.email_user_name    # Email server username
  config.email_password = Secrets.email_password      # Email server password
  config.base_domain = '#{domain_name}'                # Basedomain that emails will come from

  # ssl
  config.enable_ssl = false # Enable ssl if you have an ssl certificate installed.  This will provide security between the client and server.

  # Google Analtyics Configuration.  This will enable Google Analytics on your site and will be used if your template includes:
  #                                  <%= render :partial => 'layouts/global/google_analytics' %>
  config.google_tracking_code = ""                     # Get a tracking code here: http://www.google.com/analytics/. The codes look like this: 'UA-9685000-0'
  config.google_tracking_set_domain = "#{domain_name}" # Base domain provided to Google Analytics. Useful if you are using subdomains but want all traffic 
                                              # recorded into one account.
end
  
MuckUsers.configure do |config|

  # sign up options
  config.automatically_activate = true                    # Automatically active a users account during registration. If true the user won't get a 
                                                          # 'confirm account' email. If false then the user will need to confirm their account via an email.
  config.automatically_login_after_account_create = true  # Automatically log the user in after they have setup their account. This should be false if you 
                                                          # require them to activate their account.
  config.send_welcome = true                              # Send out a welcome email after the user has signed up.

  # if you use recaptcha you will need to also provide a public and private key available from http://recaptcha.net.
  config.use_recaptcha = false      # This will turn on recaptcha during registration. This is an alternative to sending the 
                                    # user a confirm email and can help reduce spam registrations.

  config.let_users_delete_their_account = false   # Turn on/off ability for users to delete their own account. It is not recommended that you let 
                                                  # users delete their own accounts since the delete can cascade through the system with unknown results.
end
  
}


file 'config/secrets.yml',
%Q{
default: &DEFAULT
  
  email_user_name: 'TODO_admin@#{domain_name}'    # Email server username
  email_password: 'TODO_password'                 # Email server password
  
  recaptcha_pub_key: 'GET_A_RECAPTCHA_KEY(TODO)'    # key available from http://recaptcha.net
  recaptcha_priv_key: 'GET_A_RECAPTCHA_KEY(TODO)'

  # keys
  hoptoad_key: '' # Get a hoptoad key - https://hoptoadapp.com/account/new

production:
  <<: *DEFAULT
  # Add production specific secrets
staging:
  <<: *DEFAULT
  # Add staging specific secrets
development:
  <<: *DEFAULT
  # Development specific secrets
test:
  <<: *DEFAULT
  # Test specific secrets
}

file 'app/controllers/application_controller.rb',
%Q{class ApplicationController < ActionController::Base
  
  layout 'default'
    
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
end
}

file 'app/views/layouts/default.html.erb',
%q{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
  <%= render :partial => 'layouts/global/head' %>
</head>
<body>
  <div id="wrapper" class="container">
    <%= render :partial => 'layouts/global/header' %>
    <div id="content-wrapper">
      <div id="content">
        <%= yield :layout %>
      </div>
    </div>
    <%= render :partial => 'layouts/global/footer' %>
  </div>
  <script type="text/javascript" language="JavaScript">
  <%= yield :javascript %>
  </script>
  <%= render :partial => 'layouts/global/google_analytics' %>
</body>
</html>}

file 'app/views/layouts/global/_head.html.erb',
%q{<title><%= @page_title || MuckEngine.configuration.application_name %></title>
<meta http-equiv="content-type" content="text/xhtml; charset=utf-8" />
<meta http-equiv="imagetoolbar" content="no" />
<meta name="distribution" content="all" />
<meta name="robots" content="all" />	
<meta name="resource-type" content="document" />
<meta name="MSSmartTagsPreventParsing" content="true" />
<%= stylesheet_link_tag 'blueprint/print.css', :media => "print" %>
<!--[if IE]><link rel="stylesheet" href="/stylesheets/blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
<% if MuckEngine.configuration.local_jquery -%>
  <link rel="stylesheet" href="/stylesheets/jquery/smoothness/jquery-ui-1.8.4.custom.css" type="text/css" />
  <script src="/javascripts/jquery/jquery.js" type="text/javascript"></script>
  <script src="/javascripts/jquery/jquery-ui-1.8.4.custom.min.js" type="text/javascript"></script>
<% else -%>
  <%= google_load_jquery_ui_css(http_protocol, 'smoothness', '1.8.10') %>
  <%= google_load_jquery(http_protocol, '1.5.1') %>
  <%= google_load_jquery_ui(http_protocol, '1.8.10') %>
<% end -%>
<%= stylesheet_link_tag %W{ reset styles blueprint/screen.css default }, :cache => true %>
<%= javascript_include_tag %w{
  jquery/jquery.form.js
  jquery/jquery.jgrowl.js
  jquery/jquery.tips.js
  jquery/jquery.easing.js
  jquery/jquery.fancybox.js
  rails.js
  muck.js
  application.js }, :cache => 'all_js_cached' %>
<%= javascript_tag %[const AUTH_TOKEN = #{form_authenticity_token.inspect};] if protect_against_forgery? %>
<%= yield :head -%>}

file 'app/views/layouts/global/_header.html.erb',
%q{<div class="block" id="header">
    <a href="/"><div id="logo" class="span-8 column">&nbsp;</div></a>
    <%= render :partial => 'layouts/global/login_controls' %>
  </div>}

file 'app/views/layouts/global/_footer.html.erb',
%q{<div class="block" id="footer">
</div>
<div class="block" align="center">
   <%= locale_link 'Deutsch', 'de' %>
 | <%= locale_link 'English', 'en' %>
 | <%= locale_link 'Español', 'es' %>
 | <%= locale_link 'Français', 'fr' %>
 | <%= locale_link 'Nederlands', 'nl' %>
 | <%= locale_link 'Русский язык', 'ru' %>
 | <%= locale_link '中文', 'zh' %>
 | <%= locale_link '日本語', 'ja' %>
</div>}

file 'app/views/layouts/global/_login_controls.html.erb',
%q{<div class="span-8 column">
      <div id="user-login">
        <% if logged_in? -%>
          <%= link_to t('muck.users.sign_out_title'), logout_path %>
        <% else -%>
          <%= link_to t('muck.users.sign_up'), signup_path %> | <%= link_to t('muck.users.sign_in'), login_path %> 
        <% end -%>
      </div>
    </div>}

file 'public/stylesheets/default.css',
%q{
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

production:
  adapter: mysql
  database: #{app_safe_name}_production
  username: #{app_safe_name}
  password: 
  host: localhost
  encoding: utf8
}

initializer 'caching.rb',
%q{ActionController::Base.cache_store = :file_store, ::Rails.root + 'system/tmp/cache/'}

initializer 'hoptoad.rb',
%Q{HoptoadNotifier.configure do |config|
  config.api_key = Secrets.hoptoad_key
end  
}

initializer 'recaptcha.rb',
%q{if MuckUsers.configuration.use_recaptcha
  ENV['RECAPTCHA_PUBLIC_KEY'] = Secrets.recaptcha_pub_key
  ENV['RECAPTCHA_PRIVATE_KEY'] = Secrets.recaptcha_priv_key
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

initializer 'smtp.rb',
%Q{unless Rails.env.test? # we don't want tests attempting to send out email
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address => MuckEngine.configuration.email_server_address,
    :port => 25,
    :authentication => :plain,
    :enable_starttls_auto => true,
    :user_name => Secrets.email_user_name,
    :password => Secrets.email_password,
    :domain => MuckEngine.configuration.base_domain
  }
  # ActionMailer::Base.smtp_settings = {
  #   :address => "smtp.gmail.com",
  #   :port => 587,
  #   :authentication => :plain,
  #   :enable_starttls_auto => true,
  #   :user_name => Secrets.email_user_name,
  #   :password => Secrets.email_password,
  #   :domain => MuckEngine.configuration.base_domain
  # }
end

ActionMailer::Base.default_url_options[:host] = MuckEngine.configuration.application_url
}

#==================== 
# Build custom application files
#====================

file 'app/models/user.rb',
%Q{class User < ActiveRecord::Base
  
  acts_as_authentic do |c|
    c.crypto_provider = Authlogic::CryptoProviders::BCrypt
  end
  include MuckUsers::Models::MuckUser
    
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
    self.login
  end
  
end
}

file 'app/models/user_session.rb',
%Q{class UserSession < Authlogic::Session::Base
end
}

file 'app/models/access_code.rb',
%Q{class AccessCode < ActiveRecord::Base
  include MuckUsers::Models::MuckAccessCode
end
}

file 'app/models/access_code_request.rb',
%Q{class AccessCodeRequest < ActiveRecord::Base
  include MuckUsers::Models::MuckAccessCodeRequest
end
}

file 'app/models/country.rb',
%Q{class Country < ActiveRecord::Base
  include MuckEngine::Models::MuckCountry  
end
}

file 'app/models/language.rb',
%Q{class Language < ActiveRecord::Base
  include MuckEngine::Models::MuckLanguage
end
}

file 'app/models/state.rb',
%Q{class State < ActiveRecord::Base
  include MuckEngine::Models::MuckState
end
}

file 'app/mailers/user_mailer.rb',
%Q{class UserMailer < ActionMailer::Base
  include MuckUsers::Mailers::MuckUserMailer
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
    params.each_pair do |k,v|
      if !['authenticity_token', 'action', 'controller'].include?(k) 
        body << "#{k}: #{v}"
      end
    end
    BasicMailer.mail_from_params(:subject => I18n.t("contact.contact_response_subject", :application_name => MuckEngine.configuration.application_name), :body=>body.join("\n"))
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

  <%= output_errors('', {:class => 'help-box'}) %>
  
	<h2><%= I18n.t('contact.contact_us') %></h2>

	<% form_tag('/contact', :id => "contact_form") do -%>
	
	  <div class="row clear">
	    <label for="name"><%= I18n.t('contact.name') %></label>
	    <div class="form-help"><%= I18n.t('contact.name_help') %></div>
	    <input type="text" id="name" name="name" />
	  </div>

	  <div class="row clear">
	    <label for="phone"><%= I18n.t('contact.phone') %></label>
			<div class="form-help"><%= I18n.t('contact.phone_help') %></div>
	    <input type="text" id="phone" name="phone" />
	  </div>

	  <div class="row clear">
	    <label for="email"><%= I18n.t('contact.email') %></label>
			<div class="form-help"><%= I18n.t('contact.email_help') %></div>
	    <input type="text" id="email" name="email" />
	  </div>

	  <div class="row clear">
	    <label for="subject"><%= I18n.t('contact.subject') %></label>
			<div class="form-help"><%= I18n.t('contact.subject_help') %></div>
	    <input type="text" id="subject" name="email" />
	  </div>
	
	  <div class="row clear">
	    <label for="message"><%= I18n.t('contact.question') %></label>
	    <div class="form-help"><%= I18n.t('contact.question_help') %></div>
			<textarea id="message" name="message"></textarea>
	  </div>

	  <input type="submit" value="<%= I18n.t('general.send') %>" class="button"/>
  
	  <div class="clear"></div>

	<% end -%>
		
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
    contact_response_subject: 'Thanks for your inquiry from %{application_name}!'
  general:
    thank_you_contact: 'Thank you for your message.  A member of our team will respond to you shortly.'
    send: 'Send'
}


#==================== 
# Don't include root in json output
#====================
file_append 'config/initializers/muck.rb', <<-CODE
if defined?(ActiveRecord)
  # Don't Include Active Record class name as root for JSON serialized output.
  ActiveRecord::Base.include_root_in_json = false
end
CODE

#==================== 
# Build routes file
#====================
file_inject 'config/routes.rb', "::Application.routes.draw do", <<-CODE
  root :to => "default#index"

  # top level pages
  match '/contact' => 'default#contact'
  match '/sitemap' => 'default#sitemap'
  match '/ping' => 'default#ping'

CODE

#==================== 
# General Setup
#==================== 
run "rails generate friendly_id"

# The extra '5' seconds is needed or else the migration from friendly id above and this migration will get the exact same timestamp.
timestamp = (Time.now + 5).utc.strftime("%Y%m%d%H%M%S") # HACK stole this from rails migration script
file "db/migrate/#{timestamp}_add_scope_index_to_slugs.rb", 
%q{class AddScopeIndexToSlugs < ActiveRecord::Migration
  def self.up
    add_index :slugs, :scope
  end
  def self.down
    remove_index :slugs, :scope
  end
end
}

# Note this is located between the friendly_id migration generation and the db:session:create because occasionally the 
# script would run fast enough that the migrations would end up with the same timestamp.
#==================== 
# Muck sync tasks
#==================== 
rake('muck:sync')

#==================== 
# Setup database
#==================== 

# make the db
rake('db:create')

# create sessions
rake('db:sessions:create') # Use database (active record) session store

# initial migration
rake('db:migrate')
rake('db:test:prepare')

#==================== 
# muck db tasks
#==================== 
rake('muck:db:populate ')

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

#==================== 
# Change to the jquery rails.js file
#====================
run "rails generate jquery:install"

#==================== 
# Setup git
#====================
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
  
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
coverage/*
tmp/**/*
doc/api
doc/app
**/*.pid
log/*.log
log/*.pid
tmp
.DS_Store
public/cache/**/*
public/system/**/*
doc/**/*
db/*.db
db/*.sqlite3
.project
.loadpath
nbproject/
.idea
testjour.log
*.so
*.o
Makefile
mkmf.log
*.bundle
conftest
content/
.idea
*.sw?
.DS_Store
coverage
rdoc
pkg
pkg/*
log/*
secrets.yml
END


# Commit all work so far to the repository
git :add => '.'
git :commit => "-a -m 'Initial commit'"

# # Initialize submodules
# git :submodule => "init"

# if setup_submodules_for_development
#   inside ('vendor/plugins/muck_engine') do
#     run "git remote add my git@github.com:jbasdf/muck_engine.git"
#   end
#   inside ('vendor/plugins/muck_users_engine') do
#     run "git remote add my git@github.com:jbasdf/muck_users_engine.git"
#   end
# end
 
# Success!

puts "================================================================================"
puts "SUCCESS!"
puts "Search for 'TODO' to find specific items that need to be configured"
puts "Next steps:"
puts "1. Install other muck functionality:"
puts "   Run rake rails:template LOCATION=http://github.com/jbasdf/rails-templates/raw/master/muck_too.rb"
puts "2. Install tests:"
puts "   rake rails:template LOCATION=http://github.com/jbasdf/rails-templates/raw/master/muck_test.rb"
puts "3. Add default data"
puts "   rake muck:users:create_admin # to create a default admin user with the password 'asdfasdf'"
puts "================================================================================"
