require File.dirname(__FILE__) + "/lib/yard-sftp/version"

Gem::Specification.new do |s|
  s.name        = 'yard-sftp'
  s.version     = YARDSFTP::VERSION
  s.date        = '2013-07-15'
  s.summary     = 'yard-sftp - securely transfer your yard documentation'
  s.description = 'Move your new shiny documentation to a remote location with SFTP'
  s.author      = 'Jonathan Chrisp'
  s.email       = 'jonathan.chrisp@gmail.com'
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/jonathanchrisp/yard-sftp'
  s.required_ruby_version = ">= 1.9.2"

  s.add_development_dependency 'rspec', '~> 2.13.0'
  s.add_development_dependency 'pry', '~> 0.9.12.2'

  s.add_runtime_dependency 'net-sftp', '~> 2.1.2'
  s.add_runtime_dependency 'colored', '~> 1.2'
  s.add_runtime_dependency 'yard', '~> 0.8.6.2'

  s.files         = `git ls-files`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end