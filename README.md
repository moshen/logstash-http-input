## An HTTP input for Logstash (using Jetty)

### About

Instantiates Jetty on the specified host and port, and applies the configured
codec (json by default) to the `PUT` or `POST` request body.

### Build / Fetch dependencies

Run `./gradlew` (or gradlew.bat) to assemble.

This will download the dependencies, add the right jetty version to `http.rb`
and put `http.rb` in a (somewhat proper) plugin folder:
`build/plugins/logstash/inputs/`.

### Install / Use

Run `./gradlew install -PinstallDir=dirToCopyTheContentsOfBuildTo` to install.

This will do everything in assemble, but also copy the files to a destination
of your choosing.  You probably want this to be your logstash install dir.

### Example

If I have the logstash tarball extracted to `../logstash-1.4.0`, I can simply
run: `./gradlew install -PinstallDir=../logstash-1.4.0/` to install the http
input.

To test:

    cd ../logstash-1.4.0
    bin/logstash -p plugins -e 'input { http { port => 8090 } } output { stdout { codec => rubydebug } }'

Which should show something like:

    2014-04-01 16:53:38.805:INFO::Ruby-0-Thread-3: ../logstash-1.4.0/vendor/bundle/jruby/1.9/gems/stud-0.0.17/lib/stud/task.rb:10: Logging initialized @4347ms
    Using milestone 0 input plugin 'http'. This plugin isn't well supported by the community and likely has no maintainer. For more information on plugin milestones, see http://logstash.net/docs/1.4.0/plugin-milestones {:level=>:warn}
    2014-04-01 16:53:43.942:INFO:oejs.Server:<http: jetty-9.1.3.v20140225
    2014-04-01 16:53:43.983:INFO:oejs.ServerConnector:<http: Started ServerConnector@51f061a8{HTTP/1.1}{0.0.0.0:8090}
    2014-04-01 16:53:43.984:INFO:oejs.Server:<http: Started @9526ms

Proceed to post json (by default, other codec messages if configured):

    curl -d '{ "host": "localhost", "message": "My http logs" }' http://localhost:8090

Which should result in the stdout of something like:

    {
              "host" => "localhost",
           "message" => "My http logs",
          "@version" => "1",
        "@timestamp" => "2014-04-01T21:58:39.809Z"
    }

### Issues

Doesn't override the Jetty default logging and Jetty just goes ahead and spits
out logs to `STDERR`.  I've found this useful for debugging, but may not be the
desired behavior.

