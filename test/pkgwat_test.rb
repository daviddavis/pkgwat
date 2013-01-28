require 'test_helper'

describe "Pkgwat" do

  before do
    VCR.insert_cassette('pkgwat_api')
  end

  after do
    VCR.eject_cassette
  end

  it "has a Fedora 17 constant" do
    Pkgwat::F17.must_equal "Fedora 17"
  end

  describe "#check_gem" do
    it "returns false for a non-existing gem" do
      Pkgwat.check_gem("this-gem-doesnt-exist", "0.0.1").must_equal false
    end

    it "returns true for existing gem" do
      Pkgwat.check_gem("rails", "3.2.8", [Pkgwat::F18]).must_equal true
    end

    it "returns false for non-existing version" do
      Pkgwat.check_gem("rails", "3.2.8", [Pkgwat::F17]).must_equal false
      Pkgwat.check_gem("rails", "3.2.7", [Pkgwat::F18]).must_equal false
    end

    it "returns false for an incomplete match" do
      skip "Need to fix this" # TODO: remove this line
      Pkgwat.check_gem("rails", "3.2.8", [Pkgwat::F17, Pkgwat::F18]).must_equal false
    end
  end

  describe "#get_requirements" do

    it "returns the required gems for rails" do
      reqs = Pkgwat.get_requirements("rails", "3.0.11", Pkgwat::RAWHIDE)
      reqs.map{|r| r["name"]}.sort.must_equal ["ruby(abi)",
                                               "ruby(rubygems)",
                                               "rubygem(actionmailer)",
                                               "rubygem(actionpack)",
                                               "rubygem(activerecord)",
                                               "rubygem(activeresource)",
                                               "rubygem(activesupport)",
                                               "rubygem(bundler)",
                                               "rubygem(railties)",
                                              ]
    end
  end
end
