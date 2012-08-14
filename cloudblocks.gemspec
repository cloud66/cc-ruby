require 'rake'

Gem::Specification.new do |s|
  s.name        = 'cloudblocks'
  s.version     = '0.0.18'
  s.date        = '2012-08-14'
  s.summary     = "CloudBlocks Gem and Agent"
  s.description = "See http://cloudblocks.co for more info"
  s.authors     = ["CloudBlocks"]
  s.email       = 'hello@cloudblocks.co'
  s.files       = FileList["lib/cloud-quartz.rb", "lib/client_auth.rb", 'lib/plugins/**/*.rb'].to_a
  s.add_dependency('httparty', '>= 0.8.1')
  s.add_dependency('json', '>= 1.6.3')
  s.add_dependency('eventmachine', '>=0.12.10')
  s.add_dependency('eventmachine', '~>1.0.0.beta.4')
  s.add_dependency('faye', '>=0.8.0')
  s.add_dependency('open4', '>=1.3.0')
  s.add_dependency('fog', '~>1.4.0')
  s.add_dependency('cloud66-backup', '~>3.0.25')
  
  s.add_runtime_dependency('highline', '~>1.6.11')
  s.homepage    = 'http://cloudblocks.co'
  s.executables << 'cb-agent'
  s.default_executable = 'cb-agent'
end
