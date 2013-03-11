require 'digest/sha2'

class User < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
 
  validates :password, :confirmation => true
  attr_accessor :password_confirmation
  attr_reader   :password

  validate  :password_must_be_present

  attr_accessible :name, :password, :password_confirmation, :is_admin
  after_destroy :ensure_admin

  after_initialize :default_values

  def default_values
    self.is_admin ||= 'false'
  end

  def is_admin?(name)
    user = find_by_name(name)
    user.is_admin
  end

  def ensure_admin
    if User.count.zero?
      raise "Cannot delete last admin"
    end
  end
  
  def User.authenticate(name, password)
    if user = find_by_name(name)
      if user.hashed_password == encrypt_password(password, user.salt)
        user
      end
    end
  end

  def User.encrypt_password(password, salt)
    Digest::SHA2.hexdigest(password + "wibble" + salt)
  end
  
  # 'password' is a virtual attribute
  def password=(password)
    @password = password

    if password.present?
      generate_salt
      self.hashed_password = self.class.encrypt_password(password, salt)
    end
  end
  
  private

    def password_must_be_present
      errors.add(:password, "Missing password") unless hashed_password.present?
    end
  
    def generate_salt
      self.salt = self.object_id.to_s + rand.to_s
    end
end