# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class Account < ActiveRecord::Base
  attr_accessor :old_password, :password
  validates_presence_of :code, :message => 'は必須です'
  validates_uniqueness_of :code, :message => 'は既に登録されています'

  validates_presence_of :name, :message => 'は必須です'

  validates_presence_of :email, :message => 'は必須です'
  validates_uniqueness_of :email, :message => 'は既に登録されています'

  validates_presence_of :password, :message => 'は必須です', :if => :password_required?
  validates_confirmation_of :password, :message => 'は確認用パスワードと一致しません', :if => :password_required?
  validates_length_of :password, :within => 4..40, :too_short => 'は%d文字以上で入力してください', :too_long => 'は%d文字以下で入力して下さい', :if => :password_required?

  validates_presence_of :password_confirmation, :message => 'は必須です', :if => :password_required?

  def validate
    normalize_ident_url
  rescue OpenIdAuthentication::InvalidOpenId => e
    errors.add(:ident_url, 'の形式が間違っています。')
  end

  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "code"                  => "ログインID",
      "name"                  => "名前",
      "email"                 => "メールアドレス",
      "old_password"          => "現在のパスワード",
      "password"              => "パスワード",
      "password_confirmation" => "確認用パスワード",
      "ident_url"             => 'OpenID URL'
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def before_save
    self.crypted_password = self.class.encrypt(password) if password_required?
    self.ident_url = normalize_ident_url
  end

  def self.auth(code, password)
    find_by_code_and_crypted_password(code, encrypt(password))
  end

  def self.encrypt(password)
    Digest::SHA1.hexdigest("#{SHA1_DIGEST_KEY}--#{password}--")
  end

private
  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def normalize_ident_url
    OpenIdAuthentication.normalize_url(ident_url) unless ident_url.blank?
  end
end
