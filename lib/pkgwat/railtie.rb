require 'pkgwat'
require 'rails'
module MyPlugin
  class Railtie < Rails::Railtie
    railtie_name :pkgwat

    rake_tasks do
      load "tasks/pkgwat.rake"
    end
  end
end
