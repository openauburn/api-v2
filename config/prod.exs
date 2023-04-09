import Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.

# Configure your database
config :open_auburn_api, OpenAuburnApi.Repo,
  username: System.get_env("PSQL_USER"),
  password: System.get_env("PSQL_PASS"),
  hostname: System.get_env("PSQL_HOST"),
  database: System.get_env("PSQL_GEN_DB"),
  stacktrace: true,
  # show_sensitive_data_on_connection_error: true,
  pool_size: 15


config :open_auburn_api, OpenAuburnApiWeb.Endpoint,
    load_from_system_env: true,
    http: [port: {:system, "PORT"}],
    check_origin: false,
    url: [host: 'localhost', port: {:system, "PORT"}],
    server: true,
    root: ".",
    cache_static_manifest: "priv/static/cache_manifest.json",
    server: [
       hostname: "localhost",
       # ...
      ]

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
