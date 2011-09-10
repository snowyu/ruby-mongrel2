#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent

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

describe Mongrel2::Config do

	before( :all ) do
		setup_logging()
		setup_config_db()
	end

	after( :all ) do
		reset_logging()
	end


	it "has a factory method for creating derivative classes" do
		begin
			model_class = Mongrel2::Config( :hookers )
			model_class.should < Mongrel2::Config
			model_class.dataset.first_source.should == :hookers
		ensure
			# Remove the example class from the list of subclasses so it
			# doesn't affect later tests
			Mongrel2::Config.subclasses.delete( model_class ) if model_class
		end
	end

	it "can reset the database handle for the config classes" do
		db = Mongrel2::Config.in_memory_db
		Mongrel2::Config.db = db
		Mongrel2::Config::Directory.db.should equal( db )
	end

	it "has a convenience method for fetching an Array of all of its configured servers" do
		Mongrel2::Config.init_database
		Mongrel2::Config::Server.dataset.truncate
		s = Mongrel2::Config::Server.create(
			uuid: TEST_UUID,
			access_log: '/log/access.log',
			error_log: '/log/error.log',
			pid_file: '/run/m2.pid',
			default_host: 'localhost',
			port: 8275
		  )
		Mongrel2::Config.servers.should have( 1 ).member
		Mongrel2::Config.servers.first.uuid.should == TEST_UUID
	end

	it "can read the configuration schema from a data file" do
		Mongrel2::Config.load_config_schema.should =~ /create table server/i
	end

	it "knows whether or not its database has been initialized" do
		Mongrel2::Config.db = Mongrel2::Config.in_memory_db
		Mongrel2::Config.database_initialized?.should be_false()
		Mongrel2::Config.init_database!
		Mongrel2::Config.database_initialized?.should be_true()
	end

	it "doesn't re-initialize the database if the non-bang version of init_database is used" do
		Mongrel2::Config.db = Mongrel2::Config.in_memory_db
		Mongrel2::Config.init_database

		Mongrel2::Config.should_not_receive( :load_config_schema )
		Mongrel2::Config.init_database
	end

	describe "Configurability support", :if => defined?( Configurability ) do
		require 'configurability/behavior'

		it_should_behave_like "an object with Configurability"

		it "uses the 'mongrel2' config section" do
			Mongrel2::Config.config_key.should == :mongrel2
		end

	end

end

