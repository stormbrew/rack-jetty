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
        thread_pool = Java::org.mortbay.thread.QueuedThreadPool.new
        thread_pool.setMinThreads((options[:Min_threads] || 10).to_i)
        thread_pool.setMaxThreads((options[:Max_threads] || 200).to_i)
        thread_pool.setLowThreads((options[:Low_threads] || 50).to_i)
        thread_pool.setSpawnOrShrinkAt(2)

        connectors = []
        stats_on = options[:With_Stats] || true

        if options[:Use_NIO] || true
          http_connector = Java::org.mortbay.jetty.nio.SelectChannelConnector.new
          http_connector.setLowResourcesConnections(20000)
        else
          http_connector = Java::org.mortbay.jetty.bio.SocketConnector.new
        end
        http_connector.setHost(options[:Host] || 'localhost')
        http_connector.setPort(options[:Port].to_i)
        http_connector.setMaxIdleTime(30000)
        http_connector.setAcceptors(2)
        http_connector.setStatsOn(stats_on)
        http_connector.setLowResourceMaxIdleTime(5000)
        http_connector.setAcceptQueueSize((options[:Accept_queue_size] || thread_pool.getMaxThreads).to_i)
        http_connector.setName("HttpListener")
        connectors << http_connector

        if options[:Ssl_Port] && options[:Keystore] && options[:Key_password]
          https_connector = Java::org.mortbay.jetty.security.SslSocketConnector.new

          https_connector.setKeystore(options[:Keystore])
          https_connector.setKeystoreType(options[:Keystore_type] || 'JKS')
          https_connector.setKeyPassword(options[:Key_password])
          https_connector.setHost(http_connector.getHost)
          https_connector.setPort(options[:Ssl_Port].to_i)
          https_connector.setMaxIdleTime(30000)
          https_connector.setAcceptors(2)
          https_connector.setStatsOn(stats_on)
          https_connector.setLowResourceMaxIdleTime(5000)
          https_connector.setAcceptQueueSize(http_connector.getAcceptQueueSize)
          https_connector.setName("HttpsListener")
          connectors << https_connector
        end

        @jetty = Java::org.mortbay.jetty.Server.new
        @jetty.setThreadPool(thread_pool)
        @jetty.setConnectors(connectors)
        @jetty.setGracefulShutdown(1000)

        bridge = RackJetty::ServletHandler.new
        bridge.handler = self

        handlers = Java::org.mortbay.jetty.handler.HandlerCollection.new
        context_handlers = Java::org.mortbay.jetty.handler.ContextHandlerCollection.new
        root = Java::org.mortbay.jetty.servlet.Context(context_jandlers, "/", Java::org.mortbay.jetty.servlet.Context::NO_SESSIONS)

        root.addFilter(Java::org.mortbay.jetty.servlet.FilterHolder.new(bridge), "/", 0)
        root.addServlet(Java::org.mortbay.jetty.servlet.DefaultServlet.new, "/")
        handlers.addHandler(context_handlers)
        handlers.addHandler(Java::org.eclipse.jetty.server.handler.DefaultHandler.new)

        if options[:Request_log] || options[:Request_log_path]
          request_log_handler = Java::org.mortbay.jetty.handler.RequestLogHandler.new

          request_log_handler.setRequestLog(options[:Request_log] || Java::org.eclipse.jetty.server.NCSARequestLog.new(options[:Request_log_path]))
          handlers.addHandler(request_log_handler)
        end
        if stats_on
          mbean_container = Java::javax.management.MBeanContainer.new(Java::java.lang.management.ManagementFactory.getPlatformMBeanServer)

          @jetty.getContainer.addEventListener(mbean_container)
          mbean_container.start

          stats_handler = Java::org.mortbay.jetty.handler.StatisticsHandler.new
          stats_handler.addHandler(handlers)
          server.addHandler(stats_handler)
        else
          server.addHandler(handlers)
        end
        puts "Starting jetty"
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

      def destroy()
        @jetty && @jetty.destroy
      end
    end
  end
end
