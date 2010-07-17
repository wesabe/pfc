class UserPresenter < SimplePresenter
  def abbreviated_public_api_data
    {:name => presentable.to_s,
     :profile_image => '/images/' + image_path(:thumb)}
  end
end