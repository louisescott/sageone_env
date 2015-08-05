Gem::Specification.new do |s|
  s.name        = 'sageone_env'
  s.version     = '0.0.0'
  s.date        = '2015-08-05'
  s.summary     = "SageOne environment switching"
  s.description = "Enables easy switching between test and development environments"
  s.authors     = ["Nigel Surtees"]
  s.email       = 'nigel.surtees@sage.com'
  s.files       = Dir['lib/**/*']
  s.homepage    =
    'http://rubygems.org/gems/hola'
  s.license       = 'MIT'
  s.add_dependancy 'pry'
end
