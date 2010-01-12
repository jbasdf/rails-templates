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
install_gems = false #true if yes?('Install gems on local system? (y/n)')
unpack_gems = false #true if yes?('Unpack gems into vendor directory? (y/n)')
install_capistrano = false #true if yes?('Install capistrano? (y/n)')

#setup_submodules_for_development = true if ask('Setup submodules for development?  You must have dev access to muck to do this. (y/n)') 

#====================
# Setup git.  Without this submodules wont' work
#====================
git :init

#====================
# plugins 
#====================
plugin 'hoptoad_notifier', :git => "git://github.com/thoughtbot/hoptoad_notifier.git"
plugin 'ssl_requirement', :git => 'git://github.com/rails/ssl_requirement.git'
plugin 'validate_attributes', :git => "git://github.com/jbasdf/validate_attributes.git"

#====================
# gems 
#====================
gem 'muck-engine', :lib => 'muck_engine'
gem 'muck-users', :lib => 'muck_users'
gem 'jrails'
gem 'authlogic'
gem 'searchlogic'
gem 'will_paginate'
gem 'bcrypt-ruby', :lib => 'bcrypt', :version => '>=2.1.1'
gem 'paperclip'
gem 'friendly_id'
gem "action_mailer_tls", :lib => 'smtp_tls' # This is only require for installations that have ruby 1.8.6.  If you are running Ruby 1.8.7 you may comment this out and remove require "smtp_tls" from smtp_gmail.rb
gem "recaptcha", :lib => "recaptcha/rails"

# Install gems on local system
rake('gems:install', :sudo => true) if install_gems 
rake('gems:unpack:dependencies') if unpack_gems


#==================== 
# Install and configure capistrano 
#====================
run "sudo gem install capistrano" if install_capistrano

#==================== 
# Add rake tasks
#====================
file_append 'Rakefile', <<-CODE
require 'muck_engine/tasks'
require 'muck_users/tasks'
CODE

#==================== 
# build application files 
#====================

file_inject 'config/environment.rb', "require File.join(File.dirname(__FILE__), 'boot')", <<-CODE

  require 'ostruct'
  require 'yaml'
  ::GlobalConfig = OpenStruct.new(YAML.load_file("\#{RAILS_ROOT}/config/global_config.yml")[RAILS_ENV])
CODE


file 'config/global_config.yml',
%Q{default: &DEFAULT
# All fields that need to be changed are marked with 'TODO'
default: &DEFAULT

  #
  # Replace #{domain_name} in this file with your website's domain name
  #

  # Global application values.  These are used to display the app name, send emails, and configure where system emails go.
  application_name: '#{app_name}'         # Common name for your application.  i.e. My App, Billy Bob, etc
  from_email: 'support@#{domain_name}'    # Emails will come from this address i.e. noreply@#{domain_name}, support@#{domain_name}, system@#{domain_name}, etc
  from_email_name: 'TODO Name'            # This will show up as the name on emails.  i.e. support@#{domain_name} <Example>
  support_email: 'support@#{domain_name}' # Support email for your application.  This is used for contact us etc.
  admin_email: 'admin@#{domain_name}'     # Admin email for your application
  customer_service_number: '1-800-'       # Phone number if you have one (optional)

  # Email charset.  No need to change this unless you have a good reason to change the encoding.
  mail_charset: 'utf-8'

  # Email server configuration
  # Sendgrid is easy: https://sendgrid.com/user/signup
  email_server_address: "smtp.sendgrid.net"     # Email server address.  This works for sendgrid
  email_user_name: 'TODO_admin@#{domain_name}'  # Email server username
  email_password: 'TODO_password'               # Email server password
  base_domain: '#{domain_name}'                 # Basedomain that emails will come from

  # sign up options
  automatically_activate: true                    # Automatically active a users account during registration. If true the user won't get a 
                                                  # 'confirm account' email. If false then the user will need to confirm their account via an email.
  automatically_login_after_account_create: true  # Automatically log the user in after they have setup their account. This should be false if you 
                                                  # require them to activate their account.
  send_welcome: true                              # Send out a welcome email after the user has signed up.

  # if you use recaptcha you will need to also provide a public and private
  # key available from http://recaptcha.net.
  use_recaptcha: false                            # This will turn on recaptcha during registration. This is an alternative to sending the 
                                                  # user a confirm email and can help reduce spam registrations.
  recaptcha_pub_key: GET_A_RECAPTCHA_KEY(TODO)    # key available from http://recaptcha.net
  recaptcha_priv_key: GET_A_RECAPTCHA_KEY(TODO)

  # jgrowl related settings
  growl_enabled: false    # If true then notifications and errors will popup in an overlay div similar to 'growl' on the mac.

  # application configuration
  let_users_delete_their_account: false  # Turn on/off ability for users to delete their own account. It is not recommended that you let 
                                         # users delete their own accounts since the delete can cascade through the system with unknown results.

  # ssl
  enable_ssl: false # Enable ssl if you have an ssl certificate installed.  This will provide security between the client and server.

  # keys
  hoptoad_key: '' # Get a hoptoad key - https://hoptoadapp.com/account/new

  # Google Analtyics Configuration.  This will enable Google Analytics on your site and will be used if your template includes:
  #                                  <%= render :partial => 'layouts/global/google_analytics' %>
  google_tracking_code: ""                    # Get a tracking code here: http://www.google.com/analytics/. The codes look like this: 'UA-9685000-0'
  google_tracking_set_domain: "#{domain_name}"   # Base domain provided to Google Analytics. Useful if you are using subdomains but want all traffic 
                                              # recorded into one account.

  #
  # The settings below configure the various engines that provide extra functionality to the application.
  #

  # Services Configuration
  inform_admin_of_global_feed: true   # If true then the 'admin_email' will recieve an email anytime a global feed (one that is not 
                                      # attached to any object) is added.
  # These settings apply to the toolbar which can be seen here: http://www.folksemantic.com/visits/53879
  enable_services_comments: true      # Enables or disables comments in the frame that wraps content as a user browses recommendation results
  enable_services_shares: true        # Enables or disables sharing in the frame that wraps content as a user browses recommendation results

  # Amazon service settings.  These are only needed if you wish to let a user add their Amazon Wishlist as an identity service
  amazon_secret_access_key: ''        # Amazon access key.  Get this from your Amazon services account: http://aws.amazon.com/
  amazon_access_key_id: ''            # Amazon key id.  Get this from your Amazon services account: http://aws.amazon.com/
  amazon_associate_tag: 'amzfeeds-20' # Amazon associate tag.  Not required.  This will be added to amazon feeds if present.
  ecs_to_rss_wishlist: "http://www.#{domain_name}/ecs_to_rss-wishlist.xslt" # xslt file that can transform xml from Amazon.  This file is found in /public/ecs_to_rss-wishlist.xslt and so changing #{domain_name} to you domain will make this work.

  google_ajax_api_key: ''                 # get a Google ajax api key: http://code.google.com/apis/ajaxsearch/signup.html
  google_ajax_referer: 'www.#{domain_name}'  # The website making requests to google.
  show_google_search: true                # Determines whether or not a google search is displayed on the topic page
  load_feeds_on_server: false             # Determines whether feeds on a topic page are loaded on the server or the client.  Loading on the server can take a while
  combine_feeds_on_server: false          # Combines feeds loaded on the server

  # Geo Kit Configuration
  # TODO make sure the google_ajax_api_key from above can be used with geokit.  If it can then refactor and remove google_geo_key in favor of just using a single key.
  google_geo_key: '' # Get google key from http://www.google.com/apis/maps/signup.html
  yahoo_geo_key: '' # Get yahoo key from http://developer.yahoo.com/maps/rest/V1/geocode.html

  # Oauth Configuration
  # Oauth permits access to a user's account on remote servers.  For example, instead of asking for a user's Twitter username and password
  # the system can obtain access via Oauth and then make posts on behave of the user.
  twitter_oauth_key: ''     # Get twitter credentials here: http://twitter.com/apps
  twitter_oauth_secret: ''

  # Contents Configuration
  git_repository: ''                  # Not currently used.  Eventually this will be the path to a git repository that the content system uses to store revisions.
  content_git_repository: false       # Should be set to false as git integration is not currently working.
  enable_auto_translations: false     # If true then all content objects will automatically be translated into all languages supported by Google Translate
  content_enable_solr: true           # Enables solr for the content system.  If you are using solr then set this to true.  If you do not wish to setup and manage solr 
                                      # then set this value to false (but search will be disabled).
  content_css: ['/stylesheets/reset.css', '/stylesheets/styles.css'] # CSS files that should be fed into the tiny_mce content editor.  
                                      # Note that Rails will typically generate a single all.css stylesheet.  Setting the stylesheets here let's 
                                      # the site administrator control which css is present in the content editor and thus which css an end 
                                      # user has access to to style their content.

  # Blogs Configuration
  enable_post_activities: true    # If the activity system is installed then setting this to true will add an activity to the user's activity 
                                  # feed each time they make a post.  If the activity system is not install then this value should be false.

  # Friend Configuration
  # The friend system provides a hybrid friend/follow model.  Either mode can be turned off or both can be enabled
  # If only following is enabled then users will be provided the ability to follow, unfollow, and block
  # If only friending is enabled then users will be provided a 'friend request' link and the ability to accept friend requests
  # If both modes are are enabled then users will be able to follow other users.  A mutual follow results in 'friends'.  An unfollow 
  # leaves the other party as just a follower.
  # Note that at least one mode must be enabled. 
  enable_following: true          # Turn on 'following'.  This is similar to the 'follow' functionality on Twitter in that it let's users watch one 
                                  # another's activities without having explicit permission from the user.  A mutual follow essentially becomes a
                                  # friendship.
  enable_friending: false         # Turn on friend system.
  enable_friend_activity: true    # If true then friend related activity will show up in the activity feed.  Requires muck-activities gem

  # Activity Configuration
  enable_live_activity_updates: true  # Turns on polling inside the user's activity feed so they constantly get updates from the site
  live_activity_update_interval: 60   # time between updates to live activity feed in seconds
  enable_activity_comments: true      # Turn on comments in the activity feed
  enable_activity_file_uploads: true  # Turn on file uploads in the activity feed.  Requires that uploader be installed.
  enable_activity_image_uploads: true # Turn on image uploads in the activity feed.  Requires that uploader be installed.
  enable_activity_video_sharing: true # Turn on video sharing in the activity feed.

  # Theme Configuration
  use_domain_for_themes: false  # If the disguise gem is installed it is possible to change the 'theme' or look of the site based on the current domain.

#
# Provide settings specific to each environment below.  For example, in production application_url will be a real domain name
# while in development application_url will typically be something like 'localhost:3000'
#
production:
  <<: *DEFAULT
  content_css: ['/stylesheets/all.css']
  # Sent in emails to users
  application_url: 'www.#{domain_name}'

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
    
  protected
  
  # called by Admin::Muck::BaseController to check whether or not the
  # user should have access to the admin UI
  def admin_access?
    access_denied unless admin?
  end
  
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
%q{<title><%= @page_title || GlobalConfig.application_name %></title>
<meta http-equiv="content-type" content="text/xhtml; charset=utf-8" />
<meta http-equiv="imagetoolbar" content="no" />
<meta name="distribution" content="all" />
<meta name="robots" content="all" />
<meta name="resource-type" content="document" />
<meta name="MSSmartTagsPreventParsing" content="true" />
<%= stylesheet_link_tag 'blueprint/print.css', :media => "print" %>
<!--[if IE]><link rel="stylesheet" href="/stylesheets/blueprint/ie.css" type="text/css" media="screen, projection"><![endif]-->
<%= stylesheet_link_tag %W{ reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame }, :cache => true %>
<%= stylesheet_link_tag 'default' %>
<%= javascript_include_tag %w{
            jquery/jquery.js
            jquery/jquery-ui.js
            jquery/jrails.js
            jquery/jquery.jgrowl.js
            jquery/jquery.tips.js
            jquery/jquery.easing.js
            jquery/jquery.fancybox.js
            muck.js
            application.js }, :cache => 'all_js_cached' %>
<%= javascript_tag %[var AUTH_TOKEN = #{form_authenticity_token.inspect};] if protect_against_forgery? %>
<%= yield :head -%>
<link rel="shortcut icon" href="/images/favicon.ico" type="image/x-icon">
<link rel="icon" type="image/vnd.microsoft.icon" href="/images/favicon.ico">}

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
  config.api_key = GlobalConfig.hoptoad_key
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

initializer 'smtp.rb',
%Q{unless Rails.env.test? # we don't want tests attempting to send out email
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :address => GlobalConfig.email_server_address,
    :port => 25,
    :authentication => :plain,
    :enable_starttls_auto => true,
    :user_name => GlobalConfig.email_user_name,
    :password => GlobalConfig.email_password,
    :domain => GlobalConfig.base_domain
  }
  # ActionMailer::Base.smtp_settings = {
  #   :address => "smtp.gmail.com",
  #   :port => 587,
  #   :authentication => :plain,
  #   :enable_starttls_auto => true,
  #   :user_name => GlobalConfig.email_user_name,
  #   :password => GlobalConfig.email_password,
  #   :domain => GlobalConfig.base_domain
  # }
end

ActionMailer::Base.default_url_options[:host] = GlobalConfig.application_url
}

#==================== 
# Build custom application files
#====================

file 'app/models/user.rb',
%Q{class User < ActiveRecord::Base
  
  acts_as_authentic
  acts_as_muck_user
    
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
    params.each_pair do |k,v|
      if !['authenticity_token', 'action', 'controller'].include?(k) 
        body << "#{k}: #{v}"
      end
    end
    BasicMailer.deliver_mail(:subject => I18n.t("contact.contact_response_subject", :application_name => GlobalConfig.application_name), :body=>body.join("\n"))
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

	<% form_tag('/contact', :id => "contact_form") do -%>
	
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

#==================== 
# General Setup
#==================== 
run "script/generate friendly_id"

timestamp = (Time.now + 5.seconds).utc.strftime("%Y%m%d%H%M%S") # HACK stole this from rails migration script
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
rake('muck:engine:sync')
rake('muck:users:sync')

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
vendor/rails
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
