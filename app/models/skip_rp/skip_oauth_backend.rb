module SkipRp
  class SkipOauthBackend
    def initialize name
      @name = name
    end

    def add_access_token(identity_url, token, secret)
      if openid_identifier = OpenidIdentifier.find_by_url(identity_url)
        unless UserOauthAccess.find_by_app_name_and_user_id(@name, openid_identifier.user.id)
          openid_identifier.user.user_oauth_accesses.create! :app_name => @name, :token => token, :secret => secret
        end
      end
    end

    def update_user(identity_url, data)
      :noop
    end

    def update_group(gid, data)
      :noop
    end
  end
end
