#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
		add_group "Config Classes" do |file|
			file.filename =~ %r{/config/}
		end
		add_group "Needing tests" do |file|
			file.covered_percent < 90
		end
	end
end

begin
	require 'configurability'
rescue LoadError => err
end

require 'pathname'
require 'tmpdir'

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
	def setup_config_db( dbspec=':memory:' )
		Mongrel2::Config.configure( :configdb => dbspec )
		Mongrel2::Config.initialize_database!
	end



	### Set up a Mongrel2 server instance.
	def setup_testing_mongrel_instance( uuid, req_addr, req_spec, res_addr, res_spec='' )
		spec_tmpdir      = Pathname( Dir.pwd ) + 'spec_tmp'
		config_db_path   = spec_tmpdir + 'connspec-config.sqlite'
		m2_rundir        = spec_tmpdir + 'run'
		m2_tmpdir        = spec_tmpdir + 'tmp'
		logfile          = spec_tmpdir + 'startup.log'

		m2_rundir.mkpath
		m2_tmpdir.mkpath

		logfh = logfile.open( File::WRONLY|File::CREAT|File::APPEND )
		logfh.puts ">>> Config is: #{config_db_path}"

		logfh.puts "Configuring the configdb."
		Mongrel2::Config.configure( :configdb => config_db_path.to_s )
		logfh.puts "Forcefully installing the config schema."
		Mongrel2::Config.init_database!

		# Generate the config (Mongrel2::Config::Server) and store it as a global
		logfh.print "Generating a config..."
		server( uuid ) do
		    name 'ruby-mongrel2 spec config'
		    chroot( spec_tmpdir.to_s )
		    access_log '/tmp/access.log'
		    error_log  '/tmp/error.log'
		    pid_file '/tmp/mongrel2.pid'
		    default_host 'localhost'
		    port 36677

		    host 'localhost' do
				route '/', directory( '/data/mongrel2', 'README.txt' )
				route '/handler', handler( req_addr, req_spec, res_addr, res_spec )
			end
		end
		logfh.puts "done."

		logfh.puts "About to fork."
		logfh.flush

		if pid = fork
			logfh.close
		else
			Dir.chdir( spec_tmpdir )
			logfh.puts "About to exec( mongrel2, #{config_db_path.to_s.dump}, #{uuid.dump} )"
			$stderr.reopen( logfh )
			$stdout.reopen( $stderr )
			exec( 'mongrel2', config_db_path.to_s, uuid )
			$stderr.puts "Failed to exec(mongrel2)!"
			raise "This should only happen if mongrel2 isn't exec()able."
		end

		return pid
	end


	### Check to see if the process at +pid+ is alive, returning +true+ if so.
	def process_is_alive?( pid )
		Process.kill( 0, pid )
	rescue Errno::ESRCH
		Mongrel2.log.info "No such pid #{pid}"
		false
	end 


	### Stop the Mongrel2 instance running at +pid+, if it's alive, and return either when it's
	### dead or after three tries.
	def teardown_testing_mongrel_instance( pid )
		tries = 0

		while process_is_alive?( @pid ) && tries <= 3
			Mongrel2.log.info "Signalling PID #@pid..."
			Process.kill( :TERM, @pid )
			tries += 1

			Mongrel2.log.info "  waiting..."
			return true if Process.waitpid( @pid, Process::WNOHANG )

			sleep 0.5
		end

		Mongrel2.log.info "PID #{@pid} wouldn't die." if tries > 3
		return false
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

