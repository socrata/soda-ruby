
[![Build status](https://ci.appveyor.com/api/projects/status/4uaa2irr26deoffv?svg=true)](https://ci.appveyor.com/project/chrismetcalf/soda-ruby)
[![Build Status](https://travis-ci.org/socrata/soda-ruby.svg?branch=master)](https://travis-ci.org/socrata/soda-ruby)

For more details and for documentation, check out <http://socrata.github.io/soda-ruby> or our [developer portal](http://dev.socrata.com).

## Installation

SODA is distributed as a gem, which is how it should be used in your app.

Include the gem and hashie in your Gemfile:

```ruby
gem 'soda-ruby', :require => 'soda'
```

### Important Note!

In order to access the SODA API via HTTPS, clients must now [support the Server Name Indication (SNI)](https://dev.socrata.com/changelog/2016/08/24/sni-now-required-for-https-connections.html) extension to the TLS protocol. What does this mean? It means that if you're using `soda-ruby`, you must [use Ruby 2.0.0 or above](https://en.wikipedia.org/wiki/Server_Name_Indication), as that is when `net/http` introduced support for SNI. 2.0.0 was released in 2011, so most up-to-date platforms will be on version 2.0 or greater.

## Quick Start

Create a new client. Register for an application token at <http://dev.socrata.com/register>.

```ruby
client = SODA::Client.new({:domain => "explore.data.gov", :app_token => "CGxadgoQlgQSev4zyUh5aR5J3"})
```

Issue a filter query. `644b-gaut` is the identifier for the dataset we want to access. 

### As of version 1.0.0+

The return object is the complete response object with a pre parsed body. The response.body object is an array of [Hashie::Mash].

If you are upgrading from a version < 1.0.0 The previous object returned is now the response.body object.

### Prior to version 1 (<1.0.0)

The return object is an array of [Hashie::Mash] that represents the body of the response.

(https://github.com/intridea/hashie) objects:

```ruby
response = client.get("644b-gaut", {"$limit" => 1, :namelast => "WINFREY", :namefirst => "OPRAH"})

 #=> [#<Hashie::Mash appt_end_date="12/3/09 23:59" appt_made_date="12/2/09 18:05" appt_start_date="12/3/09 9:30" caller_name_first="SALLY" caller_name_last="ARMBRUSTER" last_updatedby="J7" lastentrydate="12/2/09 18:05" meeting_loc="WH" meeting_room="DIP ROOM" namefirst="OPRAH" namelast="WINFREY" post="WIN" release_date=1269586800 terminal_suffix="J7" total_people="10" type_of_access="VA" uin="U60816" visitee_namefirst="SEMONTI" visitee_namelast="STEPHENS">]
```

You can use other simple query SoQL methods found here: <http://dev.socrata.com/docs/queries.html>

```ruby
client = SODA::Client.new({:domain => "soda.demo.socrata.com"})
magnitude_response = client.get("4tka-6guv", {"$where" => "magnitude > '3.0'"})

#=> [#<Hashie::Mash datetime="2012-09-14T09:28:55" depth="20" earthquake_id="12258012" location=#<Hashie::Mash latitude="19.7859" longitude="-64.0849" needs_recoding=false> magnitude="3.1" number_of_stations="6" region="north of the Virgin Islands" source="pr" version="0">, #<Hashie::Mash datetime="2012-09-14T07:58:39" depth="74" earthquake_id="12258011" location=#<Hashie::Mash latitude="19.5907" longitude="-64.1723" needs_recoding=false> magnitude="3.3" number_of_stations="4" region="Virgin Islands region" source="pr" version="0">, ... ]

datetime_response = client.get("4tka-6guv", {"$where" => "datetime > '2012-09-14T09:28:55' AND datetime < '2012-12-25T09:00:00'"})

#=> [#<Hashie::Mash datetime="2012-09-14T10:10:19" depth="8.2" earthquake_id="00388609" location=#<Hashie::Mash latitude="36.9447" longitude="-117.6778" needs_recoding=false> magnitude="1.7" number_of_stations="29" region="Northern California" source="nn" version="9">, #<Hashie::Mash datetime="2012-09-14T10:06:11" depth="6.4" earthquake_id="00388607" location=#<Hashie::Mash latitude="36.9417" longitude="-117.6903" needs_recoding=false> magnitude="1.7" number_of_stations="29" region="Central California" source="nn" version="9">, ... ]
```

You can also provide a full URI to an API endpoint instead of specifying the ID. Just copy and paste the dataset URI from the API documentation!

```ruby
client = SODA::Client.new({:domain => "soda.demo.socrata.com"})
magnitude_response = client.get("https://soda.demo.socrata.com/resource/4tka-6guv.json", {"$where" => "magnitude > '3.0'"})
```

All the field names have built in getter methods since the objects are Hashie::Mashes.

```ruby
magnitude_response.first.number_of_stations   #=> "6"
```
*Note that the return value is a string object.*
