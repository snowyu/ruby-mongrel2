#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

# SimpleCov test coverage reporting; enable this using the :coverage rake task
if ENV['COVERAGE']
	$stderr.puts "\n\n>>> Enabling coverage report.\n\n"
	require 'simplecov'
	SimpleCov.start do
		add_filter 'spec'
		add_group "Config Classes" do |file|
			file.filename =~ %r{lib/mongrel2/config(\.rb|/.*)$}
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

require 'sequel'
require 'sequel/model'

require 'spec/lib/constants'
require 'spec/lib/matchers'


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
		Mongrel2::Config.configure( :configdb => dbspec ) unless
			Mongrel2::Config.db.uri[ %r{sqlite:/(.*)}, 1 ] == dbspec
		Mongrel2::Config.init_database
		Mongrel2::Config.db.tables.collect {|t| Mongrel2::Config.db[t] }.each( &:truncate )
	end


	### Normalize and fill in missing members for the given +opts+.
	def normalize_headers( opts, defaults=TEST_HEADERS )
		headers = defaults.merge( opts[:headers] || {} )

		headers["PATH"]    = opts[:path]
		headers["URI"]     = "#{opts[:path]}?#{opts[:query]}"
		headers["QUERY"]   = opts[:query]
		headers["PATTERN"] = opts[:pattern] || opts[:path]

		return headers
	end


	### Make a raw Mongrel2 request from the specified +opts+ and return it as a String.
	def make_request( opts={} )
		opts = TEST_REQUEST_OPTS.merge( opts )
		headers = normalize_headers( opts )

		headerstring = TNetstring.dump( Yajl::Encoder.encode(headers) )
		bodystring = TNetstring.dump( opts[:body] || '' )

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		return "%s %d %s %s%s" % [
			opts[:uuid],
			opts[:id],
			opts[:path],
			headerstring,
			bodystring,
		]
	end


	### Make a new-style (TNetstring headers) raw Mongrel2 request from the specified +opts+ 
	### and return it as a String.
	def make_tn_request( opts={} )
		opts = TEST_REQUEST_OPTS.merge( opts )
		headers = normalize_headers( opts )

		headerstring = TNetstring.dump( headers )
		bodystring = TNetstring.dump( opts[:body] || '' )

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		return "%s %d %s %s%s" % [
			opts[:uuid],
			opts[:id],
			opts[:path],
			headerstring,
			bodystring,
		]
	end


	### Make a Mongrel2 request for a JSON route.
	def make_json_request( opts={} )
		opts = TEST_JSON_REQUEST_OPTS.merge( opts )
		headers = normalize_headers( opts, TEST_JSON_HEADERS )
		headers.delete( 'URI' ) # JSON requests don't have one

		Mongrel2.log.debug "JSON request, headers = %p, opts = %p" % [ headers, opts ]

		headerstring = TNetstring.dump( Yajl::Encoder.encode(headers) )
		bodystring = TNetstring.dump( Yajl::Encoder.encode(opts[:body] || []) )

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		return "%s %d %s %s%s" % [
			opts[:uuid],
			opts[:id],
			opts[:path],
			headerstring,
			bodystring,
		]
	end


	### Make a Mongrel2 request for an XML route.
	def make_xml_request( opts={} )
		opts = TEST_XML_REQUEST_OPTS.merge( opts )
		headers = normalize_headers( opts, TEST_XML_HEADERS )
		headers.delete( 'URI' ) # XML requests don't have one

		Mongrel2.log.debug "XML request, headers = %p, opts = %p" % [ headers, opts ]

		headerstring = TNetstring.dump( Yajl::Encoder.encode(headers) )
		bodystring = TNetstring.dump( opts[:body] || "#{TEST_XML_PATH} />" )

		# UUID ID PATH SIZE:HEADERS,SIZE:BODY,
		return "%s %d %s %s%s" % [
			opts[:uuid],
			opts[:id],
			opts[:path],
			headerstring,
			bodystring,
		]
	end

end


abort "You need a version of RSpec >= 2.6.0" unless defined?( RSpec )

if defined?( ::Amalgalite )
	$stderr.puts ">>> Using Amalgalite #{Amalgalite::VERSION} for DB access."
else
	$stderr.puts ">>> Using SQLite3 #{SQLite3::VERSION} for DB access."
end

### Mock with RSpec
RSpec.configure do |c|
	include Mongrel2::TestConstants

	c.mock_with :rspec

	c.extend( Mongrel2::TestConstants )
	c.include( Mongrel2::TestConstants )
	c.include( Mongrel2::SpecHelpers )
	c.include( Mongrel2::Matchers )
end

# vim: set nosta noet ts=4 sw=4:

