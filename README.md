# AppConfig

Helper configuration module for Elixir that simplifies access to OS environment
variables.


## Overview

The [AppConfig](lib/app_config.ex) module contains a macro that adds the
following functions to the module where it is called:

```elixir
def fetch_env(key) :: {:ok, value} | :error
def fetch_env!(key) :: value | no_return
def get_env(key, value | nil) :: value
def get_env_integer(key, integer | nil) :: integer
```

These functions fetch values from an application's environment or from
operating system (OS) environment variables. The values will be retrieved
from OS environment variables when the following expression is assigned to a
configuration parameter on the application's configuration:

```elixir
{:system, "VAR"}
```

An optional default value can be returned when the environment variable is
not set to a specific value by using the following format:

```elixir
{:system, "VAR", "default"}
```

The [AppConfig](lib/app_config.ex) module is normally used from within the module
that implements the [Application](https://hexdocs.pm/elixir/Application.html#content)
behaviour or from one used to access configuration values, and has to be
defined in the following way:

```elixir
defmodule MyConfig do
  use AppConfig, app: :my_app
  # [...]
end
```

The `app` argument contains the name of the application where the functions
(added by the macro from the [AppConfig](lib/app_config.ex) module) will look
for configuration parameters.


## Installation

The package can be installed by adding `app_config` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [{:app_config, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
by running:

    mix docs
    
The docs can also be found at [https://hexdocs.pm/app_config](https://hexdocs.pm/app_config).


## Examples

Given the following application configuration:

```elixir
config :my_app,
  db_host: {:system, "DB_HOST", "localhost"},
  db_port: {:system, "DB_PORT", "5432"}
  db_user: {:system, "DB_USER"},
  db_password: {:system, "DB_PASSWORD"},
  db_name: "my_database"
```

And the following environment variables:

    export DB_USER="my_user"
    export DB_PASSWORD="guess_me"

And assuming that the `MyConfig` module is using the `AppConfig` macro, then
the following expressions used to retrieve the values of the parameters would
be valid:

```elixir
"localhost" = MyConfig.get_env(:db_host)
5432 = MyConfig.get_env_integer(:db_port)
{:ok, "my_user"} = MyConfig.fetch_env(:db_user)
"guess_me" = MyConfig.fetch_env!(:db_password)
"my_database" = MyConfig.get_env(:db_name, "unknown")
```

Most functions from the `AppConfig` module can also be called without using its
macro. To do so, just call the functions directly by passing the application's
name as the first argument. e.g.

```elixir
AppConfig.get_env(:my_app, :db_host)
```

This module will come in handy especially when retrieving configuration
values for applications running within Elixir/Erlang releases, as it simplifies
the retrieval of values that were not defined when the release was built (i.e. at
compile-time) from OS environment variables.
