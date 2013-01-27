require 'httparty'
require 'json'

class Pkgwat::Api
  include HTTParty
  base_uri "https://apps.fedoraproject.org/packages/fcomm_connector"

  def initialize
  end

  def gem_requirements(gem, version=nil, repo=nil)
    filters = { package: "rubygem-#{gem}",
                version: version,
                repo: repo,
                arch: "noarch",
              }
    options = { filters: filters,
                rows_per_page: 1000,
                start_row: 0
              }
    query = URI.escape(options.to_json)
    self.class.get("/yum/query/query_requires/#{query}")
  end
end
