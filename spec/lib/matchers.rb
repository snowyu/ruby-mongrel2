#!/usr/bin/ruby
# coding: utf-8

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent

	libdir = basedir + "lib"

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
}

require 'rspec'
require 'mongrel2'


### RSpec matchers for Mongrel2 specs
module Mongrel2::Matchers

    ### A matcher for unordered array contents
	class EnumerableAllBeMatcher

		def initialize( expected_mod )
			@expected_mod = expected_mod
		end

		def matches?( collection )
			collection.all? {|obj| obj.is_a?(@expected_mod) }
		end

		def description
			return "all be a kind of %p" % [ @expected_mod ]
		end
	end


	###############
	module_function
	###############

	### Returns true if the actual value is an Array, all of which respond truly to
	### .is_a?( expected_mod )
	def all_be_a( expected_mod )
		EnumerableAllBeMatcher.new( expected_mod )
	end


end # module Mongrel2::Matchers


