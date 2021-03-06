module WithRememberMeToken

  def remember_me_token
    RememberMeToken.new(cookies)
  end

  class RememberMeToken
    attr_reader :cookies

    def initialize(cookies)
      @cookies = cookies
    end

    def value
      permanent_signed_cookies[key]
    end

    def value=(v)
      permanent_signed_cookies[key] = v
    end

    def clear!
      self.value = nil
      cookies.delete key
    end

    private

    def key
      :mumuki_remember_me_token
    end

    def permanent_signed_cookies
      cookies.permanent.signed
    end
  end
end