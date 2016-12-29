source 'https://rubygems.org'

gem 'sinatra'
gem 'sinatra-contrib'
gem 'haml'
gem 'json'
gem 'activesupport'
gem 'feedjira'
gem 'metoffice_datapoint'
gem 'redcarpet'
gem 'andand'
gem 'thin'
gem 'rack-contrib'

# to deal with cross-platform development issues, currently using forked variant
group :development do
  gem 'git-version-bump', :git => 'https://github.com/benbasson/git-version-bump.git', :branch => 'windows-compatibility', :platform => :mswin
end

group :development, :test do
  gem 'rspec'
  gem 'webmock'
end

group :production do
  gem 'newrelic_rpm'
end