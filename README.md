# Eidetic (EventSourcing for Elixir)

**Note:** The canonical repository is hosted [here](https://gitlab.com/gt8/open-source/elixir/eidetic), on GitLab.com.

[![Hex.pm](https://img.shields.io/hexpm/v/eidetic.svg)](https://hex.pm/packages/eidetic)
[![Hex.pm](https://img.shields.io/hexpm/l/eidetic.svg)](https://hex.pm/packages/eidetic)
[![Hex.pm](https://img.shields.io/hexpm/dw/eidetic.svg)](https://hex.pm/packages/eidetic)
[![build status](https://gitlab.com/gt8/open-source/elixir/eidetic/badges/master/pipeline.svg)](https://gitlab.com/gt8/open-source/elixir/eidetic/commits/master)
[![code coverage](https://gitlab.com/gt8/open-source/elixir/eidetic/badges/master/coverage.svg)](https://gitlab.com/gt8/open-source/elixir/eidetic/commits/master)


*WARNING:* This is under active development. We do use this in production. API is unlikely to change, but not impossible. 1.0 expected soon

Initial implementation of an event sourced model that can be used in Elixir.

## Installing

```elixir
{:eidetic, "~> 0.4.0"}
```

## Tests

```shell
make test
```

## Creating Your First EventSourced Model

Please check out the [examples](/examples)

```elixir
defmodule MyModel do
  use Eidetic.Aggregate, fields: [forename: nil, surname: nil]
end
```
