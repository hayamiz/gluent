# -*- coding: utf-8 -*-

require 'rubygems'
require 'test-unit'
require File.expand_path("../../app/helpers/search.rb", __FILE__)

def test_data_path(name)
  File.expand_path(name, File.expand_path("../test_data", __FILE__))
end

class TestSearchHelper < Test::Unit::TestCase
  setup do
    @obj = Class.new do
      include Gluent::SearchHelper
    end.new
  end

  sub_test_case 'query parsing' do
    test 'plain text' do
      assert_equal [/abla/i], @obj.parse_query("abla")
    end

    test 'single regexp' do
      assert_equal [/oh*/i], @obj.parse_query("oh*")
    end

    test 'two keywords' do
      assert_equal [/hello/i, /world/i], @obj.parse_query("hello world")

      # spaces do not matter
      assert_equal [/hello/i, /world/i], @obj.parse_query("hello		 world")

      # also Japanese spaces do not matter
      assert_equal [/hello/i, /world/i], @obj.parse_query("hello　world")
    end

    test 'two regexps' do
      assert_equal [/(a|b)/i, /hoge+/i], @obj.parse_query("(a|b) hoge+")

      # spaces do not matter
      assert_equal [/(a|b)/i, /hoge+/i], @obj.parse_query("(a|b)   	 hoge+")
    end
  end

  sub_test_case 'file matching' do
    test 'single English keyword' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("humpty"))
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("dumpty"))

      assert_false @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                   @obj.parse_query("alice"))
    end

    test 'single English regexp' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query(".*mpty"))
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("(h|d)umpty"))
    end

    test 'two English keywords' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("humpty dumpty"))
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("humpty wall"))
    end

    test 'single Japanese keyword' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("ハンプティ"))
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("ダンプティ"))
    end

    test 'single Japanese regexp' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("(ハ|ダ)ンプティ"))
    end

    test 'two Japanese keywords' do
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("ハンプティ ダンプティ"))
      assert_true @obj.match_file(test_data_path("humpty-dumpty.txt"),
                                  @obj.parse_query("ハンプティ 塀"))
    end
  end
end

