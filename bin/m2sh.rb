#!/usr/bin/env ruby

require 'pp'
require 'shellwords'
require 'tnetstring'

require 'trollop'
require 'highline'

# Have to do it this way to avoid the vendored 'sysexits' under OSX.
gem 'sysexits'
require 'sysexits'

require 'mongrel2'
require 'mongrel2/config'


# A tool for interacting with a Mongrel2 config database and server
#
#   [√]    load  Load a config.
#   [√]  config  Alias for load.
#   [ ]   shell  Starts an interactive shell.
#   [√]  access  Prints the access log.
#   [√] servers  Lists the servers in a config database.
#   [√]   hosts  Lists the hosts in a server.
#   [√]  routes  Lists the routes in a host.
#   [√]  commit  Adds a message to the log.
#   [√]     log  Prints the commit log.
#   [√]   start  Starts a server.
#   [ ]    stop  Stops a server.
#   [ ]  reload  Reloads a server.
#   [ ] running  Tells you what's running.
#   [ ] control  Connects to the control port.
#   [√] version  Prints the Mongrel2 and m2sh version.
#   [√]    help  Get help, lists commands.
#   [ ]    uuid  Prints out a randomly generated UUID.
#
class Mongrel2::M2SHCommand
	extend ::Sysexits
	include Sysexits,
	        Mongrel2::Loggable,
	        Mongrel2::Constants

	COLOR_SCHEME = HighLine::ColorScheme.new do |scheme|
		scheme[:header]	   = [ :bold, :yellow ]
		scheme[:subheader] = [ :bold, :white ]
		scheme[:key]	   = [ :white ]
		scheme[:value]	   = [ :bold, :white ]
		scheme[:error]	   = [ :red ]
		scheme[:warning]   = [ :yellow ]
		scheme[:message]   = [ :reset ]
	end

	# Help for commands, keyed by command name
	@command_help = Hash.new {|h,k| h[k] = { :desc => '', :usage => ''} }

	### Add a help string for the given +command+.
	def self::help( command, helpstring=nil )
		if helpstring
			@command_help[ command.to_sym ][:desc] = helpstring
		end

		return @command_help[ command.to_sym ][:desc]
	end


	### Add/fetch the +usagestring+ for +command+.
	def self::usage( command, usagestring=nil )
		if usagestring
			prefix = usagestring[ /\A(\s+)/, 1 ]
			usagestring.gsub!( /^#{prefix}/m, '' ) if prefix

			@command_help[ command.to_sym ][:usage] = usagestring
		end

		return @command_help[ command.to_sym ][:usage]
	end


	@prompt = nil

	### Return the global Highline prompt object, creating it if necessary.
	def self::prompt
		unless @prompt
			@prompt = HighLine.new
			@prompt.wrap_at = @prompt.output_cols - 10
		end

		return @prompt
	end


	### Run the utility with the given +args+.
	def self::run( args )
		HighLine.color_scheme = COLOR_SCHEME

		oparser = self.make_option_parser
		opts = Trollop.with_standard_exception_handling( oparser ) do
			oparser.parse( args )
		end

		command = oparser.leftovers.shift
		if command.nil? || command == 'shell'
			$stderr.puts "This version doesn't run in shell mode yet."
			exit :unavailable
		elsif command == 'help'
			self.show_help( oparser )
			exit :ok
		end

		self.new( opts ).run( command, *oparser.leftovers )
		exit :ok

	rescue => err
		Mongrel2.logger.fatal "Oops: %s: %s" % [ err.class.name, err.message ]
		Mongrel2.logger.debug { '  ' + err.backtrace.join("\n  ") }

		exit :software_error
	end


	### Show output for the 'help' command.
	def self::show_help( oparser )
		command = oparser.leftovers.shift

		# Subcommand help
		if command
			if self.available_commands.include?( command )
				desc = self.prompt.color( self.help(command), :header )
				desc << "\n" << 'Usage: ' << command << ' ' << self.usage(command) << "\n"
				self.prompt.say( desc )
			else
				self.prompt.say( %{<%= color "No such command '#{command}'", :error %>} )
			end

		# Help by itself is the same as -h
		else
			oparser.educate( $stderr )
		end

	end


	### Return an Array of the available commands.
	def self::available_commands
		return self.public_instance_methods( false ).
			map( &:to_s ).
			grep( /_command$/ ).
			map {|methodname| methodname.sub(/_command$/, '') }.
			sort
	end


	### Create and configure a command-line option parser for the command.
	### Returns a Trollop::Parser.
	def self::make_option_parser
		progname = File.basename( $0 )
		default_configdb = Mongrel2::DEFAULT_CONFIG_URI

		# Make a list of the log level names and the available commands
		loglevels = Mongrel2::Logging::LOG_LEVELS.
			sort_by {|name,lvl| lvl }.
			collect {|name,lvl| name.to_s }.
			join( ', ' )
		commands = self.available_commands

		# Build the command table
		col1len = commands.map( &:length ).max
		command_table = commands.collect do |cmd|
			helptext = self.help( cmd.to_sym ) or next # no help == invisible command
			"%s  %s" % [
				self.prompt.color(cmd.rjust(col1len), :key),
				self.prompt.color(helptext, :value)
			]
		end


		return Trollop::Parser.new do
			banner "Mongrel2 (Ruby) Shell has these commands available:"

			text ''
			command_table.each {|line| text(line) }
			text ''

			text 'Global Options'
			opt :config, "Specify the configfile to use.",
				:default => DEFAULT_CONFIG_URI
			text ''

			text 'Other Options:'
			opt :debug, "Turn debugging on. Also sets the --loglevel to 'debug'."
			opt :loglevel, "Set the logging level. Must be one of: #{loglevels}",
				:default => Mongrel2::Logging::LOG_LEVEL_NAMES[ Mongrel2.logger.level ]
		end
	end


	#################################################################
	###	I N S T A N C E   M E T H O D S
	#################################################################

	### Create a new instance of the command and set it up with the given
	### +options+.
	def initialize( options )
		Mongrel2.logger.formatter = Mongrel2::Logging::ColorFormatter.new( Mongrel2.logger )
		@options = options

		if @options.debug
			$DEBUG = true
			$VERBOSE = true
			Mongrel2.logger.level = Logger::DEBUG
		elsif @options.loglevel
			Mongrel2.logger.level = Mongrel2::Logging::LOG_LEVELS[ @options.loglevel ]
		end

		Mongrel2::Config.configure( :configdb => @options.config )
	end


	######
	public
	######

	# The Trollop options hash the command will read its configuration from
	attr_reader :options


	# Delegate the instance #prompt method to the class method instead
	define_method( :prompt, &self.method(:prompt) )


	### Display an +object+ highlighted as a header.
	def print_header( object )
		self.prompt.say( self.prompt.color(object.to_s, :header) )
	end


	### Run the command with the specified +command+ and +args+.
	def run( command, *args )
		cmd_method = nil
		begin
			cmd_method = self.method( "#{command}_command" )
		rescue NoMethodError => err
			self.prompt.say( self.prompt.color("No such command", :error) )
			exit :usage
		end

		cmd_method.call( *args )
	end


	#
	# Commands
	#

	### The 'load' command
	def load_command( configfile )
		runspace = Module.new do
			extend Mongrel2::Config::DSL
		end

		self.prompt.say( self.prompt.color("Loading config from #{configfile}", :header) )
		source = File.read( configfile )

		self.prompt.say( "  initializing database" )
		Mongrel2::Config.init_database!

		self.prompt.say( "  running DSL" )
		runspace.module_eval( source, configfile, 0 )
	end
	help :load, "Overwrite the config database with the values from the speciifed CONFIGFILE."
	usage :load, <<-END_USAGE
	CONFIGFILE
	Note: the CONFIGFILE should contain a configuration described using the
	Ruby config DSL, not a Python-ish normal one. m2sh already works perfectly
	fine for loading those.
	END_USAGE


	### The 'config' command
	alias_method :config_command, :load_command
	help :config, "Alias for 'load'."


	### (Undocumented)
	def method_name
		
	end

	### The 'init' command
	def init_command( * )
		if Mongrel2::Config.database_initialized?
			abort "Okay, aborting." unless
				self.prompt.agree( "Are you sure you want to destroy the current config? " )
		end

		self.prompt.say( self.prompt.color("Initializing #{self.options.config}", :header) )
		Mongrel2::Config.init_database!
	end
	help :init, "Initialize a new config database."


	### The 'access' command
	def access_command( logfile='logs/access.log', * )
		#      1$             2$       3$       4$        5$        6$            7$        8$  9$
		# ["localhost", "127.0.0.1", 53420, 1315533812, "GET", "/favicon.ico", "HTTP/1.1", 404, 0]
		# -> [1315533812] 127.0.0.1:53420 localhost "GET /favicon.ico HTTP/1.1" 404 0
		IO.foreach( logfile ) do |line|
			row, _ = TNetstring.parse( line )
			output = %{[%4$d] %2$s:%3$d %1$s "%5$s %6$s %7$s" %8$03d %9$d} % row

			self.prompt.say( output )
		end
	end
	help :access, "Dump the access log."
	usage :access, "[logfile]\nThe logfile defaults to 'logs/access.log'."


	### The 'servers' command
	def servers_command( * )
		self.prompt.say( self.prompt.color('SERVERS:', :header) )
		Mongrel2::Config.servers.each do |server|
			msg = "%s  [%s]: %s" % [
				self.prompt.color( server.name, :key ),
				server.default_host,
				server.uuid,
			]

			self.prompt.say( msg )
		end
	end
	help :servers, "Lists the servers in a config database."


	### The 'hosts' command
	def hosts_command( *args )
		servername = args.shift

		# Start with all servers, then narrow it down if they specified a server name.
		servers = Mongrel2::Config::Server.dataset
		servers = servers.filter( :name => servername ) if servername

		# Output a section for each server
		servers.each do |server|
			self.prompt.say( self.prompt.color("HOSTS for server #{server.name}:", :header) )

			server.hosts.each do |host|
				line = "%d: %s" % [ host.id, host.name ]
				line << " /%s/" % [ host.matching ] if host.matching != host.name

				self.prompt.say( line )
			end
		end
	end
	help :hosts, "Lists the hosts in a server, or in all servers if none is specified."
	usage :hosts, "[server]"


	### The 'routes' command
	def routes_command( *args )
		servername = args.shift
		hostname = args.shift

		# Start with all hosts, then narrow it down if a server and/or host was given.
		hosts = Mongrel2::Config::Host.dataset
		if servername
			server = Mongrel2::Config::Server[ servername ] or
				raise "No such server '#{servername}'"
			hosts = server.hosts_dataset
		end
		hosts = hosts.filter( :name => hostname ) if hostname

		# Output a section for each host
		hosts.each do |host|
			self.prompt.say( self.prompt.color("ROUTES for host #{host.server.name}/#{host.name}:", :header) )

			host.routes.each do |route|
				self.prompt.say( route.path )
			end
		end

	end
	help :routes, "Show the routes under a host."
	usage :routes, "[server [host]]"


	### The 'commit' command
	def commit_command( *args )
		what, where, why, how = *args
		what ||= ''

		log = Mongrel2::Config::Log.log_action( what, where, why, how )

		self.prompt.say( self.prompt.color("Okay, logged.", :header) )
		self.prompt.say( log.to_s )
	end
	help :commit, "Add a message to the commit log."
	usage :commit, "[WHAT [WHERE [WHY [HOW]]]]"


	### The 'log' command
	def log_command( *args )
		self.prompt.say( self.prompt.color("Log Messages") )
		Mongrel2::Config::Log.order_by( :happened_at ).each do |log|
			self.prompt.say( log.to_s )
		end
	end
	help :log, "Prints the commit log."


	### The 'start' command
	def start_command( *args )
		serverspec = args.shift
		servers = Mongrel2::Config.servers

		raise "No servers are configured." if servers.empty?
		server = nil

		# If there's only one configured server, just make sure if a serverspec was given
		# that it would have matched.
		if servers.length == 1
			server = servers.first if !serverspec ||
				servers.first.values_at( :uuid, :default_host, :name ).include?( serverspec )

		# Otherwise, require an argument and search for the desired server if there is one
		else
			raise "You must specify a server uuid/hostname/name when more " +
			      "than one server is configured." if servers.length > 1 && !serverspec

			server = servers.find {|s| s.uuid == serverspec } ||
			         servers.find {|s| s.default_host == serverspec } ||
			         servers.find {|s| s.name == serverspec }
		end

		raise "No servers match '#{serverspec}'" unless server


		exec( 'mongrel2', Mongrel2::Config.pathname.to_s, server.uuid )
	end
	help :start, "Starts a server."
	usage :start, <<-END_USAGE
	[SERVER]
	If not specified, SERVER is assumed to be the only server entry in the
	current config. If there are more than one, you must specify a SERVER.
	
	The SERVER can be a uuid, hostname, or server name, and are searched for
	in that order.
	END_USAGE


	### The 'version' command
	def version_command( *args )
		self.prompt.say( "<%= color 'Version:', :header %> " + Mongrel2.version_string(true) )
	end
	help :version, "Prints the Ruby-Mongrel2 version."

end # class Mongrel2::M2SHCommand


Mongrel2::M2SHCommand.run( ARGV.dup )

