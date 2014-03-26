---
layout: with-sidebar
title: soda-ruby
bodyclass: homepage
---

## Installation

SODA is distributed as a gem, which is how it should be used in your app.

Include the gem and hashie in your Gemfile:

{% highlight ruby %}
gem 'soda-ruby', :require => 'soda'
{% endhighlight %}

## Quick Start

Create a new client. Register for an application token at <http://dev.socrata.com/register>.

{% highlight ruby %}
require 'soda/client'

client = SODA::Client.new({:domain => 'explore.data.gov', :app_token => 'CGxadgoQlgQSev4zyUh5aR5J3'})
{% endhighlight %}


Issue a simple query. `644b-gaut` is the identifier for the dataset we want to access:

{% highlight ruby %}
response = client.get("644b-gaut", {"$limit" => 1, :namelast => "WINFREY", :namefirst => "OPRAH"})

[#<Hashie::Mash appt_end_date="12/3/09 23:59" appt_made_date="12/2/09 18:05" appt_start_date="12/3/09 9:30" caller_name_first="SALLY" caller_name_last="ARMBRUSTER" last_updatedby="J7" lastentrydate="12/2/09 18:05" meeting_loc="WH" meeting_room="DIP ROOM" namefirst="OPRAH" namelast="WINFREY" post="WIN" release_date=1269586800 terminal_suffix="J7" total_people="10" type_of_access="VA" uin="U60816" visitee_namefirst="SEMONTI" visitee_namelast="STEPHENS">]
{% endhighlight %}
