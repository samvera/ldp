# Ldp.rb

[![Build Status](https://travis-ci.org/projecthydra/ldp.png?branch=master)](https://travis-ci.org/projecthydra/ldp)
[![Version](https://badge.fury.io/rb/ldp.png)](http://badge.fury.io/rb/ldp)
[![Dependencies](https://gemnasium.com/projecthydra/ldp.png)](https://gemnasium.com/projecthydra/ldp)
[![Coverage Status](https://coveralls.io/repos/github/projecthydra/ldp/badge.svg?branch=master)](https://coveralls.io/github/projecthydra/ldp?branch=master)

Linked Data Platform client library for Ruby

## Installation

Add this line to your application's Gemfile:

    gem 'ldp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ldp

## Usage

```ruby
host = 'http://localhost:8080'
client = Ldp::Client.new(host)
resource = Ldp::Resource.new(client, host + '/rest/node/to/update')
orm = Ldp::Orm.new(resource)

# view the current title(s)
orm.orm.value(RDF::DC11.title)

# update the title
orm.graph.delete([orm.resource.subject_uri, RDF::DC11.title, nil])
orm.graph.insert([orm.resource.subject_uri, RDF::DC11.title, 'a new title'])

# save changes
orm.save
```

### Fedora Commons notes
Due to some discrepancies with alpha version of Fedora Commons, you may need to do some things differently:
* [Can't load resources from Fedora 4](https://github.com/projecthydra/ldp/issues/1)
* [orm.save with an rdf:type doesn't work with Fedora 4.0.0-alpha-3](https://github.com/projecthydra/ldp/issues/2)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Project Hydra
This software has been developed by and is brought to you by the Hydra community.  Learn more at the
[Project Hydra website](http://projecthydra.org)

![Project Hydra Logo](https://github.com/uvalib/libra-oa/blob/a6564a9e5c13b7873dc883367f5e307bf715d6cf/public/images/powered_by_hydra.png?raw=true)
