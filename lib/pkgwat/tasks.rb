require 'rake'
require 'pkgwat'

DISTRO_ERROR_MESSAGE = <<-EOS
ERROR: Distros not supplied. Please call this task with distros (e.g. rake pkgwat:check DISTROS="Fedora 19, Fedora EPEL 6, Rawhide")
EOS

def gem_output(gem)
  "#{gem.name} #{gem.version}"
end

namespace :pkgwat do
  desc "Check the Gemfile.lock for packages"
  task :check do
    distros = ENV['DISTROS']
    raise DISTRO_ERROR_MESSAGE if distros.nil? || distros.length < 1
    distros = distros.split(",")

    lockfile = Bundler::LockfileParser.new(Bundler.read_file("Gemfile.lock"))
    lockfile.specs.each do |gem|
      puts "Checking gem (#{gem_output(gem)})"
      if rel = Pkgwat.check_gem(gem.name, gem.version, distros)
        puts "  OK: #{gem_output(gem)} available in #{rel.join(", ")}"
      else
        puts "  FAIL: #{gem_output(gem)} not in #{distros.join(", ")}"
      end
    end
  end
end
