# Be sure to restart your server when you modify this file.
#
# The Flutter *web* build (dispatcher UI) runs on its own origin, e.g. http://localhost:54321,
# so the browser only lets it call the API if we answer with CORS headers.
# Native mobile builds (driver app on iOS/Android) are not browsers and ignore CORS entirely.
#
# We authenticate with a Bearer token, not cookies, so no `credentials: true` is needed.
#
# Read more: https://github.com/cyu/rack-cors

allowed_origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
# `flutter run -d chrome` picks a random port, so allow any localhost port outside production.
allowed_origins << %r{\Ahttp://(localhost|127\.0\.0\.1)(:\d+)?\z} if Rails.env.local?

if allowed_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_origins)

      resource "/api/*",
        headers: :any,
        methods: %i[get post put patch delete options head]
    end
  end
end
