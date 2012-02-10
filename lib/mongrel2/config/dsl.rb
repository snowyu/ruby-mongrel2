#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )
require 'mongrel2/config' unless defined?( Mongrel2::Config )

# The Mongrel2::Config::DSL module is a mixin that will add functions to your
# namespace that can create and replace configuration items in the current
# Mongrel2 config database.
#
# If you're creating a config that will be run standalone, you'll need to
# point the config classes to the right database before using the DSL:
#
#     #!/usr/bin/env ruby
#
#     require 'mongrel2'
#     require 'mongrel2/config'
#     require 'mongrel2/config/dsl'
#
#     Mongrel2::Config.configure( configdb: 'myconfig.sqlite' )
#     include Mongrel2::Config::DSL
#
#     server 'myserver' do
#         # ...
#     end
#
# If you're creating a config to be loaded via m2sh.rb, you don't need any of
# that, as m2sh.rb provides its own prelude before loading the config.
#
# == DSL Syntax
#
# There is basically one directive for each configuration item, and the layout follows the basic structure described in the {Mongrel2 manual}[http://mongrel2.org/static/book-finalch4.html#x6-260003.4].
#
#
# === server
#
#     server <uuid> { <server config block> }
#
# This creates or replaces the server associated with the specified +uuid+. The
# <tt>server config block</tt> has directives for each of the server attributes,
# each of which corresponds to one of the columns in the configuration database's
# +server+ table (descriptions largely borrowed from the
# manual[http://mongrel2.org/static/book-finalch4.html#x6-270003.4.1]):
#
# [chroot +directory+]   The directory that Mongrel2 should chroot to at startup.
#                        Defaults to <tt>/var/www</tt>.
# [access_log +path+]    The path to the access log file relative to the +chroot+.
#                        Usually starts with a ‘/’. Defaults to
#                        <tt>/logs/access.log</tt>.
# [error_log +path+]     The error log file, just like +access_log+. Defaults to
#                        <tt>/logs/error.log</tt>.
# [pid_file +path+]      The path to the PID file, relative to the +chroot+.
#                        Defaults to <tt>/run/mongrel2.pid</tt>.
# [default_host +name+]  Which +host+ in the server to use as the default if
#                        the +Host+ header doesn't match any host's +matching+
#                        attribute. Defaults to <tt>localhost</tt>.
# [bind_addr +ipaddr+]   The IP address to bind to; default is <tt>0.0.0.0</tt>.
# [port +int+]           The port the server should listen on for new connections;
#                        defaults to <tt>8888</tt>.
#
# The server will be saved immediately upon exiting the block, and will return the
# saved Mongrel2::Config::Server object.
#
#
# === host
#
#     host <name> { <host config block> }
#
# This creates or replaces the named Host within a +server+ block. Inside the
# <tt>host config block</tt>, there are directives for further configuring the
# Host, adding Routes, and setting up Handler, Proxy, and Directory targets
# for Routes.
#
# [matching +pattern+]     This is a pattern that’s used to match incoming
#                          <tt>Host</tt> headers for routing purposes.
# [maintenance +boolean+]  This is a (currently unused) setting that will display
#                          a "down for maintenance" page.
#
# The rest of the block will likely be concerned with setting up the routes for
# the host using the +route+, +handler+, +directory+, and +proxy+ directives, e.g.:
#
#     host 'main' do
#       matching 'example.com'
#       maintenance false
#
#       # Hello world application
#       route '/hello', handler('tcp://127.0.0.1:9999', 'helloworld-handler')
#       # Contact form handler
#       route '/contact', handler('tcp://127.0.0.1:9995', 'contact-form')
#
#       # reverse proxy for a non-mongrel application listening on 8080
#       route '/api', proxy('127.0.0.1', 8080)
#     end
#
# Since the block is just a Ruby block, and each directive returns the configured
# object, you can use conditionals, assign targets to variables to be reused later,
# etc:
#
#     require 'socket'
#
#     host 'test' do
#       matching 'testing.example.com'
#
#       # Decide which address to listen to, and which app to use based on which
#       # host the config is running on.
#       testhandler =
#         if Socket.gethostname.include?( 'example.com' )
#           handler 'tcp://0.0.0.0:31218', 'ci-builder'
#         else
#           handler 'tcp://127.0.0.1', 'unittest-builder'
#         end
#
#       route '', testhandler
#     end
#
# === route
#
#     route <pattern>, <target>, [<opts>]
#
# Create a route in the current host that will match the given +pattern+ and
# pass the request to the specified +target+, which should be a Handler, a
# Directory, or a Proxy.
#
# The only current option is +reversed+, which (if +true+) means that the pattern
# is bound to the end rather than the beginning of the path.
#
# It returns the configured Route object.
#
#     route '/demo', handler('tcp://localhost:9400', 'demo-handler')
#
#     # Use the same image-factory handler for each image type
#     image_handler = handler('tcp://localhost:9300', 'image-factory')
#     route '.jpg', image_handler, reverse: true
#     route '.gif', image_handler, reverse: true
#     route '.png', image_handler, reverse: true
#     route '.ico', image_handler, reverse: true
#
# === handler
#
#     handler <send_spec>, <send_ident>, [<recv_spec>[, <recv_ident>]], [<options>]
#
# Create a Handler that will send and receive on +send_spec+ and +recv_spec+ 0mq
# sockets, respectively. The application's +send_ident+ is an identifier (usually
# a UUID) that will be used to register the send socket so messages persist
# through crashes.
#
# If no +recv_spec+ is given, the port immediately below the +send_spec+ is used.
#
# The +recv_ident+ is another UUID if you want the receive socket to subscribe to
# its messages. Handlers properly mention the send_ident on all returned
# messages, so you should either set this to nothing and don’t subscribe, or set
# it to the same as +send_ident+.
#
# Valid +options+ for Handlers are:
#
# [raw_payload +boolean+]  ?
# [protocol +name+]        The protocol used to communicate with the handler. Should
#                          be either 'tnetstring' or 'json' (the default).
#
# As with the other directives, +handler+ returns the newly-saved Handler object.
#
#
# === directory
#
#
#
# === proxy
#
#
#
# === filter
#
#
#
# === setting
#
#
#
# === mimetype
#
#
#
#
# == Example
#
# This is the mongrel2.org config re-expressed in the Ruby DSL:
#
#     # the server to run them all
#     server '2f62bd5-9e59-49cd-993c-3b6013c28f05' do
#
#         access_log   "/logs/access.log"
#         error_log    "/logs/error.log"
#         chroot       "./"
#         pid_file     "/run/mongrel2.pid"
#         default_host "mongrel2.org"
#         name         "main"
#         port         6767
#
#         # your main host
#         host "mongrel2.org" do
#
#             # a sample of doing some handlers
#             route '@chat', handler(
#                 'tcp://127.0.0.1:9999',
#                 '54c6755b-9628-40a4-9a2d-cc82a816345e',
#                 'tcp://127.0.0.1:9998'
#             )
#
#             route '/handlertest', handler(
#                 'tcp://127.0.0.1:9997',
#                 '34f9ceee-cd52-4b7f-b197-88bf2f0ec378',
#                 'tcp://127.0.0.1:9996'
#             )
#
#             # a sample proxy route
#             web_app_proxy = proxy( '127.0.0.1', 8080 )
#
#             route '/chat/', web_app_proxy
#             route '/', web_app_proxy
#
#             # here's a sample directory
#             test_directory = directory(
#                 'tests/',
#                 :index_file => 'index.html',
#                 :default_ctype => 'text/plain'
#             )
#
#             route '/tests/', test_directory
#             route '/testsmulti/(.*.json)', test_directory
#
#             chat_demo_dir = directory(
#                 'examples/chat/static/',
#                 :index_file => 'index.html',
#                 :default_ctype => 'text/plain'
#             )
#
#             route '/chatdemo/', chat_demo_dir
#             route '/static/', chat_demo_dir
#
#             route '/mp3stream', handler(
#                 'tcp://127.0.0.1:9995',
#                 '53f9f1d1-1116-4751-b6ff-4fbe3e43d142',
#                 'tcp://127.0.0.1:9994'
#             )
#         end
#
#     end
#
#     settings(
#         "zeromq.threads"         => 1,
#         "upload.temp_store"      => "/home/zedshaw/projects/mongrel2/tmp/upload.XXXXXX",
#         "upload.temp_store_mode" => "0666"
#     )
#
module Mongrel2::Config::DSL


	# A decorator object that provides the DSL-ish interface to the various Config
	# objects. It derives its interface on the fly from columns of the class it's
	# created with and a DSLMethods mixin if the target class defines one.
	class Adapter
		include Mongrel2::Loggable

		### Create an instance of the specified +targetclass+ using the specified +opts+
		### as initial values. The first pair of +opts+ will be used in the filter to
		### find any previous instance and delete it.
		def initialize( targetclass, opts={} )
			self.log.debug "Wrapping a %p" % [ targetclass ]
			@targetclass = targetclass

			# Use the first pair as the primary key
			unless opts.empty?
				first_pair = Hash[ *opts.first ]
				@targetclass.filter( first_pair ).destroy
			end

			@target = @targetclass.new( opts )
			self.decorate_with_column_declaratives( @target )
			self.decorate_with_custom_declaratives( @targetclass )
		end


		######
		public
		######

		# The decorated object
		attr_reader :target


		### Backport the singleton_class method if there isn't one.
		unless instance_methods.include?( :singleton_class )
			def singleton_class
				class << self; self; end
			end
		end

		### Add a declarative singleton method for the columns of the +adapted_object+.
		def decorate_with_column_declaratives( adapted_object )
			columns = adapted_object.columns
			self.log.debug "  decorating for columns: %s" % [ columns.map( &:to_s ).sort.join(', ') ]

			columns.each do |colname|

				# Create a method that will act as a writer if called with an
				# argument, and a reader if not.
				method_body = Proc.new do |*args|
					if args.empty?
						self.target.send( colname )
					else
						self.target.send( "#{colname}=", *args )
					end
				end

				# Install the method
				self.singleton_class.send( :define_method, colname, &method_body )
			end
		end


		### Mix in methods defined by the "DSLMethods" mixin defined by the class
		### of the object being adapted.
		def decorate_with_custom_declaratives( objectclass )
			return unless objectclass.const_defined?( :DSLMethods )
			self.singleton_class.send( :include, objectclass.const_get(:DSLMethods) )
		end


	end # class Adapter


	### Create a Mongrel2::Config::Server with the specified +uuid+, evaluate
	### the block (if given) within its context, and return it.
	def server( uuid, &block )
		adapter = nil

		Mongrel2.log.info "Entering transaction for server %p" % [ uuid ]
		Mongrel2::Config.db.transaction do
			Mongrel2.log.info "  ensuring db is set up..."
			Mongrel2::Config.init_database

			# Set up the options hash with the UUID and reasonable defaults
			# for everything else
			server_opts = {
				uuid:         uuid,
			    access_log:   "/logs/access.log",
			    error_log:    "/logs/error.log",
			    pid_file:     "/run/mongrel2.pid",
			    default_host: "localhost",
			    port:         8888,
			}

			Mongrel2.log.debug "Server [%s] (block: %p)" % [ uuid, block ]
			adapter = Adapter.new( Mongrel2::Config::Server, server_opts )
			adapter.instance_eval( &block ) if block

			Mongrel2.log.info "  saving server %p..." % [ uuid ]
			adapter.target.save
		end

		return adapter.target
	end


	### Set the value of one of the 'Tweakable Expert Settings'
	def setting( key, val )
		Mongrel2::Config.init_database
		setting = Mongrel2::Config::Setting.find_or_create( key: key )
		setting.value = val
		setting.save
	end


	### Set some 'Tweakable Expert Settings' en masse
	def settings( hash )
		result = []

		Mongrel2::Config.db.transaction do
			hash.each do |key, val|
				result << setting( key, val )
			end
		end

		return result
	end


	### Set up a mimetype mapping between files with the given +extension+ and +mimetype+.
	def mimetype( extension, mimetype )
		Mongrel2::Config.init_database

		type = Mongrel2::Config::Mimetype.find_or_create( extension: extension )
		type.mimetype = mimetype
		type.save

		return type
	end


	### Set some mimetypes en masse.
	def mimetypes( hash )
		result = []

		Mongrel2::Config.db.transaction do
			hash.each do |ext, mimetype|
				result << mimetype( ext, mimetype )
			end
		end

		return result
	end

end # module Mongrel2::Config::DSL

