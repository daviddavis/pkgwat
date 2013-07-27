require 'test_helper'

describe "Pkgwat" do

  describe "#check_gem" do
    before do
      VCR.insert_cassette('pkgwat_check_gem')
    end

    after do
      VCR.eject_cassette
    end

    it "returns false for a non-existing gem" do
      Pkgwat.check_gem("this-gem-doesnt-exist", "0.0.1", ["Rawhide"]).must_equal false
    end

    it "returns true for existing gem" do
      (!!Pkgwat.check_gem("rails", "3.2.13", "Fedora 19")).must_equal true
    end

    it "returns false for non-existing version" do
      Pkgwat.check_gem("rails", "3.1.1", ["Rawhide"]).must_equal false
      Pkgwat.check_gem("rails", "3.0.7", "Fedora 16").must_equal false
    end

    it "returns distros that have the gem" do
      Pkgwat.check_gem("rails", "3.2.8", ["Fedora 18", "Rawhide"]).must_equal ["Fedora 18"]
    end

    it "returns false if the distro doesn't exist" do
      Pkgwat.check_gem("rails", "3.2.8", ["Ubuntu"]).must_equal false
    end
  end
end
