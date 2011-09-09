#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config'

require 'mongrel2/request'
require 'mongrel2/httprequest'
require 'mongrel2/jsonrequest'

# Mongrel2 Handler application class. Instances of this class are the applications
# which connection to one or more Mongrel2 routes and respond to requests.
class Mongrel2::Handler
	include Mongrel2::Loggable


	### Create an instance of the handler using the config from the database with
	### the given +appid+ and run it.
	def self::run( appid )
		Mongrel2.log.info "Running application %p" % [ appid ]
		send_spec, recv_spec = self.connection_info_for( appid )
		Mongrel2.log.info "  config specs: %s <-> %s" % [ send_spec, recv_spec ]
		new( appid, send_spec, recv_spec ).run
	end


	### Return the send_spec and recv_spec for the given +appid+ from the current configuration
	### database. Returns +nil+ if no Handler is configured with +appid+ as its +sender_id+.
	def self::connection_info_for( appid )
		Mongrel2.log.debug "Looking up handler spec for appid %p" % [ appid ]
		hconfig = Mongrel2::Config::Handler.by_send_ident( appid ).first or
			raise ArgumentError, "no handler with a send_ident of %p configured" % [ appid ]

		Mongrel2.log.debug "  found: %s" % [ hconfig.values ]
		return hconfig.send_spec, hconfig.recv_spec
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new instance of the handler with the specified +app_id+, +send_spec+,
	### and +recv_spec+.
	def initialize( app_id, send_spec, recv_spec ) # :notnew:
		@conn = Mongrel2::Connection.new( app_id, send_spec, recv_spec )
	end


	######
	public
	######

	# The handler's Mongrel2::Connection object.
	attr_reader :conn


	### Run the handler.
	def run
		self.log.info "Starting up %p" % [ self ]
		self.set_signal_handlers
		self.start_accepting_requests

		return self # For chaining
	ensure
		self.restore_signal_handlers
		self.log.info "Done: %p" % [ self ]
	end


	### Shut down the handler.
	def shutdown
		self.log.info "Shutting down."
		@conn.close
	end


	### Restart the handler. You should override this if you want to re-establish
	### database connections, flush caches, or other restart-ey stuff.
	def restart
		self.log.info "Restarting"
		old_conn = @conn
		@conn = @conn.dup
		self.log.debug "  conn %p -> %p" % [ old_conn, @conn ]
		old_conn.close
	end


	### Start a loop, accepting a request and handling it.
	def start_accepting_requests
		until @conn.closed?
			req = @conn.receive
			self.log.info "%p from %s:%d" % [ req.class, req.sender_id, req.conn_id ]

			res = self.dispatch_request( req )

			if res
				self.log.debug "  responding with a %p" % [ res.class ]
				@conn.reply( res )
			else
				self.log.debug "  no response; ignoring."
			end
		end
	rescue ZMQ::Error => err
		self.log.error "%p while accepting requests: %s" % [ err.class, err.message ]
		self.log.debug { err.backtrace.join("\n  ") }

		retry unless @conn.closed?
	end


	### Invoke a handler method appropriate for the given +request+.
	def dispatch_request( request )
		if request.is_disconnect?
			self.log.debug "disconnect!"
			return self.handle_disconnect( request )

		else
			return case request
				when Mongrel2::HTTPRequest
					self.handle( request )
				when Mongrel2::JSONRequest
					self.handle_json( request )
				when Mongrel2::XMLRequest
					self.handle_xml( request )
				else
					self.log.error "Unhandled request type %p" % [ request.class ]
					nil
				end
		end
	end


	#
	# :section: Handler Methods
	# These methods are the principle mechanism for defining the functionality of
	# your handler. The logic that dispatches to these methods is all contained in
	# the #dispatch_request method, so if you want to do something completely different,
	# you should override that instead.
	#

	### The main handler function: handle the specified HTTP +request+ (a Mongrel2::Request) and
	### return a response (Mongrel2::Response). If not overridden, this method returns a
	### '204 No Content' response.
	### :group: Handler Methods
	def handle( request )
		self.log.warn "No default handler; responding with '204 No Content'"
		response = request.response
		response.status = HTTP::NO_CONTENT

		return response
	end


	### Handle a JSON message +request+. If not overridden, JSON message ('@route') 
	### requests are ignored.
	### :group: Handler Methods
	def handle_json( request )
		self.log.warn "Unhandled JSON message request (%p)" % [ request.headers[:method] ]
		return nil
	end


	### Handle an XML message +request+. If not overridden, XML message ('<route') 
	### requests are ignored.
	### :group: Handler Methods
	def handle_xml( request )
		self.log.warn "Unhandled XML message request (%p)" % [ request.headers[:method] ]
		return nil
	end


	### Handle a disconnect notice from Mongrel2 via the given +request+. Its return value
	### is ignored.
	### :group: Handler Methods
	def handle_disconnect( request )
		return nil
	end


	#
	# :section: Signal Handling
	# These methods set up some behavior for starting, restarting, and stopping
	# your application when a signal is received. If you don't want signals to
	# be handled, override #set_signal_handlers with an empty method.
	#

	### Set up signal handlers for SIGINT, SIGTERM, SIGINT, and SIGUSR1 that will call the
	### #on_hangup_signal, #on_termination_signal, #on_interrupt_signal, and 
	### #on_user1_signal methods, respectively.
	def set_signal_handlers
		Signal.trap( :HUP,  &self.method(:on_hangup_signal) )
		Signal.trap( :TERM, &self.method(:on_termination_signal) )
		Signal.trap( :INT,  &self.method(:on_interrupt_signal) )
		Signal.trap( :USR1, &self.method(:on_user1_signal) )
	end


	### Restore the default signal handlers
	def restore_signal_handlers
		Signal.trap( :HUP,  :DEFAULT )
		Signal.trap( :TERM, :DEFAULT )
		Signal.trap( :INT,  :DEFAULT )
		Signal.trap( :USR1, :DEFAULT )
	end


	### Handle a HUP signal. The default is to restart the handler.
	def on_hangup_signal( signo )
		self.log.warn "Hangup: reconnecting."
		self.restart
	end


	### Handle a TERM signal. Shuts the handler down after handling any current request/s. Also
	### aliased to #on_interrupt_signal.
	def on_termination_signal( signo )
		self.log.warn "Halting on signal #{signo} (Thread: %p vs. main: %p)" %
			[ Thread.current, Thread.main ]
		self.shutdown
	end
	alias_method :on_interrupt_signal, :on_termination_signal


	### Handle a USR1 signal. Writes a message to the log by default.
	def on_user1_signal( signo )
		self.log.info "Checkpoint: User signal."
	end

end # class Mongrel2::Handler

