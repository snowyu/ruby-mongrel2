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
		# response.keepalive = false
		return response
	end

end # class HelloWorldHandler

Mongrel2.log = Logger.new( 'hello-world.log' )
Mongrel2.log.level = Logger::INFO

# Point to the config database, which will cause the handler to use
# its ID to look up its own socket info.
Mongrel2::Config.configure( :configdb => 'examples.sqlite' )
HelloWorldHandler.run( 'helloworld-handler' )

