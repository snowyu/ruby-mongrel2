#!/usr/bin/env ruby

require 'pathname'
require 'logger'
require 'mongrel2/config'
require 'mongrel2/handler'

require 'inversion'

# A handler that just dumps the request it gets from Mongrel2
class RequestDumper < Mongrel2::Handler

	TEMPLATE_DIR = Pathname( __FILE__ ).dirname
	Inversion::Template.configure( :template_paths => [TEMPLATE_DIR] )

	### Pre-load the template before running.
	def initialize( * )
		super
		@template = Inversion::Template.load( 'request-dumper.tmpl' )
	end


	### Handle a request
	def handle( request )
		response = request.response
		template = @template.dup

		template.request = request

		response.status = 200
		response.headers.content_type = 'text/html'
		response.puts( template )

		return response
	end

end # class RequestDumper

Mongrel2.log.level = $DEBUG ? Logger::DEBUG : Logger::INFO
Inversion.log.level = Logger::INFO

# Point to the config database, which will cause the handler to use
# its ID to look up its own socket info.
Mongrel2::Config.configure( :configdb => 'config.sqlite' )
RequestDumper.run( 'request-dumper' )

