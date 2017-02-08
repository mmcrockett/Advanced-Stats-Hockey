class User < ActiveRecord::Base
  before_save :downcase_username
  validates :username, :presence => true
  validates :username, :length => { :minimum => 6, :maximum => 60 }
  validates :username, :uniqueness => true
  validates :password, :presence => true, :on => :create
  validates :password, :length => { :minimum => 6, :maximum => 20 }, :on => :create
  validates :salt, :presence => true
  validates :hashed_password, :presence => true

  AUTHENTICATION_ERROR = "Authentication failed. Username or password is incorrect."

  def self.register(username, password)
    user = User.new()
    user.username = username
    user.password = password

    if (true == user.valid?)
      user.save()
    end

    return user
  end

  def self.authenticate(username, password)
    user = User.new
    user.errors.clear
    user.errors.add(:base, AUTHENTICATION_ERROR)

    if ((nil != username) && (false == username.blank?))
      possible_user = self.find_by_username(username.downcase)

      if (true == possible_user.is_a?(User))
        stored_password = encrypted_password(password,possible_user.salt)
        if (possible_user.hashed_password == stored_password)
          user = possible_user
        end
      end
    end

    return user
  end

  def password=(pwd)
    @password = pwd
    process_password
  end

private
  def self.encrypted_password(password, salt)
    if (false == password.is_a?(String))
      raise "!ERROR: password is not a string '#{password.class}'."
    elsif (false == salt.is_a?(String))
      raise "!ERROR: salt is not a string '#{salt.class}'."
    end

    string_to_hashed = password + salt          
    Digest::SHA1.hexdigest(string_to_hashed)
  end
  
  def create_new_salt
    self.salt = self.object_id.to_s + rand.to_s
  end

  def password
    return @password
  end

  def downcase_username
    self.username.downcase!
  end

  def process_password
    create_new_salt
    self.hashed_password = User.encrypted_password(@password, self.salt)
  end
end
