#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/constants'
require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/config'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Config::Directory do

	before( :all ) do
		setup_logging( :fatal )
		Mongrel2::Config.configure( :configdb => ':memory:' )
		Mongrel2::Config.init_database!
	end

	before( :each ) do
		@dir = Mongrel2::Config::Directory.new(
			:base          => 'var/www/public/',
			:index_file    => 'index.html',
			:default_ctype => 'text/plain'
		)
	end

	after( :all ) do
		reset_logging()
	end


	it "is valid if its base, index_file, and default_ctype are all valid" do
		@dir.should be_valid()
	end

	it "isn't valid if it doesn't have a base" do
		@dir.base = nil
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ /missing or nil/i
	end

	it "isn't valid when its base starts with '/'" do
		@dir.base = '/var/www/public/'
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ %r{shouldn't start with '/'}i
	end

	it "isn't valid when its base doesn't end with '/'" do
		@dir.base = 'var/www/public'
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ %r{must end with '/'}i
	end

	it "isn't valid if it doesn't have an index file" do
		@dir.index_file = nil
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ /must not be nil/i
	end

	it "isn't valid if it doesn't have a default content-type" do
		@dir.default_ctype = nil
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ /must not be nil/i
	end

	it "isn't valid if its cache TTL is set to a negative value" do
		@dir.cache_ttl = -5
		@dir.should_not be_valid()
		@dir.errors.full_messages.first.should =~ /not a positive integer/i
	end

	it "is valid if its cache TTL is set to zero" do
		@dir.cache_ttl = 0
		@dir.should be_valid()
	end

end

