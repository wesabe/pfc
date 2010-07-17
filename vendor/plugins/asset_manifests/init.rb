require "asset_manifest/javascript_asset_manifest"
require "asset_manifest/css_asset_manifest"
require "asset_manifests_helper"

ActionView::Base.class_eval do
  include ActionView::Helpers::AssetManifestsHelper
end if defined?(ActionView::Base)
