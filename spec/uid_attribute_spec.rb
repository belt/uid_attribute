require 'spec_helper'
require 'uid_attribute'
require 'ap'

class Model
  include UIDAttribute
  attr_accessor :uid
end

class ModelSpecifyingUID
  include UIDAttribute
  uid_attribute :my_uid
  attr_accessor :my_uid
end

class ReadOnlyModel
  include UIDAttribute
  attr_reader :uid
end

describe 'uid_attribute' do
  describe 'generation of a unique ID attribute upon instantiation' do
    it 'should default to use the :uid attribute of the including class' do
      @model = Model.new
      @model.should respond_to(:uid)
    end

    it 'should allow specification of the :uid attribute by the including class' do
      @model_specifying_uid = ModelSpecifyingUID.new
      @model_specifying_uid.should respond_to(:my_uid)
    end

    it 'should generate a random ID upon instantiation' do
      @model = Model.new
      @model.uid.should be_a(String)
    end

    it 'should optionally generate a MD5-sum (as an :uid) upon instantiation' do
      @model = Model.new
      Model.uid_object = true
      @model.uid = 'seed'
      checksum = @model.set_uid

      @model.uid = 'seed'
      @model.set_uid
      @model.uid.should == checksum
    end

    context 'should raise an error if the including classes uid_attribute' do
      it 'does not have a getter' do
        Model.uid_attr = :test_uid
        lambda { Model.new }.should raise_error(RuntimeError)
      end

      it 'does not have a setter' do
        lambda { ReadOnlyModel.new }.should raise_error(RuntimeError)
      end
    end
  end

  describe 'classes inheritting ActiveRecord' do
    pending 'should add validations to the including model' do
      @model = Model.new
      @model_specifying_uid = ModelSpecifyingUID.new
      debugger
      true
    end
  end

end

