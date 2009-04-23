app_name = ask("What do you want to call your application?")
domain_name = ask("What domain name would you like for your application? (ie example.com)")
install_tagging = true if yes?('Install Tagging? (y/n)')
install_cms_lite = true if yes?('Install CMS Lite? (y/n)')
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
plugin 'open_id_authentication', :git => 'git://github.com/rails/open_id_authentication.git'
plugin 'jquery', :svn => "http://ennerchi.googlecode.com/svn/trunk/plugins/jrails"
plugin 'validation_reflection', :git => "git://github.com/redinger/validation_reflection.git"
#plugin 'permalink_fu', :git => "git://github.com/technoweenie/permalink_fu.git" 
plugin 'friendly_id', :git => "git://github.com/norman/friendly_id.git"

plugin 'cells', :git => "git://github.com/apotonick/cells.git"

plugin 'acts-as-taggable-on', :git => "git://github.com/mbleigh/acts-as-taggable-on.git" if install_tagging

# muck engines
plugin 'muck_engine', :git => "git://github.com/jbasdf/muck_engine.git", :submodule => true
rake('muck:base:sync')

plugin 'muck_users_engine', :git => "git://github.com/jbasdf/muck_users_engine.git", :submodule => true
rake('muck:users:sync')

plugin 'cms_lite', :git => "git://github.com/jbasdf/cms_lite.git ", :submodule => true if install_cms_lite
# setup directories for cms lite
run "mkdir content"
run "mkdir content/pages"
run "mkdir content/protected-pages"

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
  config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
  config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
  config.gem "authlogic"

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


def output_cms_lite(install_cms_lite)
  return if !install_cms_lite
  %Q{
  # uncomment this method if you would like to add directories to cms lite
  #def setup_cms_lite
    # this will be called by the cms lite plugin
    # prepend_cms_lite_path(File.join(RAILS_ROOT, 'content', 'help'))
  #end}  
end

file 'app/controllers/application_controller.rb',
%Q{class ApplicationController < ActionController::Base
  
  layout 'default'
    
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
   
  before_filter :set_body_class
  
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

  #{output_cms_lite(install_cms_lite)}
  private
  def set_body_class
    @body_class ||= "body"
  end 

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


file 'Capfile',
%Q{load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
load 'config/deploy'  
}


file 'config/database.yml',
%Q{development:
  adapter: mysql
  database: #{app_name}_development
  username: root
  password:
  host: localhost
  encoding: utf8

test:
  adapter: mysql
  database: #{app_name}_test
  username: root
  password:
  host: localhost
  encoding: utf8

staging:
  adapter: mysql
  database: #{app_name}_staging
  username: #{app_name}
  password: 
  host: localhost
  encoding: utf8
  socket: /var/lib/mysql/mysql.sock

production:
  adapter: mysql
  database: #{app_name}_production
  username: #{app_name}
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
# Setup database
#==================== 

# make the db
rake('db:create:all')

# create sessions
rake('db:sessions:create') # Use database (active record) session store

# Generate OpenID authentication keys
rake('open_id_authentication:db:create')

# initial migration
rake('db:migrate')
rake('db:test:prepare')


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


def add_cms_lite_routes(install_cms_lite)
  return if !install_cms_lite
  %q{map.content '/content/*content_page', :controller => 'cms_lite', :action => 'show_page'
  map.protected_page '/protected/*content_page', :controller => 'cms_lite', :action => 'show_protected_page'}
end

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
  
  #{add_cms_lite_routes(install_cms_lite)}

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
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
  if install_cms_lite
    inside ('vendor/plugins/cms_lite') do
      run "git remote add my git@github.com:jbasdf/cms_lite.git"
    end
  end
end
 
# Success!
puts "SUCCESS!"
puts "Search for 'TODO' to find specific items that need to be configured"