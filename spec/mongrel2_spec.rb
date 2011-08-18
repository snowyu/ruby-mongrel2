#!/usr/bin/env rspec -cfd -b

BEGIN {
	require 'pathname'
	basedir = Pathname( __FILE__ ).dirname.parent
	libdir = basedir + 'lib'

	$LOAD_PATH.unshift( basedir.to_s ) unless $LOAD_PATH.include?( basedir.to_s )
	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'logger'
require 'mongrel2'


describe Mongrel2 do

	describe "version methods" do
		it "returns a version string if asked" do
			Mongrel2.version_string.should =~ /\w+ [\d.]+/
		end


		it "returns a version string with a build number if asked" do
			Mongrel2.version_string(true).should =~ /\w+ [\d.]+ \(build [[:xdigit:]]+\)/
		end
	end


	describe "logging subsystem" do
		before(:each) do
			Mongrel2.reset_logger
		end

		after(:each) do
			Mongrel2.reset_logger
		end


		it "should know if its default logger is replaced" do
			Mongrel2.should be_using_default_logger
			Mongrel2.logger = Logger.new( $stderr )
			Mongrel2.should_not be_using_default_logger
		end

		it "has the default logger instance after being reset" do
			Mongrel2.logger.should equal( Mongrel2.default_logger )
		end

		it "has the default log formatter instance after being reset" do
			Mongrel2.logger.formatter.should equal( Mongrel2.default_log_formatter )
		end

	end


	describe "logging subsystem with new defaults" do
		before( :all ) do
			@original_logger = Mongrel2.default_logger
			@original_log_formatter = Mongrel2.default_log_formatter
		end

		after( :all ) do
			Mongrel2.default_logger = @original_logger
			Mongrel2.default_log_formatter = @original_log_formatter
		end


		it "uses the new defaults when the logging subsystem is reset" do
			logger = double( "dummy logger" ).as_null_object
			formatter = mock( "dummy logger" )

			Mongrel2.default_logger = logger
			Mongrel2.default_log_formatter = formatter

			logger.should_receive( :formatter= ).with( formatter )

			Mongrel2.reset_logger
			Mongrel2.logger.should equal( logger )
		end

	end

end

