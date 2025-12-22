# frozen_string_literal: true

Hanami.application.register_provider :assets do
  start do
    require "framework/web/assets"

    assets = Framework::Web::Assets.new(
      root: Hanami.application.root,
      precompiled: Hanami.env == :production || target["settings"].precompiled_assets,
      server_url: Hanami.application.configuration.assets.server_url
    )

    register "assets", assets
  end
end
