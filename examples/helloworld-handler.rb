#!/usr/bin/env ruby

require 'logger'
require 'mongrel2/config'
require 'mongrel2/handler'

# A dumb, dead-simple example that just returns a plaintext 'Hello' document.
class HelloWorldHandler < Mongrel2::Handler

	### The main method to override -- accepts requests and returns responses.
	def handle( request )
		response = request.response

		response.status = 200
		response.headers.content_type = 'text/plain'
		response.puts "Hello, world, it's #{Time.now}!"

		return response
	end

end # class HelloWorldHandler

configdb = ARGV.shift || 'examples.sqlite'

# Log to a file instead of STDERR for a bit more speed.
# Mongrel2.log = Logger.new( 'hello-world.log' )
Mongrel2.log.level = Logger::DEBUG

# Point to the config database, which will cause the handler to use
# its ID to look up its own socket info.
Mongrel2::Config.configure( configdb: configdb )
HelloWorldHandler.run( 'helloworld-handler' )

