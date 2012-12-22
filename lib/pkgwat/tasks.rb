require 'rake'
require 'pkgwat'

namespace :pkgwat do
  desc "Check the Gemfile.lock for packages"
  task :check do
    lockfile = Bundler::LockfileParser.new(Bundler.read_file("Gemfile.lock"))
    lockfile.specs.each do |gem|
      Pkgwat.check_gem(gem.name, gem.version)
    end
  end
end
