#!/usr/bin/env ruby

require 'pp'
require 'trollop'
require 'highline'
require 'shellwords'

# Have to do it this way to avoid the vendored 'sysexits' under OSX.
gem 'sysexits'
require 'sysexits'

require 'mongrel2'
require 'mongrel2/config'


# A tool for displaying information about a directory's records and schema artifacts.
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
	@command_help = {}

	### Add a help string for the given +command+.
	def self::help( command, helpstring=nil )
		if helpstring
			@command_help[ command.to_sym ] = helpstring
		end

		return @command_help[ command.to_sym ]
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
		end

		self.new( opts ).run( command, *oparser.leftovers )
		exit :ok

	rescue => err
		Mongrel2.logger.fatal "Oops: %s: %s" % [ err.class.name, err.message ]
		Mongrel2.logger.debug { '  ' + err.backtrace.join("\n  ") }

		exit :software_error
	end


	### Create and configure a command-line option parser for the command.
	### @return [Trollop::Parser] the option parser
	def self::make_option_parser
		progname = File.basename( $0 )
		default_configdb = Mongrel2::DEFAULT_CONFIG_URI
		loglevels = Mongrel2::Logging::LOG_LEVELS.
			sort_by {|name,lvl| lvl }.
			collect {|name,lvl| name.to_s }.
			join( ', ' )
		commands = self.public_instance_methods( false ).
			map( &:to_s ).
			grep( /_command$/ ).
			map {|methodname| methodname.sub(/_command$/, '') }.
			sort
		col1len = commands.map( &:length ).max
		command_table = commands.collect do |cmd|
			helptext = help( cmd.to_sym ) or next # no help == invisible command
			"%*s  %s" % [
				col1len,
				self.prompt.color(cmd, :key),
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
		self.send( "#{command}_command", *args )
	rescue NoMethodError => err
		self.prompt.say( self.prompt.color("No such command", :error) )
		exit :usage
	end


	#
	# Commands
	#

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
		servername = args.shift or raise "No server specified."
		server = Mongrel2::Config::Server.filter( :name => servername ).first or
			raise "No such server %p" % [ servername ]

		self.prompt.say( self.prompt.color('HOSTS:', :header) )
		pp server
	end
	help :hosts, "Lists the hosts in a server."

end # class Mongrel2::M2SHCommand


Mongrel2::M2SHCommand.run( ARGV.dup )

