class OpenidIdentifier < ActiveRecord::Base
  belongs_to :account

  validates_presence_of :url
  validates_uniqueness_of :url
  class << self
    HUMANIZED_ATTRIBUTE_KEY_NAMES = {
      "url" => "OpenID URL",
    }
    def human_attribute_name(attribute_key_name)
      HUMANIZED_ATTRIBUTE_KEY_NAMES[attribute_key_name] || super
    end
  end

  def validate
    normalize_ident_url
  rescue OpenIdAuthentication::InvalidOpenId => e
    errors.add(:url, 'の形式が間違っています。')
  end

  def before_save
    self.url = normalize_ident_url
  end

private
  def normalize_ident_url
    OpenIdAuthentication.normalize_url(url) unless url.blank?
  end
end
