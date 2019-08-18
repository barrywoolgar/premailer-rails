class Premailer
  module Rails
    module CSSLoaders
      module NetworkLoader
        extend self

        def load(url)
          uri = uri_for_url(url)
          return unless uri

          options = {
            use_ssl: (uri.scheme == 'https'),
            verify_mode: (OpenSSL::SSL::VERIFY_NONE unless Premailer::Rails.config.fetch(:verify_ssl))
          }.compact!

          Net::HTTP.start(uri.host, uri.port, options) do |http|
            request = Net::HTTP::Get.new(uri)
            http.request(request).body
          end
        end

        def uri_for_url(url)
          uri = URI(url)

          if uri.host.present?
            return uri if uri.scheme.present?
            URI("http:#{uri}")
          elsif asset_host_present?
            scheme, host = asset_host(url).split(%r{:?//})
            scheme, host = host, scheme if host.nil?
            scheme = 'http' if scheme.blank?
            path = url
            URI(File.join("#{scheme}://#{host}", path))
          end
        end

        def asset_host_present?
          ::Rails.respond_to?(:configuration) &&
            ::Rails.configuration.action_controller.asset_host.present?
        end

        def asset_host(url)
          config = ::Rails.configuration.action_controller.asset_host
          config.respond_to?(:call) ? config.call(url) : config
        end
      end
    end
  end
end
