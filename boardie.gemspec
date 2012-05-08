# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'version'

Gem::Specification.new do |s|
  s.name          = "boardie"
  s.version       = Boardie::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = "James Turnbull"
  s.email         = "james@lovedthanlost.net"
  s.homepage      = ""
  s.summary       = %q{Simple status display board for Redmine}
  s.description   = %q{Simple status display board for Redmine}
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency(%q<rest-client>, [">= 0"])
  s.add_dependency(%q<json>, [">= 0"])
end
