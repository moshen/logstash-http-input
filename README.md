## An HTTP input for Logstash <= 1.4.x (using Jetty)

## NOTICE

[Logstash 1.5.0 is introducing an official http input](https://github.com/logstash-plugins/logstash-input-http).
Considering this, and the fact that I'm no longer using this plugin in my own
work; I'm recommending >= 1.5.x users should switch to the official plugin.

### About

Instantiates Jetty on the specified host and port, and applies the configured
codec (`plain` by default) to the `PUT` or `POST` request body.

### Build / Fetch dependencies

Run `./gradlew` (or gradlew.bat) to assemble.

This will download the dependencies, add the right jetty version to `http.rb`
and put `http.rb` in a (somewhat proper) plugin folder:
`build/plugins/logstash/inputs/`.

### Installation

Run `./gradlew install -PinstallDir=dirToCopyTheContentsOfBuildTo` to install.

This will do everything in assemble, but also copy the files to a destination
of your choosing.  You probably want this to be your logstash install dir.

### Configuration

The default configuration as represented in the logstash configuration file
format:

    input {
      http {
        host => "0.0.0.0"
        maxFormSize => 200000
        acceptQueueSize => 0
      }
    }

**host** - The address to listen on.  Default: `"0.0.0.0"`

**port** - The port to listen on.  No Default, **required**

**maxFormSize** - [The maximum form size for Jetty in bytes](http://www.eclipse.org/jetty/documentation/current/setting-form-size.html).
Default `200000` (set to `-1` for no max size)

**acceptQueueSize** - The accept queue size for the default server connector.
Default `0` (Which defers to the implementation default, currently `50`)

### Example

If I have the logstash tarball extracted to `../logstash-1.4.2`, I can simply
run: `./gradlew install -PinstallDir=../logstash-1.4.2/` to install the http
input.

To test:

    cd ../logstash-1.4.2
    bin/logstash -p plugins -e 'input { http { port => 8090 } } output { stdout { codec => rubydebug } }'

Which should show something like:

    2014-04-01 16:53:38.805:INFO::Ruby-0-Thread-3: ../logstash-1.4.2/vendor/bundle/jruby/1.9/gems/stud-0.0.17/lib/stud/task.rb:10: Logging initialized @4347ms
    Using milestone 0 input plugin 'http'. This plugin isn't well supported by the community and likely has no maintainer. For more information on plugin milestones, see http://logstash.net/docs/1.4.2/plugin-milestones {:level=>:warn}
    2014-04-01 16:53:43.942:INFO:oejs.Server:<http: jetty-9.1.3.v20140225
    2014-04-01 16:53:43.983:INFO:oejs.ServerConnector:<http: Started ServerConnector@51f061a8{HTTP/1.1}{0.0.0.0:8090}
    2014-04-01 16:53:43.984:INFO:oejs.Server:<http: Started @9526ms

Proceed to post `plain` (by default, other codec messages if configured):

    curl -d 'Hello Logstash!' http://localhost:8090

Which should result in the output of something like:

    {
           "message" => "Hello Logstash!",
          "@version" => "1",
        "@timestamp" => "2014-05-18T22:22:14.064Z",
              "host" => "0:0:0:0:0:0:0:1"
    }

### Tips / Performance Considerations

Can quickly become overloaded if sending single log messages in each http
request.  Recommended usage is to use `Keep-Alive` and combine several
newline-delimited log messages in each `POST` with the
[`line`](http://logstash.net/docs/1.4.2/codecs/line) or
[`json_lines`](http://logstash.net/docs/1.4.2/codecs/json_lines) codecs.

### Issues

Doesn't override the Jetty default logging and Jetty just goes ahead and spits
out logs to `STDERR`.  I've found this useful for debugging, but may not be the
desired behavior.

Currently doesn't expose configuration of the Jetty thread pool options.  This
will probably change in the future.

### License

Apache v2, See LICENSE file

