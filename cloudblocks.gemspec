require 'rake'

Gem::Specification.new do |s|
  s.name        = 'cloudblocks'
  s.version     = '0.0.10'
  s.date        = '2012-03-24'
  s.summary     = "CloudBlocks Gem and Agent"
  s.description = "See http://www.thecloudblocks.com for more info"
  s.authors     = ["Khash Sajadi"]
  s.email       = 'khash@thecloudblocks.com'
  s.files       = FileList["lib/config-chief.rb", "lib/cloud-quartz.rb", 'lib/plugins/**/*.rb'].to_a
  s.add_dependency('httparty', '>= 0.8.1')
  s.add_dependency('json', '>= 1.6.3')
  s.add_dependency('eventmachine', '>=0.12.10')
  s.add_dependency('faye', '>=0.8.0')
  s.add_dependency('open4', '>=1.3.0')
  s.add_dependency('fog', '>=1.1.2')
  s.homepage    = 'http://www.thecloudblocks.com'
  s.executables << 'chief'
  s.executables << 'quartz'
end