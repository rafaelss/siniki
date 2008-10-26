helpers do
  def logged_in?
    session[:username]
  end

  def require_login
    unless logged_in?
      session[:redirect_back_to] = request.env['REQUEST_URI']
      redirect '/login'
    end
  end
end