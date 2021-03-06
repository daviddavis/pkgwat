pkgwat [![Build Status](https://travis-ci.org/daviddavis/pkgwat.png)](http://travis-ci.org/daviddavis/pkgwat)
======

Pkgwat is a ruby gem for querying gem versions from RPM repos. It's based off
of [pkgwat.cli](https://github.com/ralphbean/pkgwat.cli) and it uses
[apps.fedoraproject.org/packages](https://apps.fedoraproject.org/packages/).



Installing pkgwat
-----------------

```bash
gem install pkgwat
```

Alternatively, if you're using a Gemfile, just add this:

```bash
gem 'pkgwat'
```

Using pkgwat
------------

Inside your code, simply require rubygems and pkgwat. Then you use it like so:

```ruby
Pkgwat.get_versions("rails")

# this will return true or false if the package exists
Pkgwat.check_gem("pry", "0.9.10", ["Fedora EPEL 6", "Fedora 19", "Rawhide"])
```

### Rake Tasks

To check your gems in bundler against Fedora repos, run:

```bash
rake pkgwat:check
```

Developing pkgwat
-----------------

### Requirements

* ruby 2.0 (or greater)
* rvm (optional but recommended)
* rubygems
* bundler (`gem install bundler`)

### Getting started

To develop pkgwat, check out the git repo and bundle:

```bash
git clone git@github.com:daviddavis/pkgwat.git pkgwat
cd pkgwat # accept the rvmrc file
bundle install # run bundler
```

Then just fire up irb:

```
irb -Ilib -rpkgwat
>> Pkgwat.get_versions("runcible")
=> [{"release"=>"Rawhide", ...
```

### Testing

To run the pkgwat test suite execute via rake:

```bash
rake test
```

Also you can run an individual test:

```bash
ruby -Itest test/pkgwat_test.rb
```

To record your interactions via VCR and use the actual web APIs:

```bash
rake test mode=all
```
