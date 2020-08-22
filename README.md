# ZenPub Federated Server

## About the project

ZenPub is a flavour of [CommonsPub](http://commonspub.org), a project to create a generic federated server, based on the `ActivityPub` and `ActivityStreams` web standards).

This is the main repository, written in Elixir (running on Erlang/OTP).

The federation API uses [ActivityPub](http://activitypub.rocks/) and the client API uses [GraphQL](https://graphql.org/).

There is a bundled front-end built with [Phoenix LiveView](https://www.phoenixframework.org/) (and an older React frontend in a [seperate repo](https://gitlab.com/CommonsPub/Client).

Some of this code was forked from [MoodleNet](http://moodle.net/), which was originally forked from [Pleroma](https://git.pleroma.social/pleroma/pleroma).

---

## Documentation

Do you want to...

- Read about the CommonsPub architecture? Read our [overview](https://gitlab.com/CommonsPub/Server/blob/flavour/commonspub/ARCHITECTURE.md).

- Hack on the code? Read our [Developer FAQs](https://gitlab.com/CommonsPub/Server/blob/flavour/commonspub/HACKING.md).

- Understand the client API? Read our [GraphQL guide](https://gitlab.com/CommonsPub/Server/blob/flavour/commonspub/GRAPHQL.md).

- Deploy in production? Read our [Deployment Docs](https://gitlab.com/CommonsPub/Server/blob/flavour/commonspub/DEPLOY.md).

---

## Forks and branches

### Flavours

CommonsPub comes in different flavours, which are made up of a combination of extensions and probably some custom config and branding. Each flavour has its own branch in the [CommonsPub repo](https://gitlab.com/CommonsPub/Server):

- `flavour/commonspub` - Contains the generic flavour of [CommonsPub](http://commonspub.org) (currently packaged with all extensions)
- `flavour/zenpub` - WIP [ZenPub](https://github.com/dyne/zenpub/) flavour (which will use [ZenRoom](https://zenroom.org/) for public key signing and end-to-end encryption
- `flavour/haha` - WIP for [HAHA Academy](https://haha.academy/)

### Extensions

Features are being developed in seperate namespaces in order to make the software more modular (to then be spun out into individual libraries):

- `lib/activity_pub` and `lib/activity_pub_web` - Implementation of the [ActivityPub](http://activitypub.rocks/) federation protocol.
- `lib/extensions/value_flows` - WIP implementation of the [ValueFlows](https://valueflo.ws/) economic vocabulary, to power distributed economic networks for the next economy.
- `lib/extensions/organisations` - Adds functionality for organisations to maintain a shared profile.
- `lib/extensions/tags` - For tagging, @ mentions, and user-maintained taxonomies of categories.
- `lib/extensions/measurements` - Various units and measures for indicating amounts (incl duration).
- `lib/extensions/locales` - Extensive schema of languages/countries/etc. The data is also open and shall be made available oustide the repo.
- `lib/extensions/geolocations` - Shared 'spatial things' database for tagging objects with a location.

#### Please **avoid mixing flavours!**

For example, do not merge directly from `flavour/commonspub`-->`flavour/zenpub`.

---

## Copyright and License

Copyright © 2018-2019 by Git Contributors.

Licensed under the GNU Affero GPL version 3.0 (GNU AGPLv3).

Contains code from [CommonsPub](https://commonspub.org/), [Pleroma](https://pleroma.social/), and [MoodleNet](http://moodle.net/)
