Gem::Specification.new do |s|
  s.name        = 'config-chief'
  s.version     = '0.0.1'
  s.date        = '2012-02-28'
  s.summary     = "CloudBlocks ConfigChief Ruby Gem"
  s.description = "Simple and easy configuration for ruby/rails apps. See http://www.thecloudblocks.com for more info"
  s.authors     = ["Khash Sajadi"]
  s.email       = 'khash@thecloudblocks.com'
  s.files       = ["lib/config-chief.rb"]
  s.add_dependency('httparty', '>= 0.8.1')
  s.add_dependency('json', '>= 1.6.3')
  s.homepage    = 'http://www.thecloudblocks.com'
  s.executables << 'chief'
end