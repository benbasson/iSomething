source 'https://rubygems.org'

ruby '3.4.8'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'haml'
gem 'json'
gem 'activesupport'
gem 'feedjira'
gem 'redcarpet'
gem 'andand'
gem 'rack-contrib'
gem 'logger'
gem 'puma'
gem 'httparty'

# to deal with cross-platform development issues, currently using forked variant
group :development do
  gem 'git-version-bump', :git => 'https://github.com/benbasson/git-version-bump.git', :branch => 'windows-compatibility', :platform => :mswin
end

group :development, :test do
  gem 'rackup'
  gem 'rspec'
  gem 'webmock'
end

group :production do
  gem 'newrelic_rpm'
end