module ActionController
  class Base
    def rescue_action(exception)
      raise exception
    end
  end

  class TestResponse
    def created?
      status == 201
    end

    def bad_request?
      status == 400
    end

    def unauthorized?
      status == 401
    end

    def forbidden?
      status == 403
    end

    def not_found?
      status == 404
    end

    def method_not_allowed?
      status == 405
    end

    def not_acceptable?
      status == 406
    end

    def unprocessable_entity?
      status == 422
    end

    def error?
      status == 500
    end

    def post_only?
      method_not_allowed? && headers["Allow"] == "POST"
    end

    def get_only?
      method_not_allowed? && headers["Allow"] == "GET"
    end

    def redirected_to_login?
      redirect? && redirected_to == "http://test.host/user/login"
    end
  end
end
