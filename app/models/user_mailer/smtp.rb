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

class UserMailer::Smtp < UserMailer::Base
  def sent_signup_confirm(recipient, login_id, login_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64(_("[%s] User registration completed") % Admin::Setting.abbr_app_title)
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:login_id => login_id, :login_url => login_url, :header => header, :footer => footer}
  end

  def sent_apply_email_confirm(recipient, confirm_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64(_("[%s] Confirmation for changing email address") % Admin::Setting.abbr_app_title)
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:confirm_url => confirm_url, :header => header, :footer => footer}
  end

  def sent_forgot_password(recipient, reset_password_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64(_("[%s] Resetting your password") % Admin::Setting.abbr_app_title)
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:reset_password_url => reset_password_url, :header => header, :footer => footer}
  end

  def sent_forgot_openid(recipient, reset_openid_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64(_("[%s] Resetting your OpenID") % Admin::Setting.abbr_app_title)
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:reset_openid_url => reset_openid_url, :header => header, :footer => footer}
  end

  def sent_activate(recipient, signup_url)
    @recipients = recipient
    @subject    = UserMailer::Base.base64("[#{Admin::Setting.abbr_app_title}] " + _('Activate your account and start using'))
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:signup_url => signup_url, :site_url => site_url, :header => header, :footer => footer}
  end

  def sent_cleaning_notification(recipient)
    @recipients = recipient
    @subject    = UserMailer::Base.base64("[#{Admin::Setting.abbr_app_title}] " + _('Remember to clean up the user data periodically'))
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = {:header => header, :footer => footer}
  end

  def sent_invitation(invitation)
    @recipients = invitation.email
    @subject    = UserMailer::Base.base64("[#{Admin::Setting.abbr_app_title}] " + invitation.subject)
    @from       = from
    @send_on    = Time.now
    @headers    = {}
    @body       = invitation.body
  end
end
