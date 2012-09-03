require 'rake'

Gem::Specification.new do |s|
  s.name        = 'cloud66'
  s.version     = '0.0.5.beta5'
  s.date        = '2012-09-01'
  s.summary     = "Cloud 66 Server Agent"
  s.description = "See http://cloud66.com for more info"
  s.authors     = ["Cloud 66"]
  s.email       = 'hello@cloud66.com'
  s.files       = FileList["lib/cloud-quartz.rb", "lib/client_auth.rb", 'lib/plugins/**/*.rb'].to_a
  s.add_dependency('httparty', '>= 0.8.1')
  s.add_dependency('json', '>= 1.6.3')
  s.add_dependency('eventmachine', '>=0.12.0')
  s.add_dependency('faye', '>=0.8.0')
  s.add_dependency('open4', '>=1.3.0')
  s.add_dependency('fog', '~>1.4.0')
  s.add_dependency('cloud66-backup', '~>3.0.25')
  s.add_dependency('highline', '~>1.6.11')
  s.homepage    = 'http://cloud66.com'
  s.executables << 'c66-agent'
  s.default_executable = 'c66-agent'
end
