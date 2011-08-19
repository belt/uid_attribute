require "uid_attribute/version"
require 'uuidtools'

module UIDAttribute

def self.included( klass ) # :nodoc:
  klass.extend ClassMethods
  klass.send(:install_uid_attribute)
end

module ClassMethods
  include UUIDTools

  # :call-seq:
  # uid_attribute
  #
  # This function defines the UID attribute for the klass <tt>(default: :uid)</tt>

  def uid_attribute(uid_attr = :uid)
    install_uid_attribute_validators(uid_attr)

    class_eval("class << self;attr_accessor :uid_attr;attr_accessor :uid_object; end")
    @uid_object = false
    protected
    @uid_attr = uid_attr
  end

protected

  def install_uid_attribute #:nodoc:
    uid_attribute
  end

  # :call-seq:
  # install_uid_attribute_validators :uid_attr
  #
  # if the including class inherits from ActiveRecord::Base,
  # then validate Klass.uid_attr is not blank and is unique (within this model)

  def install_uid_attribute_validators(uid_attr) #:nodoc:
    return unless ancestors.collect{|ancestor|
      ancestor.to_s }.include?('ActiveRecord::Base')
    validates_presence_of uid_attr
    validates_uniqueness_of uid_attr
  end

end # /class_methods

def initialize(*args) # :nodoc:
  # hyjack including class initializer to set UID too
  ret = super(*args)
  set_uid
  ret
end

# :call-seq:
# set_uid
#
# set :uid_attribute

def set_uid
  klass = self.class
  has_uid_accessors?

  uid = klass.uid_object ?  UUIDTools::UUID.md5_create(UUIDTools::UUID_OID_NAMESPACE, self.inspect) :
    UUIDTools::UUID.random_create.to_s

  send("#{klass.uid_attr}=", uid)
end

protected

# :call-seq:
# has_uid_accessors?
#
# raises errors unless the including class has a setter and getter for Klass.uid_attr

def has_uid_accessors?
  klass = self.class
  uid_attr = klass.uid_attr
  raise "dev.error: #{klass}.respond_to?(:#{uid_attr}) == false" unless respond_to?(uid_attr)
  raise "dev.error: #{klass}.respond_to?(:#{uid_attr}=) == false" unless respond_to?("#{uid_attr}=")
end

end # /module

