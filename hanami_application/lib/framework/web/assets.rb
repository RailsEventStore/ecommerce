# frozen_string_literal: true

require "down"
require "yaml"

module Framework
  module Web
    class Assets
      attr_reader :root
      attr_reader :precompiled
      attr_reader :server_url

      def initialize(root:, precompiled:, server_url: nil)
        @root = root
        @precompiled = precompiled
        @server_url = server_url
      end

      def precompiled?
        !!precompiled
      end

      def on_server?
        !precompiled?
      end

      def [](asset)
        if precompiled
          asset_path_from_manifest(asset)
        else
          asset_path_on_server(asset)
        end
      end

      def read(asset)
        path = self[asset]

        if File.exist?("#{root}/public#{path}")
          File.read("#{root}/public#{path}")
        else
          Down.open(path).read
        end
      end

      private

      def asset_path_from_manifest(asset)
        manifest[asset]
      end

      def asset_path_on_server(asset)
        "#{server_url}/assets/#{asset}"
      end

      def manifest
        @manifest ||= YAML.load_file(manifest_path)
      end

      def manifest_path
        "#{root}/public/assets/manifest.json"
      end
    end
  end
end
