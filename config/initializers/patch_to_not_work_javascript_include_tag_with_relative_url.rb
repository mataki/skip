# Asset caching does not work with relative_url_root
# http://rails.lighthouseapp.com/projects/8994/tickets/1022-asset-caching-does-not-work-with-relative_url_root
# TODO: Rails2.2以降本体で修正次第このファイルを削除すること

module ActionView
  module Helpers
    module AssetTagHelper
      private
      def compute_public_path(source, dir, ext = nil, include_host = true)
        has_request = @controller.respond_to?(:request)

        cache_key =
          if has_request
            [ @controller.request.protocol,
              ActionController::Base.asset_host.to_s,
              @controller.request.relative_url_root,
              dir, source, ext, include_host ].join
          else
            [ ActionController::Base.asset_host.to_s,
              dir, source, ext, include_host ].join
          end

        ActionView::Base.computed_public_paths[cache_key] ||=
          begin
            source += ".#{ext}" if ext && File.extname(source).blank? || File.exist?(File.join(ASSETS_DIR, dir, "#{source}.#{ext}"))

            if source =~ %r{^[-a-z]+://}
              source
            else
              source = "/#{dir}/#{source}" unless source[0] == ?/
              if has_request && include_host
                unless source =~ %r{^#{@controller.request.relative_url_root}/}
                  source = "#{@controller.request.relative_url_root}#{source}"
                end
              end
              source = rewrite_asset_path(source)

              if include_host
                host = compute_asset_host(source)

                if has_request && !host.blank? && host !~ %r{^[-a-z]+://}
                  host = "#{@controller.request.protocol}#{host}"
                end

                "#{host}#{source}"
              else
                source
              end
            end
          end
      end
    end
  end
end
