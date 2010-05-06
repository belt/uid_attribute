module UIDAttribute
require 'uuidtools'

def self.included( klass ) # :nodoc:
  klass.extend ClassMethods
  klass.install_uid_attribute
end

module ClassMethods
  include UUIDTools

  def install_uid_attribute #:nodoc:
    uid_attribute
  end

  # :call-seq:
  # uid_attribute
  #
  # This function defines the UID attribute for the klass <tt>(default: :uid)</tt>

  def uid_attribute(uid_attr = :uid)
    if ancestors.include?('ActiveRecord::Base')
      validates_uniqueness_of uid_attr
      before_validation :set_uid
    end

    class_eval("class << self;attr_accessor :uid_attr;attr_accessor :uid_object; end")
    @uid_attr = uid_attr
    @uid_object = false
  end

end

if self.class.ancestors.include?('ActiveRecord::Base')
  def initialize(args) # :nodoc:
    super args
    self.set_uid
  end
else
  def initialize # :nodoc:
    super
    self.set_uid
  end
end

# :call-seq:
# set_uid
#
# This function sets the attribute (as identified by klass.uid_attribute)

def set_uid
  raise "dev.error: #{self.class}.respond_to?(:#{self.class.uid_attr}) == false" unless self.respond_to?(self.class.uid_attr)
  #return unless self.send("#{self.class.uid_attr}=").nil?

  if self.class.uid_object
    uid = UUIDTools::UUID.md5_create(UUIDTools::UUID_OID_NAMESPACE, "#{self.inspect}")
  else
    uid = UUIDTools::UUID.random_create.to_s
  end

  self.send("#{self.class.uid_attr}=", uid)
end

# /module
end

