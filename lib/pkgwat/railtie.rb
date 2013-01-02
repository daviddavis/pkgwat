require 'pkgwat'
require 'rails'
module MyPlugin
  class Railtie < Rails::Railtie
    railtie_name :pkgwat
  end
end
