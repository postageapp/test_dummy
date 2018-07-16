require 'digest/sha1'

class User < ActiveRecord::Base
  # == Extensions ===========================================================
  
  # == Constants ============================================================
  
  # == Properties ===========================================================

  attr_accessible :name
  attr_accessible :password, :password_confirmation

  attr_accessor :password, :password_confirmation
  
  # == Relationships ========================================================

  belongs_to :account
  
  # == Callbacks ============================================================
  
  before_save :encrypt_password

  # == Validations ==========================================================
  
  validates :password,
    confirmation: true

  # == Scopes ===============================================================

  # == Class Methods ========================================================
  
  # == Instance Methods =====================================================

protected
  def encrypt_password
    # A proper implementation would use bcrypt, but this is just a
    # non-functional demonstration.
    self.password_crypt = Digest::SHA1.hexdigest(
      [
        @password,
        SecureRandom.uuid
      ].join('$')
    )
  end
end
