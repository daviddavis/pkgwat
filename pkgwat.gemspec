# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pkgwat/version"

Gem::Specification.new do |s|
  s.name        = "pkgwat"
  s.version     = Pkgwat::VERSION
  s.authors     = ["David Davis"]
  s.email       = ["daviddavis@redhat.com"]
  s.homepage    = ""
  s.summary     = %q{pkgwat checks your gems to against Fedora/EPEL.}
  s.description = %q{pkgwat checks your Gemfile.lock to make sure all your gems
                     are packaged in Fedora/EPEL. Eventually we hope to support
                     Gemfiles and bundle list as well.}

  s.rubyforge_project = "pkgwat"

  s.add_dependency("nokogiri", "= 1.5.5")
  s.add_dependency("rake")
  s.add_dependency("thor")
  s.add_dependency("json", "1.6.5")
  s.add_dependency("sanitize")
  s.add_dependency("httparty", "0.8.1")

  s.add_development_dependency("vcr", "~> 2.4.0")
  s.add_development_dependency("webmock", "~> 1.9.0")
  s.add_development_dependency("minitest", "~> 4.4.0")
  if RUBY_VERSION >= "1.9"
    s.add_development_dependency("debugger")
  else
    s.add_development_dependency("ruby-debug")
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
