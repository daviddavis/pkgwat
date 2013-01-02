require "pkgwat/version"
require 'net/https'
require 'json'
require 'sanitize'

module Pkgwat
  require 'pkgwat/railtie' if defined?(Rails)

  F17 = "Fedora 17"
  F16 = "Fedora 16"
  F18 = "Fedora 18"
  EPEL6 = "Fedora EPEL 6"
  EPEL5 = "Fedora EPEL 5"
  DEFAULT_DISTROS = [F17, F16, EPEL6]
  PACKAGE_NAME = "rubygem-:gem"
  PACKAGES_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/bodhi/query/query_active_releases"
  PACKAGES_URL_LIST = "https://apps.fedoraproject.org/packages/fcomm_connector/xapian/query/search_packages"
  BUGS_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/bugzilla/query/query_bugs"
  BUILDS_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/koji/query/query_builds"
  KOJI_BUILD_STATES = ["all" => "", "f17" =>"17", "f16" => "16", "f15" => "15", "e16" => "16", "e15" => "15"]
  BUGZILLA_RELEASEA = ["all" => "", "building" =>"0", "success" => "1", "failed" => "2", "cancelled" => "3", "deleted" => "4"]

  def self.check_gem(name, version, distros = DEFAULT_DISTROS, throw_ex = false)
    puts "Checking #{name} #{version}...\n"
    versions = get_versions(name)
    matches = []
    distros.each do |distro|
      dv = versions.detect { |v| v["release"] == distro }
      match = compare_versions(version, dv["stable_version"])
      matches << dv["release"] if match
    end
    puts "#{name} is available in the following distros: #{matches.join(",")}"
  end

  def self.compare_versions(version, distro)
    distro.to_s.split("-").first == version.to_s
  end

  def self.get_versions(gem_name)
    uri = search_url(gem_name)
    response = submit_request(uri)
    raise "Could not connect to packages API (#{response.inspect})" unless response.code == "200"
    parse_results(response.body)
  end

  def self.package_name(gem)
    PACKAGE_NAME.gsub(":gem", gem)
  end
  
  #this function queries and returns the specified number of packages starting at the specified row
  def self.get_packages(pattern, start=0, num=nil) 
    if num == nil
      num = total_rows(pattern, "packages", PACKAGES_URL_LIST)
    end
    query = {"filters"=>{"search"=>pattern}, "rows_per_page"=>num, "start_row"=>start}
    url = PACKAGES_URL_LIST + "/" + query.to_json
    uri = URI.parse(URI.escape(url)) 
    response = submit_request(uri)
    clean_response = Sanitize.clean(response.body)
    parse_results(clean_response)    
  end 
 
  #this function just queries for and returns a single package  
  def self.get_package(pattern)
    get_packages(pattern, 0, 1).first
  end 

  #this function queries for and returns a list of then open BUGS  
  def self.get_bugs(pattern, version='all', num=nil, start =0)
    if BUGZILLA_RELEASEA[0][version].nil?
      version = BUGZILLA_RELEASEA[0]['all']
    else
      version = BUGZILLA_RELEASEA[0][version]
    end 
    if num == nil
      num = total_rows(pattern, "bugs", BUGS_URL)
    end
    query = {"filters"=> {"package"=> pattern, "version"=> version}, "rows_per_page"=> num, "start_row"=> start}
    url = BUGS_URL + "/" + query.to_json
    uri = URI.parse(URI.escape(url)) 
    response = submit_request(uri)
    parse_results(response.body)  
  end

  #this function queries for and returns a list of the BUILDS 
  def self.get_builds(pattern, state='all', num=nil, start =0)
    if KOJI_BUILD_STATES[0][state].nil?
      state = KOJI_BUILD_STATES[0]['all']
    else
      state = KOJI_BUILD_STATES[0][state]
    end
    if num == nil
      num = total_rows(pattern, "builds", BUILDS_URL)
    end
    query = {"rows_per_page"=> num, "start_row"=> start, "filters"=> {"state"=> state, "package"=> pattern}}
    url = BUILDS_URL + "/" + query.to_json
    uri = URI.parse(URI.escape(url)) 
    response = submit_request(uri)
    parse_results(response.body)  
  end
  
  def self.search_params(gem)
    filters = { :package => package_name(gem) }
    { :filters => filters }
  end

  def self.search_url(gem)
    query = search_params(gem)
    url = PACKAGES_URL + "/" + query.to_json
    URI.parse(URI.escape(url))
  end

  def self.submit_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE #TODO: verify
    request = Net::HTTP::Get.new(uri.request_uri)
    http.request(request)
  end

  def self.parse_results(results)
    results = JSON.parse(results)
    results["rows"]
  end
  
  private

  def self.total_rows(pattern, type, type_url)
    if type == "packages"
      query = {"filters"=>{"search"=>pattern}, "rows_per_page"=>10, "start_row"=>0}
    elsif type == "builds"
      query = {"rows_per_page"=> 10, "start_row"=> 0, "filters"=> {"state"=> "", "package"=> pattern}}
    elsif type == "bugs"
      query = {"filters"=> {"package"=> pattern, "version"=> ""}, "rows_per_page"=> 10, "start_row"=> 0}
    end
    url = type_url + "/" + query.to_json
    uri = URI.parse(URI.escape(url)) 
    response = submit_request(uri)
    JSON.parse(response.body)["total_rows"]            
  end
  
end
