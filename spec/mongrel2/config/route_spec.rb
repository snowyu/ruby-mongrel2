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

describe Mongrel2::Config::Route do

	before( :all ) do
		setup_logging()
		Mongrel2::Config.configure( :configdb => ':memory:' )
		Mongrel2::Config.init_database
	end

	before( :each ) do
		@route = Mongrel2::Config::Route.new( :path => '' )
	end

	after( :all ) do
		reset_logging()
	end

	it "returns a Mongrel2::Config::Directory if its target_type is 'dir'" do
		dir = Mongrel2::Config::Directory.create( :base => '/var/www' )

		@route.target_type = 'dir'
		@route.target_id = dir.id

		@route.target.should == dir
	end

	it "returns a Mongrel2::Config::Proxy if its target_type is 'proxy'" do
		proxy = Mongrel2::Config::Proxy.create( :addr => '10.2.18.8' )

		@route.target_type = 'proxy'
		@route.target_id = proxy.id

		@route.target.should == proxy
	end

	it "returns a Mongrel2::Config::Handler if its target_type is 'handler'" do
		handler = Mongrel2::Config::Handler.create(
			:send_ident => TEST_UUID,
			:send_spec => 'tcp://127.0.0.1:9998',
			:recv_spec => 'tcp://127.0.0.1:9997' )

		@route.target_type = 'handler'
		@route.target_id = handler.id

		@route.target.should == handler
	end

	it "raises an exception if its target_type is set to something invalid" do
		@route.target_type = 'giraffes'

		expect {
			@route.target
		}.to raise_error( ArgumentError, /unknown target type/i )
	end

end

