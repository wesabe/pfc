module SetReferrer
  def set_referrer(path)
    @request.stub!(:env).and_return({"HTTP_REFERER" => path})
  end

  def set_intended(uri)
    @request.session[:intended_uri] = uri
  end
end
