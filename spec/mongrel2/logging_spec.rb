#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'
require 'stringio'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/logging'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Logging, "-extended module" do

	before( :each ) do
		@extended_module = Module.new do
			extend Mongrel2::Logging
		end
	end

	it "should have a default Logger" do
		@extended_module.logger.should be_a( Logger )
		@extended_module.default_logger.should equal( @extended_module.logger )
	end

	it "should know if its default logger is replaced" do
		@extended_module.should be_using_default_logger
		@extended_module.logger = Logger.new( $stderr )
		@extended_module.should_not be_using_default_logger
	end

	it "has the default logger instance after being reset" do
		@extended_module.reset_logger
		@extended_module.logger.should equal( @extended_module.default_logger )
	end

	it "has the default log formatter instance after being reset" do
		@extended_module.reset_logger
		@extended_module.logger.formatter.should equal( @extended_module.default_log_formatter )
	end


	context "with new defaults" do

		before( :each ) do
			@sink = StringIO.new
			@logger = Logger.new( @sink )
			@formatter = Mongrel2::Logging::ColorFormatter.new( @logger )

			@extended_module.default_logger = @logger
			@extended_module.default_log_formatter = @formatter
		end

		it "uses the new defaults when the logging subsystem is reset" do
			@extended_module.reset_logger
			@extended_module.logger.should equal( @logger )
		end

	end


end

