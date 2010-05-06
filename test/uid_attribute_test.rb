require 'rubygems'
require 'test/unit'
require File.join(File.dirname(__FILE__),'..','lib','uid_attribute')

class Model
  include UIDAttribute
  attr_accessor :uid
end

class UidAttribueTest < Test::Unit::TestCase
  def setup
    @model = Model.new
    assert @model.class.uid_attr
  end

  def test_uid_attr
    assert !@model.send(@model.class.uid_attr).nil?
  end

  def test_object_uid_attr
    Model.uid_object = true
    assert !@model.send(@model.class.uid_attr).nil?
  end
end

