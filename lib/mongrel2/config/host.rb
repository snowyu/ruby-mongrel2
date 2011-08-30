#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# Mongrel2 Host configuration class
class Mongrel2::Config::Host < Mongrel2::Config( :host )

	### As of Mongrel2/1.7.5:
	# CREATE TABLE host (id INTEGER PRIMARY KEY, 
	#     server_id INTEGER,
	#     maintenance BOOLEAN DEFAULT 0,
	#     name TEXT,
	#     matching TEXT);

	one_to_many :routes

	### DSL methods for the Server context besides those automatically-generated from its
	### columns.
	module DSLMethods

		### Add a Mongrel2::Config::Route to the Host object.
		def route( path, target, opts={} )
			self.target.save
			Mongrel2.log.debug "Route %s -> %p [%p]" % [ path, target, opts ]

			args = { :path => path, :target => target }
			args.merge!( opts )
			route = Mongrel2::Config::Route.new( args )

			self.target.add_route( route )
		end


		# These are route _arguments_, so they need to be declared in Host's scope rather
		# than Route's.

		### Create a new Mongrel2::Config::Directory object for the specified +base+ and
		### return it.
		def directory( base, index_file, default_ctype='text/plain', opts={} )
			opts.merge!( :base => base, :index_file => index_file, :default_ctype => default_ctype )
			return Mongrel2::Config::Directory.create( opts )
		end


		### Create a new Mongrel2::Config::Proxy object for the specified +addr+ and
		### +port+ and return it.
		def proxy( addr, port=80 )
			return Mongrel2::Config::Proxy.create( :addr => addr, :port => port )
		end


		### Create a new Mongrel2::Config::Handler object with the specified +send_spec+, 
		### +send_ident+, +recv_spec+, +recv_ident+, and +options+ and return it.
		def handler( send_spec, send_ident, recv_spec, recv_ident='', options={} )
			# Shift the opts hash over if the recv_ident was omitted
			if recv_ident.is_a?( Hash )
				options = recv_ident
				recv_ident = ''
			end

			options.merge!(
				:send_spec  => send_spec,
				:send_ident => send_ident,
				:recv_spec  => recv_spec,
				:recv_ident => recv_ident
			)

			Mongrel2.log.debug "Creating handler with options: %p" % [ options ]
			return Mongrel2::Config::Handler.create( options )
		end

	end # module DSLMethods

end # class Mongrel2::Config::Host

