require 'rack_jetty/java_input'
require 'rack_jetty/servlet_handler'

module Rack
  module Handler
    class Jetty
      attr_reader :app
      attr_reader :options

      def initialize(app, options={})
        @app = app
        @options = options
      end

      def self.run(app, options = {})
        new(app,options).run()
      end

      def run()
        if options.has_key?(:ssl)
          ssl = options[:ssl]
          if ssl.is_a?(Hash) && ssl[:keystore] && ssl[:keystore_password]
            @connector = Java::org.mortbay.jetty.security.SslSocketConnector.new
            @connector.set_keystore(ssl[:keystore])
            @connector.set_password(ssl[:keystore_password])
            @connector.set_key_password(ssl[:key_password])
            @connector.set_truststore(ssl[:truststore] || ssl[:keystore])
            @connector.set_trust_password(
              ssl[:truststore_password] || ssl[:keystore_password]
            )
          else
            raise ArgumentError.new(
              "SSL requested but keystore, keystore password or key password" + 
              "not provided"
            )
          end
        end

        @connector ||= Java::org.mortbay.jetty.bio.SocketConnector.new

        @connector.set_host(options[:Host])
        @connector.set_port(options[:Port].to_i)

        @jetty = Java::org.mortbay.jetty.Server.new
        @jetty.addConnector(@connector)

        bridge = RackJetty::ServletHandler.new
        bridge.handler = self

        @jetty.set_handler(bridge)
        @jetty.start
      end
      
      def running?
        @jetty && @jetty.is_started
      end

      def stopped?
        !@jetty || @jetty.is_stopped
      end

      def stop()
        @jetty && @jetty.stop
      end

    end
  end
end

