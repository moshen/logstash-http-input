# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"

require 'java'
# Load Jetty Dependencies
jarpath = File.join(File.dirname(__FILE__),
  "../../../vendor/jar/jetty-@version@/*.jar")
Dir.glob(jarpath).each do |jar|
  require jar
end

# Read events PUT or POSTED to an http server.
#
# Each PUT or POST is assumed to be an event by default.
class LogStash::Inputs::Http < LogStash::Inputs::Base
  class Interrupted < StandardError; end
  config_name "http"
  milestone 0

  default :codec, "plain"

  # The address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on.
  config :port, :validate => :number, :required => true

  # Max form content size in bytes. Set to -1 to disable.
  config :maxFormSize, :validate => :number, :default => 200000

  # Jetty Server Connector acceptQueueSize. 0 uses implementation default.
  config :acceptQueueSize, :validate => :number, :default => 0

  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    # I don't think we need to do anything here
  end # def register

  class LogHandler < org.eclipse.jetty.server.handler.AbstractHandler
    def handle(target, baseRequest, httpRequest, httpResponse)
      case httpRequest.getMethod() 
      when 'PUT', 'POST'
        setKeepAlive(httpRequest, httpResponse)
        httpResponse.setStatus(200)
        scanner = Java::java.util.Scanner.new(httpRequest.getInputStream(), "UTF-8")
          .useDelimiter("\\A")

        if scanner.hasNext()
          @codec.clone.decode(scanner.next()) do |event|
            @parent.decorate(event)
            if !event.include?("host") || event["host"].empty?
              event["host"] = httpRequest.getRemoteAddr()
            end
            @output_queue << event
          end
        end

      when 'HEAD', 'GET', 'OPTIONS'
        if setKeepAlive(httpRequest, httpResponse)
          httpResponse.setStatus(200)
        else
          httpResponse.setStatus(501)
        end

      else
        httpResponse.setStatus(501)
      end
  
      baseRequest.setHandled(true)
    end

    def setKeepAlive(httpRequest, httpResponse)
      ka = httpRequest.getHeader('Connection')
      if ka && ka.downcase == 'keep-alive'
        httpResponse.addHeader('Connection', 'Keep-Alive')
        return true
      else
        return false
      end
    end

    def setupInput(parent, output_queue)
      @parent = parent
      @codec = parent.instance_variable_get(:@codec)
      @output_queue = output_queue
    end
  end

  public
  def decorate(event)
    super(event)
  end

  public
  def run(output_queue)
    @server = Java::org.eclipse.jetty.server.Server.new(
      Java::java.net.InetSocketAddress.new(@host, @port)
    )
    @server.setAttribute(
      'org.eclipse.jetty.server.Request.maxFormContentSize',
      @maxFormSize
    )

    @server.getConnectors()[0].setAcceptQueueSize(@acceptQueueSize)
    
    handler = LogHandler.new
    handler.setupInput(self, output_queue)
    @server.setHandler(handler)
    @server.start
    @server.join
  end # def run

  public
  def teardown
    @server.doStop
  end # def teardown
end # class LogStash::Inputs::Http
