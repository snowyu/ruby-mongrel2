#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( basedir ) unless $LOAD_PATH.include?( basedir )
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'rspec'

require 'spec/lib/helpers'

require 'mongrel2'
require 'mongrel2/config'


#####################################################################
###	C O N T E X T S
#####################################################################

describe Mongrel2::Config::Handler do

	before( :all ) do
		setup_logging( :fatal )
		setup_config_db()
	end

	before( :each ) do
		@handler = Mongrel2::Config::Handler.new(
			:send_spec  => TEST_SEND_SPEC,
			:send_ident => TEST_UUID,
			:recv_spec  => TEST_RECV_SPEC,
			:recv_ident => ''
		)
	end

	after( :all ) do
		reset_logging()
	end

	it "is valid if its specs and identities are all valid" do
		@handler.should be_valid()
	end


	it "isn't valid if it doesn't have a send_spec" do
		@handler.send_spec = nil
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /must not be nil/i
	end

	it "isn't valid if it doesn't have a recv_spec" do
		@handler.recv_spec = nil
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /must not be nil/i
	end


	it "isn't valid if it doesn't have a valid URL in its send_spec" do
		@handler.send_spec = 'carrier pigeon'
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /not a uri/i
	end

	it "isn't valid if it doesn't have a valid URL in its recv_spec" do
		@handler.recv_spec = 'smoke signals'
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /not a uri/i
	end


	it "isn't valid if has an unsupported transport in its send_spec" do
		@handler.send_spec = 'inproc://application'
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /invalid 0mq transport/i
	end

	it "isn't valid if has an unsupported transport in its recv_spec" do
		@handler.recv_spec = 'inproc://application'
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /invalid 0mq transport/i
	end


	it "isn't valid if it doesn't have a send_ident" do
		@handler.send_ident = nil
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /invalid sender identity/i
	end

	it "*is* valid if it doesn't have a recv_ident" do
		@handler.recv_ident = nil
		@handler.should be_valid()
	end


	it "is valid if it has 'json' set as the protocol" do
		@handler.protocol = 'json'
		@handler.should be_valid()
	end

	it "is valid if it has 'tnetstring' set as the protocol" do
		@handler.protocol = 'tnetstring'
		@handler.should be_valid()
	end

	it "isn't valid if it has an invalid protocol" do
		@handler.protocol = 'morsecode'
		@handler.should_not be_valid()
		@handler.errors.full_messages.first.should =~ /invalid/i
	end

end

