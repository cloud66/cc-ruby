Gem::Specification.new do |s|
  s.name        = 'cloudblocks'
  s.version     = '0.0.1'
  s.date        = '2012-03-08'
  s.summary     = "CloudBlocks Gem and Agent"
  s.description = "See http://www.thecloudblocks.com for more info"
  s.authors     = ["Khash Sajadi"]
  s.email       = 'khash@thecloudblocks.com'
  s.files       = ["lib/config-chief.rb"]
  s.add_dependency('httparty', '>= 0.8.1')
  s.add_dependency('json', '>= 1.6.3')
  s.add_dependency('eventmachine', '>=0.12.10')
  s.add_dependency('faye', '>=0.8.0')
  s.add_dependency('open4', '>=1.3.0')
  s.add_dependency('rubygems', '>=1.8.17')
  s.homepage    = 'http://www.thecloudblocks.com'
  s.executables << 'chief'
  s.executables << 'quartz'
end