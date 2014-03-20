Cherby
======

Cherby is a Ruby wrapper for the
[Cherwell Web Service](http://cherwellsupport.com/webhelp/cherwell/index.htm#1971.htm).

[Full documentation is on rdoc.info](http://rubydoc.info/github/a-e/cherby/master/frames).

[![Build Status](https://secure.travis-ci.org/a-e/cherby.png?branch=dev)](http://travis-ci.org/a-e/cherby)


Usage
-----

Connect to a Cherwell server by providing the URL of the web service:

    url = "http://my.server/CherwellService/api.asmx"
    cherwell = Cherby::Cherwell.new(url)

Login by providing username and password, either during instantiation, or later
when calling the `#login` method:

    cherwell = Cherby::Cherwell.new(url, 'sisko', 'baseball')
    cherwell.login
    # => true

    # or

    cherwell = Cherby::Cherwell.new(url)
    cherwell.login('sisko', 'baseball')
    # => true

Fetch an Incident:

    incident = cherwell.incident('12345')
    # => #<Cherby::Incident:0x...>

View as a Hash:

    incident.to_hash
    # => {
    #   'IncidentID' => '12345',
    #   'Status' => 'Open',
    #   'Priority' => '7',
    #   ...
    # }

Make changes:

    incident['Status'] = 'Closed'
    incident['CloseDescription'] = 'Issue resolved'

Save back to Cherwell:

    cherwell.save_incident(incident)


Copyright
---------

The MIT License

Copyright (c) 2014 Eric Pierce

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

