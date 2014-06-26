source 'https://rubygems.org'

# Regular gems
gem 'rails',             '3.0.7'
gem 'resque',            '1.25.2'
gem 'system-timer19'
gem 'daemon_controller', '0.2.5'
gem 'json',              '1.8.1'

platforms :mri_18 do
  gem "oniguruma", :require => 'oniguruma'
end

gem 'chronic',           '0.2.3'
gem 'memcache-client',              :require => 'memcache'
gem 'mime-types',                   :require => 'mime/types'
gem 'rest-client',                  :require => 'rest_client'
gem 'rubyzip',           '1.1.4'
gem 'zip-zip',                      :require => 'zip/zip'
gem 'libxml-ruby',       '=2.7.0',  :require => 'xml/libxml'
gem 'daemons'
gem 'rdoc'
gem 'thor' # for imports
gem 'puma' # faster development server
gem 'rchardet19'

group :development do
  gem 'mysql'           # in production: apt-get install libmysql-ruby
end

group :test do
  gem 'webmock'
  gem 'rspec-rails',     '>= 2.0.1'
  gem 'machinist'
  gem 'faker'
end
