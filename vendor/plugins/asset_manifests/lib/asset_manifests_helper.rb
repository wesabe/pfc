module ActionView
  module Helpers
    module AssetManifestsHelper
      # generate javascript_includes for the files listed in the given manifest
      # if we're in production mode, just look for a js file with the manifest's name
      # otherwise, generate separate includes for each file
      def javascript_include_manifest(manifest)
        manifest = JavaScriptAssetManifest.new(manifest)
        javascript_include_tag(manifest.files(Rails.env.production?))
      end

      def stylesheet_link_manifest(manifest)
        manifest = CSSAssetManifest.new(manifest)
        stylesheet_link_tag(manifest.files(Rails.env.production?))
      end
    end
  end
end
