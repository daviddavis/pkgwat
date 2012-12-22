pkgwat
======

Pkgwat is a gem for querying gem versions from RPM repos. It's based off of
[pkgwat.cli](git://github.com/ralphbean/pkgwat.cli.git) and it uses
[apps.fedoraproject.org/packages](https://apps.fedoraproject.org/packages/).



Installing pkgwat
-----------------

```bash
gem isntall pkgwat
```

Alternatively, if you're using a Gemfile, just add this:

```bash
gem 'pkgwat'
```

Using pkgwat
------------

```ruby
Pkgwat.get_versions("rails")

# this will return true or false if the package exists
Pkgwat.check_gem("pry", "0.9.10", [Pkgwat::F16])
```

We also plan to add some rake tasks so you can check that your bundler gems are
available in Fedora/EPEL repos either locally or as part of a test suite.
