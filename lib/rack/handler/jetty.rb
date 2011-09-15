require 'rack_jetty/java_input'
require 'rack_jetty/servlet_handler'
require 'java'

java_import 'org.mortbay.jetty.NCSARequestLog'
java_import 'org.mortbay.jetty.Server'
java_import 'org.mortbay.jetty.bio.SocketConnector'
java_import 'org.mortbay.jetty.handler.DefaultHandler'
java_import 'org.mortbay.jetty.handler.HandlerCollection'
java_import 'org.mortbay.jetty.handler.ContextHandlerCollection'
java_import 'org.mortbay.jetty.handler.RequestLogHandler'
java_import 'org.mortbay.jetty.handler.StatisticsHandler'
java_import 'org.mortbay.jetty.nio.SelectChannelConnector'
java_import 'org.mortbay.jetty.security.SslSocketConnector'
java_import 'org.mortbay.management.MBeanContainer'
java_import 'org.mortbay.thread.QueuedThreadPool'
java_import 'java.lang.management.ManagementFactory'


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
        thread_pool = QueuedThreadPool.new
        thread_pool.setMinThreads((options[:Min_threads] || 10).to_i)
        thread_pool.setMaxThreads((options[:Max_threads] || 200).to_i)
        thread_pool.setLowThreads((options[:Low_threads] || 50).to_i)
        thread_pool.setSpawnOrShrinkAt(2)

        @jetty = Java::org.mortbay.jetty.Server.new
        @jetty.setThreadPool(thread_pool)
        @jetty.setGracefulShutdown(1000)

        stats_on = options[:With_Stats] || true

        if options[:Use_NIO] || true
          http_connector = SelectChannelConnector.new
          http_connector.setLowResourcesConnections(20000)
        else
          http_connector = SocketConnector.new
        end
        http_connector.setHost(options[:Host] || 'localhost')
        http_connector.setPort(options[:Port].to_i)
        http_connector.setMaxIdleTime(30000)
        http_connector.setAcceptors(2)
        http_connector.setStatsOn(stats_on)
        http_connector.setLowResourceMaxIdleTime(5000)
        http_connector.setAcceptQueueSize((options[:Accept_queue_size] || thread_pool.getMaxThreads).to_i)
        http_connector.setName("HttpListener")
        @jetty.addConnector(http_connector)

        if options[:Ssl_Port] && options[:Keystore] && options[:Key_password]
          https_connector = SslSocketConnector.new

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
          @jetty.addConnector(http_connector)
        end

        bridge = RackJetty::ServletHandler.new
        bridge.handler = self

        handlers = HandlerCollection.new
        handlers.addHandler(bridge)

        if options[:Request_log] || options[:Request_log_path]
          request_log_handler = RequestLogHandler.new

          request_log_handler.setRequestLog(options[:Request_log] || NCSARequestLog.new(options[:Request_log_path]))
          handlers.addHandler(request_log_handler)
        end
        if stats_on
          mbean_container = MBeanContainer.new(ManagementFactory.getPlatformMBeanServer)

          @jetty.getContainer.addEventListener(mbean_container)
          mbean_container.start

          stats_handler = StatisticsHandler.new
          stats_handler.addHandler(handlers)
          @jetty.addHandler(stats_handler)
        else
          @jetty.addHandler(handlers)
        end
        @jetty.start
      end
      
      def running?
        @jetty && @jetty.isStarted
      end
      
      def stopped?
        !@jetty || @jetty.isStopped
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
