#!/usr/bin/ruby

require 'zmq'
require 'yajl'
require 'tnetstring'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'


# An interface to the Mongrel2 control port.
#
# == References
# (http://mongrel2.org/static/mongrel2-manual.html#x1-380003.8)
class Mongrel2::Control
	include Mongrel2::Loggable

	# The default zmq connection spec to use when talking to a mongrel2 server
	DEFAULT_PORT = 'ipc://run/control'


	### Create a new control port object using the current configuration.
	def initialize( port=DEFAULT_PORT )
		@ctx = Mongrel2.zmq_context
		@socket = @ctx.socket( ZMQ::REQ )
		@socket.connect( port.to_s )
	end


	######
	public
	######

	# The control port ZMQ::REQ socket
	attr_reader :socket


	### Stops the server using a SIGINT.
	def stop
		self.request( :stop )
	end


	### Reloads the server using a SIGHUP.
	def reload
		self.request( :reload )
	end


	### Terminates the server with SIGTERM.
	def terminate
		self.request( :terminate )
	end


	### Prints out a simple help message.
	def help
		self.request( :help )
	end


	### Returns the server’s UUID as a String.
	def uuid
		self.request( :uuid )
	end


	### More information about the server.
	def info
		self.request( :info )
	end


	### Returns a Hash of all the currently running tasks and what they’re doing, keyed
	### by conn_id.
	def tasklist
		self.request( :status, :what => 'tasks' )
	end


	### Dumps a JSON dict that matches connections IDs (same ones your handlers 
	### get) to the seconds since their last ping. In the case of an HTTP 
	### connection this is how long they’ve been connected. In the case of a 
	### JSON socket this is the last time a ping message was received.
	def conn_status
		self.request( :status, :what => 'net' )
	end


	### Prints the unix time the server thinks it’s using. Useful for synching.
	def time
		response = self.request( :time )
		response.each do |row|
			row[ :time ] = Time.at( row.delete(:time).to_i ) if row[:time]
		end

		return response
	end


	### Does a forced close on the socket that is at the specified +conn_id+.
	def kill( conn_id )
		self.request( :kill, :id => conn_id )
	end


	### Shuts down the control port permanently in case you want to keep it from 
	### being accessed for some reason.
	def control_stop
		self.request( :control_stop )
	end


	### Send a raw request to the server, asking it to perform the +command+ with the specified
	### +options+ hash and return the results.
	def request( command, options={} )
		msg = TNetstring.dump([ command, options ])
		self.log.debug "Request: %p" % [ msg ]
		self.socket.send( msg )

		response = self.socket.recv
		self.log.debug "Response: %p" % [ response ]
		return unpack_response( response )
	end


	### Close the control port connection.
	def close
		self.socket.close
	end


	#######
	private
	#######

	### Unpack a Mongrel2 Control Port response (TNetString encoded table) as an
	### Array of Hashes.
	def unpack_response( response )
		table = TNetstring.parse( response ).first
		self.log.debug "Unpacking response: %p" % [ table ]

		# Success
		if table.key?( 'headers' )
			headers, rows = table.values_at( 'headers', 'rows' )
			headers.map!( &:to_sym )

			return rows.collect do |row|
				Hash[ [headers, row].transpose ]
			end

		# Error
		elsif table.key?( 'code' )
			# {"code"=>"INVALID_ARGUMENT", "error"=>"Invalid argument type."}
			raise Mongrel2::ControlError.new( table['code'], table['error'] )

		else
			raise ScriptError, "Don't know how to handle response: %p" % [ table ]
		end
	end

end # class Mongrel2::Control

# vim: set nosta noet ts=4 sw=4:

