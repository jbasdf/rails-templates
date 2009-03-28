app_name = ask("What do you want to call your application?")
domain_name = ask("What domain name would you like for your application? (ie example.com)")
install_tagging = true if yes?('Install Tagging?')
install_gems = true if yes?('Install gems on local system? (y/n)')
unpack_gems = true if yes?('Unpack gems into vendor directory? (y/n)')

#====================
# plugins 
#====================
plugin 'paperclip', :git => "git://github.com/thoughtbot/paperclip.git"
plugin 'hoptoad_notifier', :git => "git://github.com/thoughtbot/hoptoad_notifier.git"
plugin 'recaptcha', :git => "http://github.com/ambethia/recaptcha/tree/master"
plugin 'ssl_requirement', :git => 'git://github.com/rails/ssl_requirement.git'
plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git'
plugin 'jquery', :svn => "http://ennerchi.googlecode.com/svn/trunk/plugins/jrails"

plugin 'permalink_fu', :git => "git://github.com/technoweenie/permalink_fu.git" 
plugin 'acts-as-taggable-on', :git => "git://github.com/mbleigh/acts-as-taggable-on.git" if install_tagging

# muck engines
plugin 'muck_engine', :git => "git://github.com/jbasdf/muck_engine.git", :submodule => true
rake(':muck_engine:sync')

plugin 'muck_user_engine', :git => "git://github.com/jbasdf/muck_users_engine.git", :submodule => true
rake(':muck_users_engine:sync')

#====================
# gems 
#====================
gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'mislav-will_paginate', :lib => 'will_paginate', :source => 'http://gems.github.com'

# optional
# gem 'erubis'
# gem 'rubyist-aasm'
# gem 'ruby-openid', :lib => 'openid'
# gem 'simple-rss'
# gem 'fastercsv'
# gem 'activemerchant', :lib => 'active_merchant'
# gem 'aws-s3', :lib => 'aws/s3'
  
# Install gems on local system
rake('gems:install', :sudo => true) if install_gems 
rake('gems:unpack:dependencies') if unpack_gems

#==================== 
# Install and configure capistrano 
#====================
run "sudo gem install capistrano"

#==================== 
# build custom files 
#====================

file 'app/models/user.rb',
%Q{class User < ActiveRecord::Base
  
  acts_as_authenticated_user
  #{ 'acts_as_tagger' if install_tagging }
  
  has_permalink :login, :url_key

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

  def to_param
    self.url_key
  end

  def display_name
    h(self.login)
  end
  
end
}


file 'db/migrate/20090327231918_create_users.rb',
%Q{class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string   :login
      t.string   :email
      t.string   :first_name
      t.string   :last_name
      t.string   :crypted_password,          :limit => 40
      t.string   :salt,                      :limit => 40
      t.string   :remember_token
      t.datetime :remember_token_expires_at
      t.string   :activation_code,           :limit => 40
      t.datetime :activated_at
      t.string   :password_reset_code,       :limit => 40
      t.boolean  :enabled,                   :default => true
      t.boolean  :terms_of_service,          :default => false, :null => false
      t.string   :time_zone,                 :default => "UTC"
      t.datetime :created_at
      t.datetime :updated_at
      t.boolean  :is_active,                 :default => false
      t.string   :identity_url
      t.string   :url_key
    end

    add_index "users", ["login"], :name => "index_users_on_login"
    
  end

  def self.down
    drop_table :users
  end
end  
}


file 'config/environment.rb',
%Q{# Be sure to restart your server when you modify this file

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
  config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
  config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'

  # Only load the plugins named here, in the order given (default is alphabetical).
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


file 'config/global_config.yml',
%Q{default: &DEFAULT

  # Sent in emails to users
  application_name: '#{app_name}'

  # Email charset
  mail_charset: 'utf-8'

  automatically_activate: false
  send_welcome: true
  allow_anonymous_commenting: false
  automatically_login_after_account_create: true
  
  # if you use recaptcha you will need to also provide a public and private
  # key available from http://recaptcha.net.
  use_recaptcha: true
  recaptcha_pub_key: GET_A_RECAPTCHA_KEY(TODO)
  recaptcha_priv_key: GET_A_RECAPTCHA_KEY(TODO)
  
  growl: true 
  
  support_email: 'support@#{domain_name}.com'
  customer_service_number: '1-800-'
  
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
  
  layout 'default'
    
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  include HoptoadNotifier::Catcher
  
  filter_parameter_logging :password, :password_confirmation
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
   
  before_filter :set_body_class
  before_filter :login_from_cookie
  
  protected

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


file 'app/views/layouts/default.html.erb',
Q%{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
  	<head>
  		<title><%= @page_title || GlobalConfig.application_name %></title>
  		<meta http-equiv="content-type" content="text/xhtml; charset=utf-8" />
  		<meta http-equiv="imagetoolbar" content="no" />
  		<meta name="distribution" content="all" />
  		<meta name="robots" content="all" />	
  		<meta name="resource-type" content="document" />
  		<meta name="MSSmartTagsPreventParsing" content="true" />
  		<%= stylesheet_link_tag 'reset' %>
  		<%= stylesheet_link_tag 'styles' %>
  		<%= javascript_include_tag "jquery/jquery.js" %>
      <%= javascript_include_tag "jquery/jquery-ui.js" %>
      <%= javascript_include_tag "jquery/jrails.js" %>
      <%= javascript_include_tag "jquery/jquery.jgrowl.js" %>
      <%= javascript_include_tag "jquery/jquery.tips.js" %>
      <%= javascript_include_tag "application.js" %>
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


file, 'Capfile',
%Q{load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'  
}


file 'config/database.yml',
%q{<% PASSWORD_FILE = File.join(RAILS_ROOT, '..', '..', 'shared', 'config', 'dbpassword') %>
 
development:
  adapter: mysql
  database: <%= app_name %>_development
  username: root
  password:
  host: localhost
  encoding: utf8

test:
adapter: mysql
  database: <%= app_name %>_test
  username: root
  password:
  host: localhost
  encoding: utf8

staging:
  adapter: mysql
  database: <%= app_name %>_staging
  username: <%= app_name %>
  password: <%= File.read(PASSWORD_FILE).chomp if File.readable? PASSWORD_FILE %>
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock

production:
  adapter: mysql
  database: <%= app_name %>_production
  username: <%= app_name %>
  password: <%= File.read(PASSWORD_FILE).chomp if File.readable? PASSWORD_FILE %>
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


#==================== 
# remove default files 
#====================
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run 'rm public/images/rails.png'
run 'rm config/database.yml'
 

#==================== 
# Rake tasks
#==================== 
rake('db:sessions:create') # Use database (active record) session store
rake('acts_as_taggable:db:create')
rake('db:migrate')
# Generate OpenID authentication keys
rake('open_id_authentication:db:create')


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
git :init
git :add => '.'
git :commit => "-a -m 'Initial commit'"

# Initialize submodules
git :submodule => "init"
 
# Success!
puts "SUCCESS!"
puts "Search for 'TODO' to find specific items that need to be configured"