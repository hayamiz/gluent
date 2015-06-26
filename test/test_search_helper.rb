# coding: utf-8

require 'rubygems'
require 'test-unit'
require File.expand_path("../../app/helpers/search.rb", __FILE__)

class TestSearchHelper < Test::Unit::TestCase
  setup do
    @obj = Class.new do
      include Gluent::SearchHelper
    end.new
  end

  sub_test_case 'query parsing' do
    test 'plain text' do
      assert_equal [/abla/], @obj.parse_query("abla")
    end

    test 'single regexp' do
      assert_equal [/oh*/], @obj.parse_query("oh*")
    end
  end
end

