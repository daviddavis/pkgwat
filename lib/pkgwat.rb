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
  CHANGELOG_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/koji/query/query_changelogs"
  CONTENT_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/yum/get_file_tree"
  UPDATES_URL = "https://apps.fedoraproject.org/packages/fcomm_connector/bodhi/query/query_updates"
  KOJI_BUILD_STATES = ["all" => "", "f17" =>"17", "f16" => "16", "f15" => "15", "e16" => "16", "e15" => "15"]
  BUGZILLA_RELEASEA = ["all" => "", "building" =>"0", "success" => "1", "failed" => "2", "cancelled" => "3", "deleted" => "4"]
  BODHI_REALEASE = ["all", "f17", "f16", "f15", "e16", "e15"]
  BODHI_ARCH = ["x86_64", "i686"]

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

  # this function queries and returns the specified number of packages starting
  # at the specified row
  def self.get_packages(pattern, start=0, num=nil)
    num ||= total_rows(pattern, "packages", PACKAGES_URL_LIST)
    query = {"filters"=>{"search"=>pattern}, "rows_per_page"=>num, "start_row"=>start}
    url = PACKAGES_URL_LIST + "/" + query.to_json
    uri = URI.parse(URI.escape(url))
    response = submit_request(uri)
    clean_response = Sanitize.clean(response.body)
    parse_results(clean_response)
  end

  # this function just queries for and returns a single package
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
    num ||= total_rows(pattern, "bugs", BUGS_URL)

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
    num ||= total_rows(pattern, "builds", BUILDS_URL)
    query = {"rows_per_page"=> num, "start_row"=> start, "filters"=> {"state"=> state, "package"=> pattern}}
    url = BUILDS_URL + "/" + query.to_json
    uri = URI.parse(URI.escape(url))
    response = submit_request(uri)
    parse_results(response.body)
  end

  def self.get_changelog(pattern, num=nil, start=0)
    num ||= total_rows(pattern, "builds", BUILDS_URL)
    build_id = get_builds(pattern)[0]['build_id']
    query = {"filters"=> {"build_id"=> build_id}, "rows_per_page"=> num, "start_row"=> start}
    url = CHANGELOG_URL + "/" + query.to_json
    uri = URI.parse(URI.escape(url))
    response = submit_request(uri)
    parse_results(response.body)
  end

  def self.get_contents(pattern, arch='x86_64', release='Rawhide')
    if !BODHI_ARCH.include? arch
      return "Invalid yum arch."
    end
    if !BODHI_REALEASE.include? release
      return "Invalid bodhi release."
    end
    url = CONTENT_URL + "?package=#{pattern}&arch=#{arch}&repo=#{release}"
    uri = URI.parse(URI.escape(url))
    response = submit_request(uri)
    JSON.parse(response.body)
  end

  def self.get_releases(pattern, num=nil, start=0)
    num ||= total_rows(pattern, "releases", PACKAGES_URL)
    query = {"filters"=> {"package"=> pattern}, "rows_per_page"=> num, "start_row"=> start}
    url = PACKAGES_URL + "/" + query.to_json
    uri = URI.parse(URI.escape(url))
    response = submit_request(uri)
    parse_results(response.body)
  end

  def self.get_updates(pattern, status, release, num=nil, start=0)
    num ||= total_rows(pattern, "updates", UPDATES_URL)
    if !BODHI_REALEASE.include? status
      return "Invalid bodhi state."
    end
    if !BODHI_REALEASE.include? release
      return "Invalid bodhi release."
    end
    if status == "all"
      status = ""
    end
    if release == "all"
      release = ""
    end
    query = {"rows_per_page"=> num, "start_row"=> start, "filters"=> {"package"=> pattern, "release" => release, "state"=> status}}
    url = PACKAGES_URL + "/" + query.to_json
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
    elsif type == "releases"
      query = {"filters"=> {"package"=> pattern}, "rows_per_page"=> 10, "start_row"=> 0}
    elsif type == "updates"
      query = {"rows_per_page"=> 10, "start_row"=> 0, "filters"=> {"package"=> pattern, "release" => "all", "state"=> "all"}}
    end
    url = type_url + "/" + query.to_json
    uri = URI.parse(URI.escape(url)) 
    response = submit_request(uri)
    JSON.parse(response.body)["total_rows"]
  end

end
