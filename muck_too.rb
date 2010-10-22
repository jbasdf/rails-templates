require 'ruby-debug'

def file_append(file, data)
  log 'file_append', file
  append_file(file, data)
end

def file_inject(file_name, sentinel, string, before_after = :after)
  log 'file_inject', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match}\n#{string}"
    else
      "#{string}\n#{match}"
    end
  end
end

def file_insert(file_name, sentinel, string, before_after = :after)
  log 'file_insert', file_name
  gsub_file file_name, /(#{Regexp.escape(sentinel)})/mi do |match|
    if :after == before_after
      "#{match} #{string} "
    else
      " #{string} #{match}"
    end
  end
end

def file_replace(file_name, string, replace)
  gsub_file file_name, /(#{Regexp.escape(string)})/mi do |match|
    "#{replace}"
  end
end


install_everything = true if yes?('Install everything? (y/n)')
if !install_everything
  install_muck_blogs = true if yes?('Install blog system? (Muck Blogs) (y/n)')
  install_muck_content = true if yes?('Install content system (Muck Content)? (y/n)')
  install_muck_profiles = true if yes?('Install profile system (Muck Profiles)? (y/n)')
  install_muck_raker = true if yes?('Muck Raker? (y/n)')
  install_muck_services = true if yes?('Muck Services? (y/n)')
  install_muck_shares = true if yes?('Install muck shares (Muck Shares)? (y/n)')
  install_muck_activity = true if yes?('Install activity system (Muck Activities)? (y/n)')
  install_muck_friends = true if yes?('Install friends system (Muck Friends)? (y/n)')
  install_muck_invites = true if yes?('Install invite system (Muck Invites)? (y/n)')
  install_file_uploads = true if yes?('Install file uploads? (y/n)')
  install_cms_lite = true if yes?('Install CMS Lite? (y/n)')
  install_solr = true if yes?('Install Acts As Solr (Muck Solr)? (y/n)')
  install_disguise = true if yes?('Install disguise theme engine? (y/n)')
  install_muck_comments = true if yes?('Install comment engine (Muck Comments)?  This is required for the muck activity engine. (y/n)')
  install_tagging = true if yes?('Install Tagging? (y/n)')
  install_babelphish = true if yes?('Install Translations (babelphish - recommended)? (y/n)')
  install_geokit = true if yes?('Install Geokit? (y/n)')
  install_sms = true if yes?('Install SMS support? (y/n)')
  #install_muck_oauth = true if yes?('Install Muck Oauth? (y/n)') # Depricated
  install_muck_auth = true if yes?('Install Muck Auth? (y/n)')
  
  # Deal with dependencies
  install_muck_shares ||= install_muck_raker
  install_muck_activity ||= install_muck_shares
  install_muck_content ||= install_muck_blogs
  install_muck_profiles ||= install_muck_activity
  install_solr ||= install_muck_content
  install_muck_comments ||= install_muck_activity || install_muck_blogs || install_muck_raker
  install_tagging ||= install_muck_content
  install_babelphish ||= install_muck_content
  install_file_uploads ||= install_muck_content
  install_geokit ||= install_muck_profiles

  domain_name = ask("What domain name would you like for your application? (Yes I need it again. ie example.com)")
end

installed_gems = []

#====================
# Geokit
#====================
if install_geokit
  gem 'geokit'
  plugin 'geokit-rails', :git => "git://github.com/andre/geokit-rails.git"
  
  file_inject 'config/initializers/geokit_config.rb', "default: &DEFAULT", <<-CODE
  require 'geokit'
  CODE
  
  file_inject 'vendor/plugins/geokit-rails/init.rb', "default: &DEFAULT", <<-CODE
  require 'geokit'
  CODE
  
  file_replace 'config/initializers/geokit_config.rb', "'REPLACE_WITH_YOUR_YAHOO_KEY'", <<-CODE
  Secrets.yahoo_geo_key # http://developer.yahoo.com/faq/index.html#appid
  
  CODE
  
  file_replace 'config/initializers/geokit_config.rb', "'REPLACE_WITH_YOUR_GOOGLE_KEY'", <<-CODE
  Secrets.google_geo_key # http://www.google.com/apis/maps/signup.html  
  
  CODE
  
  file_inject 'config/secrets.yml', "default: &DEFAULT", <<-CODE
  # Geo Kit Configuration
  # TODO make sure the google_ajax_api_key from above can be used with geokit.  If it can then refactor and remove google_geo_key in favor of just using a single key.
  # Get google key from http://www.google.com/apis/maps/signup.html
  google_geo_key: ''
  
  # Get yahoo key from http://developer.yahoo.com/maps/rest/V1/geocode.html
  yahoo_geo_key: ''
  CODE
  
  puts 'Look in secrets.yml for the urls where you can aquire the keys for the yahoo and google key required to make geo coding work.'
end

#====================
# SMS fu
#====================
if install_sms
  plugin 'sms-fu', :git => "git://github.com/brendanlim/sms-fu.git"
end

#====================
# babelphish
#====================
if install_babelphish || install_everything
  gem 'babelphish'
  installed_gems << 'babelphish'
end

#====================
# muck solr
#====================
if install_solr || install_everything
  gem 'muck-solr', :require => 'acts_as_solr'
  # TODO add code to install solr config files
  # TODO muck-solr requires muck_raker.rb to be installed in initializers.
  # that file should probably be setup by a rake task in muck-solr and be
  # called muck_solr.rb NOT muck_raker.rb
  installed_gems << 'muck-solr'
end

#====================
# muck raker
#====================
if install_muck_raker || install_everything
  gem 'muck-raker'
  
  installed_gems << 'muck-raker'
  
end

#====================
# muck services
#====================
if install_muck_services || install_everything
  
  gem 'muck-services'
  gem 'hpricot'
  gem "muck-feedbag", :require => 'feedbag'

  file_inject 'config/secrets.yml', "default: &DEFAULT", <<-CODE
  # Amazon service settings.  These are only needed if you wish to let a user add their Amazon Wishlist as an identity service
  amazon_secret_access_key: ''        # Amazon access key.  Get this from your Amazon services account: http://aws.amazon.com/
  amazon_access_key_id: ''            # Amazon key id.  Get this from your Amazon services account: http://aws.amazon.com/
  amazon_associate_tag: 'amzfeeds-20' # Amazon associate tag.  Not required.  This will be added to amazon feeds if present.  
  
  google_ajax_api_key: ''                 # get a Google ajax api key: http://code.google.com/apis/ajaxsearch/signup.html
  CODE
  
  file_append 'config/initializers/muck.rb', <<-CODE
  MuckServices.configure do |config|    
    # Services Configuration
    config.inform_admin_of_global_feed = true   # If true then the 'admin_email' will recieve an email anytime a global feed (one that is not 
                                                # attached to any object) is added.
    # These settings apply to the toolbar which can be seen here: http://www.folksemantic.com/visits/53879
    config.enable_services_comments = true      # Enables or disables comments in the frame that wraps content as a user browses recommendation results
    config.enable_services_shares = true        # Enables or disables sharing in the frame that wraps content as a user browses recommendation results

    config.ecs_to_rss_wishlist = "http://www.#{domain_name}/ecs_to_rss-wishlist.xslt" # xslt file that can transform xml from Amazon.  This file is found in /public/ecs_to_rss-wishlist.xslt and so changing #{domain_name} to you domain will make this work.

    config.google_ajax_referer = 'www.#{domain_name}'  # The website making requests to google.
    config.show_google_search = true                # Determines whether or not a google search is displayed on the topic page
    config.load_feeds_on_server = false             # Determines whether feeds on a topic page are loaded on the server or the client.  Loading on the server can take a while
    config.combine_feeds_on_server = false          # Combines feeds loaded on the server
  end
  CODE
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-raker
  CODE
  
  installed_gems << 'muck-services'
  
  file_inject 'app/views/layouts/global/_head.html.erb', "muck.js", <<-CODE
  muck_services.js
  CODE
  
end

#====================
# muck auth
#====================
if install_muck_auth || install_everything
  gem 'muck-auth'

  file_inject 'config/secrets.yml', "default: &DEFAULT", <<-CODE
  oauth_credentials:
    twitter: # Twitter api access: http://www.twitter.com/apps 
      key: ''
      secret: ''
    linked_in: # Linked In api access: https://www.linkedin.com/secure/developer
      key: ""
      secret: ""
    facebook: # Use the Facebook Developer app, create an app and get the key and secret.
      key: ''
      secret: ''    
  CODE
  
end

#====================
# muck oauth
#====================
# This gem has been depricated in favor of muck-auth
# if install_muck_oauth || install_everything
#   gem 'muck-oauth'
#     
#   file_inject 'config/secrets.yml', "default: &DEFAULT", <<-CODE
#   # Oauth
#   # Twitter api access: http://www.twitter.com/apps 
#   twitter_oauth_key: ""
#   twitter_oauth_secret: ""
# 
#   # Google api access: http://code.google.com/apis/accounts/docs/RegistrationForWebAppsAuto.html#register
#   google_oauth_key: ""
#   google_oauth_secret: ""
# 
#   # Yahoo api access: http://developer.yahoo.com/flickr/
#   # yahoo_oauth_key: ""
#   # yahoo_oauth_secret: ""
# 
#   # Flick api access: http://www.flickr.com/services/apps/create/apply
#   # flickr_oauth_key: ""
#   # flickr_oauth_secret: ""
# 
#   # Linked In api access: https://www.linkedin.com/secure/developer
#   linkedin_oauth_key: ""
#   linkedin_oauth_secret: ""
# 
#   # Friendfeed api access: https://friendfeed.com/account/login?next=%2Fapi%2Fregister
#   friendfeed_oauth_key: ""
#   friendfeed_oauth_secret: ""  
# 
#   # Fire Eagle api access: https://fireeagle.yahoo.net/developer/manage
#   # fireeagle_oauth_key: "" 
#   # fireeagle_oauth_secret: ""
#   CODE
#     
#   installed_gems << 'muck-oauth'
# end

#====================
# muck comments
#====================
if install_muck_comments || install_everything

  # nested set is required for comments
  gem "nested_set"
  gem "sanitize"
  gem "muck-comments", ">=3.0.2"
  
  file 'app/models/comment.rb', <<-CODE
  class Comment < ActiveRecord::Base
    
    include MuckComments::Models::MuckComment
    
    # TODO polish the add to activity for comment
    def after_create
      # if !self.commentable.is_a?(Activity) # don't add comments to the activity feed that are comments on the items in the activity feed.
      content = I18n.t('muck.comments.new_comment')
      add_activity(self, self, self, 'comment', '', content)
    end
  
    def self.between_users user1, user2
      find(:all, {
        :order => 'created_at asc',
        :conditions => [
          "(user_id=? and commentable_id=?) or (user_id=? and commentable_id=?) and commentable_type='User'",
          user1.id, user2.id, user2.id, user1.id]
          })
    end

  end
  CODE

  file 'app/controllers/comments_controller.rb', <<-CODE
  class CommentsController < Muck::CommentsController
    
    before_filter :login_required # require the user to be logged in to make a comment
    
    # Modify this method to change how permissions are checked to see if a user can comment.
    # Each model that implements 'include MuckComments::Models::MuckComment' can override can_comment? to 
    # change how comment permissions are handled.
    def has_permission_to_comment(user, parent)
      parent.can_comment?(user)
    end
    
  end
  CODE

  file_inject 'config/routes.rb', "root :to => \"default#index\"", <<-CODE
  resources :comments
  CODE
  
  installed_gems << 'muck-comments'
end

#====================
# muck blogs
#====================
if install_muck_blogs || install_everything
  gem 'muck-blogs'
    
  file_append 'config/initializers/muck.rb', <<-CODE
  MuckBlogs.configure do |config|
    # Blogs Configuration
    enable_post_activities = true   # If the activity system is installed then setting this to true will add an activity to the user's activity 
                                    # feed each time they make a post.  If the activity system is not install then this value should be false.
  end
  CODE

  file 'app/models/blog.rb', <<-CODE
  class Blog < ActiveRecord::Base
    include MuckBlogs::Models::Blog
  end
  CODE

  installed_gems << 'muck-blogs'
  
end

#====================
# muck content engine
#====================
if install_muck_content || install_everything
  gem 'muck-contents'
  gem 'tiny_mce'
    
  file_append 'config/initializers/muck.rb', <<-CODE
  MuckContents.configure do |config|
    # Contents Configuration
    git_repository = ''                  # Not currently used.  Eventually this will be the path to a git repository that the content system uses to store revisions.
    content_git_repository = false       # Should be set to false as git integration is not currently working.
    enable_auto_translations = false     # If true then all content objects will automatically be translated into all languages supported by Google Translate
    content_enable_solr = true           # Enables solr for the content system.  If you are using solr then set this to true.  If you do not wish to setup and manage solr 
                                         # then set this value to false (but search will be disabled).
    content_css = ['/stylesheets/reset.css', '/stylesheets/styles.css'] # CSS files that should be fed into the tiny_mce content editor.  
                                                                        # Note that Rails will typically generate a single all.css stylesheet.  Setting the stylesheets here let's 
                                                                        # the site administrator control which css is present in the content editor and thus which css an end 
                                                                        # user has access to to style their content.
  end
  CODE
  
  file 'app/models/content.rb', <<-CODE
  class Content < ActiveRecord::Base
    include MuckContents::Models::MuckContent
  end
  CODE
  
  file 'app/models/content_translation.rb', <<-CODE
  class ContentTranslation < ActiveRecord::Base
    include MuckContents::Models::MuckContentTranslation
  end
  CODE
  
  file 'app/models/content_permission.rb', <<-CODE
  class ContentPermission < ActiveRecord::Base
    include MuckContents::Models::MuckContentPermission
  end
  CODE
  
  file 'app/controllers/contents_controller.rb', <<-CODE
  class ContentsController < Muck::ContentsController
  end
  CODE
  
  file_inject 'config/routes.rb', "ActionController::Routing::Routes.draw do |map|", <<-CODE
  resources :contents
  CODE
  
  installed_gems << 'muck-contents'
end

#====================
# muck profile engine
#====================
if install_muck_profiles || install_everything
  gem 'muck-profiles'
    
  file 'app/models/profile.rb', <<-CODE
  class Profile < ActiveRecord::Base
    include MuckProfiles::Models::MuckProfile
  end
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  include MuckProfiles::Models::MuckUser
  CODE
  
  file_append 'config/initializers/muck.rb', <<-CODE
  MuckProfiles.configure do |config|
    config.enable_solr = true           # This enables or disables acts as solr for profiles.
    config.enable_guess_location = true # If true the profile system will attempt to determine the user's location via IP and populated with the location, lat and lon fields.
    config.policy = { :public => [:login, :first_name, :last_name, :about],
                       :authenticated => [:location, :city, :state_id, :country_id, :language_id],
                       :friends => [:email],
                       :private => [] }
    
  end
  CODE
  
  installed_gems << 'muck-profiles'
end

#====================
# muck activity engine
#====================
if install_muck_activity || install_everything
  gem 'muck-activities'

  file_append 'config/initializers/muck.rb',  <<-CODE
  MuckActivities.configure do |config|
    config.enable_activity_comments = true     # Enable if you would like to enable comments for your project's activities feeds
    config.enable_live_activity_updates = true # Turns on polling inside the user's activity feed so they constantly get updates from the site
    config.live_activity_update_interval = 60  # Time between updates to live activity feed in seconds
                                               # Note that this will poll the server every 60 seconds and so will increase server load and bandwidth usage.
    config.enable_activity_shares = true       # Turn on shares in the activity feed

    # You can also use the 'contribute' helper method to render a richer status update if you have uploader installed and configured:
    config.enable_activity_file_uploads = true # Turn on file uploads in the activity feed.  Requires that uploader be installed.
    config.enable_activity_image_uploads = true # Turn on image uploads in the activity feed.  Requires that uploader and muck_albums be installed.
    config.enable_activity_video_sharing = true # Turn on video sharing in the activity feed.
  end
  CODE
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-activities
  CODE
  
  file 'app/models/activity.rb', <<-CODE
  class Activity < ActiveRecord::Base
    include MuckActivities::Models::Activity
  end
  CODE
  
  # file_inject 'app/views/layouts/global/_head.html.erb', "muck.js", <<-CODE
  # muck_activities.js
  # CODE
  
  installed_gems << 'muck-activities'
end

#====================
# muck friends engine
#====================
if install_muck_friends || install_everything
  gem 'muck-friends'
    
  file_append 'config/initializers/muck.rb',  <<-CODE
  MuckFriends.configure do |config|
    # Friend Configuration
    # The friend system provides a hybrid friend/follow model.  Either mode can be turned off or both can be enabled
    # If only following is enabled then users will be provided the ability to follow, unfollow, and block
    # If only friending is enabled then users will be provided a 'friend request' link and the ability to accept friend requests
    # If both modes are are enabled then users will be able to follow other users.  A mutual follow results in 'friends'.  An unfollow 
    # leaves the other party as just a follower.
    # Note that at least one mode must be enabled.
    allow_following = true          # Turn on 'following'.  This is similar to the 'follow' functionality on Twitter in that it let's users watch one 
                                    # another's activities without having explicit permission from the user.  A mutual follow essentially becomes a
                                    # friendship.
    enable_friending = true         # Turn on friend system.
    enable_friend_activity = true   # If true then friend related activity will show up in the activity feed.  Requires muck-activities gem
  end
  CODE

  file 'app/models/friend.rb', <<-CODE
  class Friend < ActiveRecord::Base
    include MuckFriends::Models::Friend
  end
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  include MuckFriends::Models::MuckUser
  CODE
  
  file 'app/mailers/friend_mailer.rb',
  %Q{class FriendMailer < ActionMailer::Base
    include MuckFriends::Mailers::FriendMailer
  end
  }
  
  installed_gems << 'muck-friends'
end

#====================
# cms lite
#====================
if install_cms_lite
  gem 'cms-lite', :require => 'cms_lite'
    
  installed_gems << 'cms-lite'
end

#====================
# disguise
#====================
if install_disguise || install_everything
  gem 'disguise'
  
  file 'app/controllers/admin/themes_controller.rb', <<-CODE
  class Admin::ThemesController < Admin::Disguise::ThemesController
    before_filter :login_required
    layout 'admin'
  end
  CODE
  
  file 'app/controllers/admin/domain_themes_controller.rb', <<-CODE
  class Admin::DomainThemesController < Admin::Disguise::DomainThemesController
    before_filter :login_required
    layout 'admin'
  end
  CODE
  
  initializer 'disguise.rb', <<-CODE
  Disguise.configure do |config|
    config.use_domain_for_themes = false  # If the disguise gem is installed it is possible to change the 'theme' or look of the site based on the current domain.
                                          # Themes can be set in the admin UI or determined at run time by the domain name.
    config.themes_enabled = true          # Turns the theme engine on and off.  If false then only the views in the standard app directory will be used.

    # These options are also available to configure disguise.  In most cases the defaults should work fine.
    config.theme_full_base_path =  File.join(::Rails.root.to_s, 'themes') # Full path to the themes folder. The examples puts themes in a directory called 'themes' in the Rails app root.
  CODE
  
  rake('disguise:setup')
  
  installed_gems << 'disguise'
  
end


#====================
# uploader
#====================
if install_file_uploads || install_everything
  
  gem 'uploader'
    
  initializer 's3_credentials.rb', <<-CODE
  # This keeps the developers from having to have the Amazon keys on their machines
  s3_file = "\#{::Rails.root}/config/s3.yml"
  if File.exist?(s3_file)
    AMAZON_S3_CREDENTIALS = s3_file
  else
    AMAZON_S3_CREDENTIALS = { 
      :access_key_id => '',
      :secret_access_key => ''
    }
  end
  CODE
  
  
  file 'app/models/upload.rb', <<-CODE
  class Upload < ActiveRecord::Base
  
    include Uploader::Models::Upload
    
    validates_attachment_presence :local
    validates_attachment_size :local, :less_than => 10.megabytes
    
  end
  CODE
  
  installed_gems << 'uploader'
  
  rake('uploader:sync')
end

#====================
# muck shares
#====================
if install_muck_shares || install_everything
  gem 'muck-shares'
  
  file 'app/models/share.rb', <<-CODE
  class Share < ActiveRecord::Base
    include MuckShares::Models::MuckShare
  end
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  include MuckShares::Models::MuckSharer
  CODE
  
  installed_gems << 'muck-shares'
end

#====================
# muck invites
#====================
if install_muck_invites || install_everything
  
  gem 'muck-invites'
  
  file_insert 'app/views/layouts/global/_head.html.erb', "reset blueprint/liquid_screen.css jquery/jquery.fancybox.css styles frame", <<-CODE
  muck-invites
  CODE
  
  file_inject 'app/models/user.rb', 'class User < ActiveRecord::Base', <<-CODE
  include MuckInvites::Models::MuckInviter
  CODE
  
  file 'app/models/invite.rb', <<-CODE
  class Invite < ActiveRecord::Base
    include MuckInvites::Models::MuckInvite 
  end
  CODE
  
  file 'app/models/invitee.rb', <<-CODE
  class Invitee < ActiveRecord::Base
    include MuckInvites::Models::MuckInvitee
  end
  CODE
    
  installed_gems << 'muck-invites'
  
end


#====================
# muck.rake
#====================
file 'lib/tasks/muck.rake', <<-CODE
require 'fileutils'

namespace :muck do
    
  desc 'Translate app'
  task :translate => :environment do
    puts 'translating'
    system("babelphish -o -y #{::Rails.root.to_s}/config/locales/en.yml")
  end

end
CODE

#====================
# tagging
#====================
if install_tagging || install_everything
  gem 'acts-as-taggable-on'
  file_inject('app/helpers/application_helper.rb', 'module ApplicationHelper', 'include ActsAsTaggableOn::TagsHelper')
  file_inject('app/models/user.rb', 'class User < ActiveRecord::Base', 'acts_as_tagger')
  run "rails generate acts_as_taggable_on:migration"
end

#====================
# Sync in assets from the gems
#====================
rake('muck:sync')

#====================
# Run any needed migrations
#====================
rake('db:migrate')


puts "================================================================================"
puts "SUCCESS!"
puts "================================================================================"
puts "To populate the database with feeds and defaults for raker run: "
puts " rake muck:db:populate"
puts ""
puts "Or to populate the database with only the defaults and no feeds run: "
puts " rake muck:services:db:bootstrap_services"
puts ""
puts "Update existing default data with defaults specific to muck raker"
puts " rake muck:services:db:populate "
