# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
import Config

alias MoodleNet.{
  Actors,
  Blocks,
  Collections,
  Communities,
  Features,
  Feeds,
  Flags,
  Follows,
  Instance,
  Likes,
  Resources,
  Threads,
  Users,
  Uploads,
}
alias MoodleNet.Blocks.Block
alias MoodleNet.Collections.Collection
alias MoodleNet.Communities.Community
alias MoodleNet.Feeds.{FeedActivities, FeedSubscriptions}
alias MoodleNet.Flags.Flag
alias MoodleNet.Likes.Like
alias MoodleNet.Resources.Resource
alias MoodleNet.Threads.{Comment, Thread}
alias MoodleNet.Users.User
alias MoodleNet.Workers.GarbageCollector

# stuff you might need to change to be viable

config :moodle_net, :app_name, System.get_env("APP_NAME", "MoodleNet")

config :moodle_net, MoodleNetWeb.Gettext, default_locale: "en", locales: ~w(en es)

# stuff you might want to change for your use case

config :moodle_net, GarbageCollector,
  # Contexts which require a mark phase, in execution order
  mark: [Uploads],
  # Contexts which need to perform maintainance, in execution order
  sweep: [ Uploads, FeedActivities, FeedSubscriptions, Feeds, Features,
           Resources, Collections, Communities, Users, Actors ],
  # We will not sweep content newer than this
  grace: 302400 # one week

config :moodle_net, Feeds,
  valid_contexts: [Collection, Comment, Community, Resource, Like],
  default_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Blocks,
  valid_contexts: [Collection, Community, User]

config :moodle_net, Instance,
  hostname: "moodlenet.local",
  description: "Local development instance",
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Collections,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Communities,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Features,
  valid_contexts: [Collection, Community]

config :moodle_net, Flags,
  valid_contexts: [Collection, Comment, Community, Resource, User, Circle, Character]

config :moodle_net, Follows,
  valid_contexts: [Collection, Community, Thread, User, Geolocation, Circle, Character]

config :moodle_net, Likes,
  valid_contexts: [Collection, Community, Comment, Resource]

config :moodle_net, Threads,
  valid_contexts: [Collection, Community, Flag, Resource, User, Circle, Character]

config :moodle_net, Users,
  public_registration: false,
  default_outbox_query_contexts: [Collection, Comment, Community, Resource, Like],
  default_inbox_query_contexts: [Collection, Comment, Community, Resource, Like]

config :moodle_net, Units,
  valid_contexts: [Circle, Community, Collection]

config :moodle_net, Circle,
  valid_contexts: [Circle, Community, Collection]

config :moodle_net, Character,
  valid_contexts: [Character, Circle, Community, Collection],
  default_outbox_query_contexts: [Collection, Character, Community, Comment, Community, Resource, Like]

image_media_types = ~w(image/png image/jpeg image/svg+xml image/gif)

config :moodle_net, Uploads.ResourceUploader,
  allowed_media_types: ~w(text/plain text/html text/markdown text/rtf text/csv) ++
      # App formats
      ~w(application/rtf application/pdf application/zip application/gzip) ++
      ~w(application/x-bittorrent application/x-tex) ++
      # Docs
      ~w(application/epub+zip application/vnd.amazon.mobi8-ebook) ++
      ~w(application/postscript application/msword) ++
      ~w(application/powerpoint application/mspowerpoint application/vnd.ms-powerpoint application/x-mspowerpoint) ++
      ~w(application/excel application/x-excel application/vnd.ms-excel) ++
      ~w(application/vnd.oasis.opendocument.chart application/vnd.oasis.opendocument.formula) ++
      ~w(application/vnd.oasis.opendocument.graphics application/vnd.oasis.opendocument.image) ++
      ~w(application/vnd.oasis.opendocument.presentation application/vnd.oasis.opendocument.spreadsheet) ++
      ~w(application/vnd.oasis.opendocument.text) ++
      # Images
      image_media_types ++
      # Audio
      ~w(audio/mp3 audio/m4a audio/wav audio/flac audio/ogg) ++
      # Video
      ~w(video/avi video/webm video/mp4)

config :moodle_net, Uploads.IconUploader,
  allowed_media_types: image_media_types

config :moodle_net, Uploads.ImageUploader,
  allowed_media_types: image_media_types

config :moodle_net, Uploads,
  max_file_size: System.get_env("UPLOAD_LIMIT", "20000000") # default to 20mb

 # before compilation, replace this with the email deliver service adapter you want to use: https://github.com/thoughtbot/bamboo#available-adapters
  # api_key: System.get_env("MAIL_KEY"), # use API key from runtime environment variable (make sure to set it on the server or CI config), and fallback to build-time env variable
  # domain: System.get_env("MAIL_DOMAIN"), # use sending domain from runtime env, and fallback to build-time env variable
# config :moodle_net, MoodleNet.Mail.MailService,
#   adapter: Bamboo.MailgunAdapter

config :moodle_net, :mrf_simple,
  media_removal: [],
  media_nsfw: [],
  report_removal: [],
  accept: [],
  avatar_removal: [],
  banner_removal: []

config :moodle_net, Oban,
  repo: MoodleNet.Repo,
  # prune: {:maxlen, 100_000},
  poll_interval: 5_000,
  queues: [
    federator_incoming: 50,
    federator_outgoing: 50,
    ap_incoming: 10,
    mn_ap_publish: 30,
  ]

config :moodle_net, :workers,
  retries: [
    federator_incoming: 5,
    federator_outgoing: 5
  ]

config :moodle_net, MoodleNet.MediaProxy,
  impl: MoodleNet.DirectHTTPMediaProxy,
  path: "/media/"

### Standin data for values you'll have to provide in the ENV in prod

config :moodle_net, MoodleNetWeb.Endpoint,
  url: [host: "localhost"],
  protocol: "https",
  secret_key_base: "aK4Abxf29xU9TTDKre9coZPUgevcVCFQJe/5xP/7Lt4BEif6idBIbjupVbOrbKxl",
  render_errors: [view: MoodleNetWeb.ErrorView, accepts: ["json", "activity+json"]],
  pubsub_server: MoodleNet.PubSub,
  secure_cookie_flag: true

version =
  with {version, 0} <- System.cmd("git", ["rev-parse", "HEAD"]) do
    "MoodleNet #{Mix.Project.config()[:version]} #{String.trim(version)}"
  else
    _ -> "MoodleNet #{Mix.Project.config()[:version]} dev"
  end

config :moodle_net, :instance,
  version: version,
  name: "MoodleNet",
  email: "moodlenet-moderators@moodle.com",
  description: "An instance of MoodleNet, a federated educational commons",
  federation_publisher_modules: [ActivityPubWeb.Publisher],
  federation_reachability_timeout_days: 7,
  federating: true,
  rewrite_policy: []

### Stuff you probably won't want to change

config :moodle_net, ecto_repos: [MoodleNet.Repo]

config :moodle_net, MoodleNet.Repo,
  types: MoodleNet.PostgresTypes,
  migration_primary_key: [name: :id, type: :binary_id]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :mime, :types, %{
  "application/activity+json" => ["json"],
  "application/ld+json" => ["json"],
  "application/jrd+json" => ["json"]
}

config :argon2_elixir,
  argon2_type: 2 # argon2id, see https://hexdocs.pm/argon2_elixir/Argon2.Stats.html

# Configures http settings, upstream proxy etc.
config :moodle_net, :http,
  proxy_url: nil,
  send_user_agent: true,
  adapter: [
    ssl_options: [
      # Workaround for remote server certificate chain issues
      partial_chain: &:hackney_connect.partial_chain/1,
      # We don't support TLS v1.3 yet
      versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"]
    ]
  ]


config :phoenix, :format_encoders, json: Jason
config :phoenix, :json_library, Jason

config :furlex, Furlex.Oembed,
  oembed_host: "https://oembed.com"

config :tesla, adapter: Tesla.Adapter.Hackney

config :http_signatures, adapter: ActivityPub.Signature

config :moodle_net, ActivityPub.Adapter, adapter: MoodleNet.ActivityPub.Adapter

config :floki, :html_parser, Floki.HTMLParser.FastHtml

config :sentry,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!

config :moodle_net, :env, Mix.env()

config :pointers, 
  table_table: "mn_table",
  pointer_table: "mn_pointer",
  trigger_function: "insert_pointer",
  trigger_prefix: "insert_pointer_"


# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

