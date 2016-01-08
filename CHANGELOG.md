0.2.19
------
Added the ability to pass in a full URI instead of just a path or dataset identifier when making a request. You can also combine URIs with additional parameters.

Ex:

    require 'soda/client'
    client = SODA::Client.new
    client.get("https://fakehost.socrata.com/resource/644b-gaut.json?last_name=Willis", :first_name => "Bruce")

0.2.18
------
Added a `:debug_stream` option to the client to all you to get the full HTTP conversation for debugging. Should not be used in production.

    require 'soda/client'
    client = SODA::Client.new(:domain => "data.seattle.gov", :debug_stream => $stderr)

0.2.17
------
Modified `SODA::Client.generate_user_agent` to not use `Sys::Uname` to fetch system information. 

0.2.16
------
- Added support for OAuth tokens for authentication
- Improved the detail of the exceptions we throw in the case of errors

0.2.15
------
(This version was never pushed)
- Added an OmniAuth provider

0.2.13
------
Added a global :timeout option to override the default Net:HTTP timeout, and accepting 202 as an "OK" response code, which should only occur during import.

0.2.12
------
Added a global option to disable SSL checking (#7)

0.2.11
------
We weren't properly handling an empty payload response

0.2.10
------
Removing a nesting limit that we missed

0.2.8
-----
Removing the nesting limit on the JSON parser

0.2.7
-----
Removing dead code and an un-needed dependency

0.2.6
-----
Code cleanup from @raykao

0.2.4
-----
Point release including tests that are now mocked properly

0.2.1
-----
Point release to update gemspec dependencies

0.2.0
-----
Initial Public Release

