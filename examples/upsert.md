---
layout: with-sidebar
title: Updating data with soda-ruby
type: example
---

## An Important Note

The ability to write to a Socrata dataset requires you to own that dataset or be granted permission to write to it. This might not apply to you. Unless you're already a [Socrata customer](http://www.socrata.com/customer-spotlight/), you have a few other options:

- Sign up for an account on [opendata.socrata.com](http://opendata.socrata.com), our public portal where you can create a limited number of datasets for free.
- If you're a member of a community group working on open data, request the creation of a [Socrata Community Portal](http://communities.socrata.com).
- Get hired by one of our wonderful customers. :)

## Create Your Client and Authenticate

The soda-ruby Gem supports [HTTP Basic Authentication](http://en.wikipedia.org/wiki/Basic_access_authentication) over HTTPs, one of the two different [authentication methods](http://dev.socrata.com/docs/authentication.html) supported by the Socrata APIs. You'll also need to register for an [application token](http://dev.socrata.com/docs/app-tokens.html).

Once you have your account information and your application token, you can create your client. For this example, we'll be updating the [USGS Earthquake Reports](https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4tka-6guv) dataset on our API demo domain, `soda.demo.socrata.com`. It has an identifier of `4tka-6guv`:

{% highlight ruby %}
require 'soda/client'

client = SODA::Client.new({:domain => "soda.demo.socrata.com",
                           :username => "demouser@example.com",
                           :password => "my_demo_user_password",
                           :app_token => "CGxadgoQlgQSev4zyUh5aR5J3"})
{% endhighlight %}

## Create Your Update Payload

We're going to use the `POST` method to update our dataset, using the [upsert functionality](http://dev.socrata.com/publishers/upsert.html) documented on the [Socrata Developer Portal](http://dev.socrata.com). If you've never used upsert before, make sure you have your primary key set properly to make sure you update records properly.

For this example, we're going to create one record and update a second, but the record set could easily be thousands of records. The soda-ruby `post` method accepts an array of hashes to represent the records you want to update in your dataset. For this example, `earthquake_id` is the identifier for this dataset, and it is a [`String`](http://dev.socrata.com/docs/datatypes/string.html) value:

{% highlight ruby %}
update = [ {
  "earthquake_id" => "00388610",
  "region" => "Utah",
  "source" => "nn",
  "location" => {
    "longitude" => -117.6135,
    "latitude" => 41.1085
  },
  "magnitude" => 2.9,
  "number_of_stations" => 17,
  "datetime" => "2012-09-14T22:38:01",
  "depth" => 7.90,
  "version" => 9
}, {
  "earthquake_id" => "12345678901",
  "region" => "Washington",
  "source" => "socrata",
  "location" => {
    "longitude" => -117.6135,
    "latitude" => 41.1085
  },
  "magnitude" => 2.9,
  "number_of_stations" => 17,
  "datetime" => "2014-03-25T22:38:01",
  "depth" => 7.90,
  "version" => 9
} ] 
{% endhighlight %}

## POST Your Update

Once you have your update set ready, you can use the `post` method to push it to Socrata:

{% highlight ruby %}
response = client.post("4tka-6guv", update)
{% endhighlight %}

The response object will be a summary of the updates were made and possibly the errors that were encountered.

