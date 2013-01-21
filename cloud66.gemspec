require 'rake'
require File.expand_path('lib/version')

Gem::Specification.new do |gem|
  gem.name        = 'cloud66'
  gem.version     = Agent::Version.current
  gem.platform    = Gem::Platform::RUBY
  gem.date        = '2013-01-21'
  gem.summary     = "Cloud 66 Server Agent"
  gem.description = "See http://cloud66.com for more info"
  gem.authors     = ["Cloud 66"]
  gem.email       = 'hello@cloud66.com'
  gem.files       = FileList["lib/version.rb", "lib/cloud-quartz.rb", "lib/client_auth.rb", "lib/vital_signs_utils.rb", 'lib/plugins/**/*.rb'].to_a
  gem.add_dependency('httparty', '>= 0.8.1')
  gem.add_dependency('json', '>= 1.6.3')
  gem.add_dependency('eventmachine', '>=0.12.0')
  gem.add_dependency('faye', '>=0.8.0')
  gem.add_dependency('open4', '>=1.3.0')
  gem.add_dependency('fog', '~>1.4.0')
  gem.add_dependency('cloud66-backup', '~>3.0.25')
  gem.add_dependency('highline', '~>1.6.11')
  gem.add_dependency('sys-filesystem', '~>1.0.0')
  gem.homepage    = 'http://cloud66.com'
  gem.executables << 'c66-agent'
  gem.default_executable = 'c66-agent'
end
