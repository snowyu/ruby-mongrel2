#!/usr/bin/env ruby

require 'mongrel2' unless defined?( Mongrel2 )


### A collection of constants used in testing
module Mongrel2::TestConstants # :nodoc:all

	include Mongrel2::Constants

	unless defined?( TEST_HOST )

		TEST_HOST             = 'localhost'
		TEST_PORT             = 8118

		constants.each do |cname|
			const_get(cname).freeze
		end
	end

end


