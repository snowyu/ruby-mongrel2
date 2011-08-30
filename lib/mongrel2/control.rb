#!/usr/bin/ruby

require 'zmq'
require 'yajl'
require 'tnetstring'

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/mixins'


# An interface to the Mongrel2 control port.
#
# == Author/s
# * Michael Granger <ged@FaerieMUD.org>
#
# == References
# (http://mongrel2.org/static/mongrel2-manual.html#x1-380003.8)
class Mongrel2::Control

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


	### Send a request that the server perform the +command+ with the specified +options+ 
	### hash and return the results.
	def request( command, options={} )
		msg = TNetstring.dump([ command, options ])
		self.socket.send( msg )
		response = self.socket.recv
		return TNetstring.parse( response ).first
	end


	### Close the control port connection.
	def close
		self.socket.close
	end

end # class Mongrel2::Control

# vim: set nosta noet ts=4 sw=4:

