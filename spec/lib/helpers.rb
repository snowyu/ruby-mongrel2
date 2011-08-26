#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

begin
	require 'configurability'
rescue LoadError => err
end

require 'rspec'
require 'mongrel2'
require 'mongrel2/config'
require 'spec/lib/constants'

require 'sequel'
require 'sequel/model'
require 'sequel/adapters/sqlite'

### IRb.start_session, courtesy of Joel VanderWerf in [ruby-talk:42437].
require 'irb'
require 'irb/completion'

module IRB # :nodoc:
	def self.start_session( obj )
		unless @__initialized
			args = ARGV
			ARGV.replace( ARGV.dup )
			IRB.setup( nil )
			ARGV.replace( args )
			@__initialized = true
		end

		workspace = WorkSpace.new( obj )
		irb = Irb.new( workspace )

		@CONF[:IRB_RC].call( irb.context ) if @CONF[:IRB_RC]
		@CONF[:MAIN_CONTEXT] = irb.context

		begin
			prevhandler = Signal.trap( 'INT' ) do
				irb.signal_handle
			end

			catch( :IRB_EXIT ) do
				irb.eval_input
			end
		ensure
			Signal.trap( 'INT', prevhandler )
		end

	end
end




### RSpec helper functions.
module Mongrel2::SpecHelpers
	include Mongrel2::TestConstants

	class ArrayLogger
		### Create a new ArrayLogger that will append content to +array+.
		def initialize( array )
			@array = array
		end

		### Write the specified +message+ to the array.
		def write( message )
			@array << message
		end

		### No-op -- this is here just so Logger doesn't complain
		def close; end

	end # class ArrayLogger


	unless defined?( LEVEL )
		LEVEL = {
			:debug => Logger::DEBUG,
			:info  => Logger::INFO,
			:warn  => Logger::WARN,
			:error => Logger::ERROR,
			:fatal => Logger::FATAL,
		  }
	end

	###############
	module_function
	###############

	### Make an easily-comparable version vector out of +ver+ and return it.
	def vvec( ver )
		return ver.split('.').collect {|char| char.to_i }.pack('N*')
	end


	### Reset the logging subsystem to its default state.
	def reset_logging
		Mongrel2.reset_logger
	end


	### Alter the output of the default log formatter to be pretty in SpecMate output
	def setup_logging( level=Logger::FATAL )

		# Turn symbol-style level config into Logger's expected Fixnum level
		if Mongrel2::Logging::LOG_LEVELS.key?( level.to_s )
			level = Mongrel2::Logging::LOG_LEVELS[ level.to_s ]
		end

		logger = Logger.new( $stderr )
		Mongrel2.logger = logger
		Mongrel2.logger.level = level

		# Only do this when executing from a spec in TextMate
		if ENV['HTML_LOGGING'] || (ENV['TM_FILENAME'] && ENV['TM_FILENAME'] =~ /_spec\.rb/)
			Thread.current['logger-output'] = []
			logdevice = ArrayLogger.new( Thread.current['logger-output'] )
			Mongrel2.logger = Logger.new( logdevice )
			# Mongrel2.logger.level = level
			Mongrel2.logger.formatter = Mongrel2::Logging::HtmlFormatter.new( logger )
		end
	end


	### Set up a Mongrel2 configuration database in memory.
	def setup_config_db
		Mongrel2::Config.configure( :configdb => ':memory:' )
		Mongrel2::Config.initialize_database!
	end

end


abort "You need a version of RSpec >= 2.6.0" unless defined?( RSpec )

### Mock with RSpec
RSpec.configure do |c|
	include Mongrel2::TestConstants

	c.mock_with :rspec

	c.extend( Mongrel2::TestConstants )
	c.include( Mongrel2::TestConstants )
	c.include( Mongrel2::SpecHelpers )

	c.filter_run_excluding( :ruby_1_8_only => true ) if
		Mongrel2::SpecHelpers.vvec( RUBY_VERSION ) >= Mongrel2::SpecHelpers.vvec('1.9.1')
	c.filter_run_excluding( :mri_only => true ) if
		defined?( RUBY_ENGINE ) && RUBY_ENGINE != 'ruby'
end

# vim: set nosta noet ts=4 sw=4:

