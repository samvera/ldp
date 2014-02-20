# Ldp.rb

[![Build Status](https://travis-ci.org/cbeer/ldp.png?branch=master)](https://travis-ci.org/cbeer/ldp)

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
* [Can't load resources from Fedora 4](https://github.com/cbeer/ldp/issues/1)
* [orm.save with an rdf:type doesn't work with Fedora 4.0.0-alpha-3](https://github.com/cbeer/ldp/issues/2)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
