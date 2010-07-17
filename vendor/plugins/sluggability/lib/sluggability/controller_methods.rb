module Sluggability::ControllerMethods
  # Redirects to the right URL if the slug in the params doesn't match the one from the database.
  #
  #   @user = User.find(params[:user_id])
  #   @picture = @user.pictures.find(params[:id])
  #   return if wrong_slug?(:user_id => @user, :id => @picture)
  def wrong_slug?(keys_and_objects, perform_redirect = true)
    actual_params = params.symbolize_keys
    keys_and_objects = { :id => keys_and_objects } unless keys_and_objects.respond_to?(:keys)
    if keys_and_objects.inject(true) { |previous, key_and_object| previous && params[key_and_object.first] == key_and_object.last.to_param }
      return false
    elsif perform_redirect

      # So. A not-so-quick note about the following bit of code. When a request path is parsed by the routing code
      # into a set of params, it doesn't record which named route, if any, was used to parse the path. This is very
      # important because named route helpers (e.g., new_thing_url) specify internally which route should be used,
      # otherwise the default :controller/:action/:id route is used. This means that given the params, we still don't
      # have enough information to reconstruct the URL that a client should be redirected to.
      #
      # In short, two different paths will parse to the same params:
      #   /things/show/1 #=> { :controller => "things", :action => "show", :id => "1" }
      #   /things/1      #=> { :controller => "things", :action => "show", :id => "1" }
      #
      # But it takes two different params to generate these two paths:
      #   { :controller => "things", :action => "show", :id => "1" }                       #=> /things/show/1
      #   { :controller => "things", :action => "show", :id => "1", :use_route => :thing } #=> /things/1
      #
      # :use_route is the really important bit, but the routing code doesn't add it in, for whatever reason.
      #
      # To get around this, we have to do some really nasty things. All the base params for named routes are store in
      # a series of helpers: hash_for_new_thing_path, hash_for_things_url, etc. We'll be going through all methods on
      # the controller which are of the hash_for_blah_path flavor and putting the results of those methods into an
      # array. From that array, we select ones for this specific controller and action. We iterate through that result,
      # looking for a hash which, when merged with the initial params, enables us to reproduce the request path.
      #
      # Once we have that hash, we can then replace the incorrectly-slugged params and generate the correct version of
      # the request path.
      #
      # (btw, thanks to protocool for tipping me off to :use_route)
      # (he's totally not responsible for how long this comment is or how weird this code is)
      # (speaking of which I'm really sorry for how god-awfully weird this code is -- I'll work on a patch to fix the routing code)

      # go through and find the routing hashes for all named routes
      hashes_for_named_routes = methods.grep(/^hash_for.+_path$/).map do |hash_accessor|
        self.send(hash_accessor)
      end.select do |named_params|
        named_params.slice(:controller, :action) == actual_params.slice(:controller, :action)
      end

      # use the params we're given as a fallback
      route_params = params.slice(params.keys - keys_and_objects.keys)

      # go through the named hash params
      for named_params in hashes_for_named_routes
        begin
          # if we can reconstruct the path for the original request with this route, it's our guy
          if request.path == url_for(named_params.merge(params.slice(keys_and_objects.keys + [:format])))
            route_params = named_params
            break
          end
        rescue ActionController::RoutingError
          # can't build it? probably isn't the one
        end
      end

      # redirect to the appropriate URL
      redirect_to(route_params.merge(keys_and_objects).merge(:format => params[:format], :only_path => false))

      # set this after the redirect because otherwise the 307 Temporary Redirect gets turned into a 302 Found.
      headers["Status"] = interpret_status(request.get? || request.head? ? :moved_permanently : :temporary_redirect)

      # and let the controller know that it should take the day off
      return true
    end
  end
end