ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'pkgwat'
require 'vcr'
begin
  require 'debugger'
rescue LoadError
  warn "warning: debugger gem not found; skipping debugger support"
end


mode = ENV['mode'] ? ENV['mode'] : :none

VCR.configure do |c|
  c.cassette_library_dir = 'test/fixtures/vcr'
  c.hook_into :webmock
  c.default_cassette_options = {
    :record => mode.to_sym
  }
end