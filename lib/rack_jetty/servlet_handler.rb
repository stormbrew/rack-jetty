require 'rack'
require 'rack/rewindable_input'
require 'rack_jetty/version'

Dir[::File.join(::File.dirname(__FILE__), 'jars', '*.jar')].each { |jar| require jar }

module RackJetty
  class ServletHandler < Java::org.mortbay.jetty.handler.AbstractHandler
    attr_accessor :handler

    DefaultRackEnv = {
      'rack.version' => ::Rack::VERSION,
      'rack.multithread' => true,
      'rack.multiprocess' => false,
      'rack.run_once' => false,
      'rack.errors' => $stderr,
      'jruby.version' => JRUBY_VERSION,
      'rack_jetty.version' => RackJetty::VERSION,
      'SCRIPT_NAME' => '',
    }

    def handle(target, request, response, dispatch)
      begin
        env = DefaultRackEnv.merge({
          'rack.input' => Rack::RewindableInput.new(JavaInput.new(request.get_input_stream)),
          'rack.url_scheme' => request.get_scheme,
          'CONTENT_TYPE' => request.get_content_type,
          'CONTENT_LENGTH' => request.get_content_length, # some post-processing done below
          'REQUEST_METHOD' => request.get_method || "GET",
          'REQUEST_URI' => request.getRequestURI,
          'PATH_INFO' => request.get_path_info,
          'QUERY_STRING' => request.get_query_string || "",
          'SERVER_NAME' => request.get_server_name || "",
          'REMOTE_HOST' => request.get_remote_host || "",
          'REMOTE_ADDR' => request.get_remote_addr || "",
          'REMOTE_USER' => request.get_remote_user || "",
          'SERVER_PORT' => request.get_server_port.to_s
        })
        env['CONTENT_LENGTH'] = env['CONTENT_LENGTH'] >= 0? env['CONTENT_LENGTH'].to_s : "0"
        request.get_header_names.each do |h|
          next if h =~ /^Content-(Type|Length)$/i
          k = "HTTP_#{h.upcase.gsub(/-/, '_')}"
          env[k] = request.getHeader(h) unless env.has_key?(k)
        end

        # request.get_content_type returns nil if the Content-Type is not included
        # and Rack doesn't expect Content-Type => '' - certain methods will issue 
        # a backtrace if it's passed in. 
        #
        # The correct behaviour is not to include Content-Type in the env hash
        # if it is blank. 
        #
        # https://github.com/rack/rack/issues#issue/40 covers the problem from
        # Rack's end. 
        env.delete('CONTENT_TYPE') if [nil, ''].include?(env['CONTENT_TYPE'])

        status, headers, output = handler.app.call(env)
        
        if (match = %r{^([0-9]{3,3}) +([[:print:]]+)$}.match(status.to_s))
          response.set_status(match[1].to_i, match[2].to_s)
        else
          response.set_status(status.to_i)
        end
        
        headers.each do |k, v|
          case k
          when 'Content-Type'
            response.set_content_type(v)
          when 'Content-Length'
            response.set_content_length(v.to_i)
          else
            response.set_header(k, v)
          end
        end
        
        buffer = response.get_output_stream
        output.each do |s|
          buffer.write(s.to_java_bytes)
        end
      ensure
        request.set_handled(true)
      end
    end
  end
end
