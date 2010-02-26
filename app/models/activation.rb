# SKIP(Social Knowledge & Innovation Platform)
# Copyright (C) 2008-2010 TIS Inc.
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

class Activation < ActiveRecord::Base
  include ActionController::UrlWriter

  belongs_to :tenant

  validates_presence_of :tenant

  validates_uniqueness_of :tenant_id

  default_url_options[:host] = SkipEmbedded::InitialSettings['host_and_port']
  default_url_options[:protocol] = SkipEmbedded::InitialSettings['protocol']

  def initialize(attr ={})
    super(attr)
    self.code ||= self.class.make_token
  end

  def first_new_admin_url
    polymorphic_url [:admin, self.tenant, :user], :action => 'first_new', :code => self.code
  end

  def self.secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end

  def self.make_token
    secure_digest(Time.now, (1..10).map{ rand.to_s })
  end
end
