defmodule AppConfig do
  @moduledoc """
  Helper module with a macro that adds the following functions to the module
  where it is called:

      def fetch_env(key) :: {:ok, value} | :error
      def fetch_env!(key) :: value | no_return
      def get_env(key, value | nil) :: value
      def get_env_boolean(key, boolean | nil) :: boolean | nil
      def get_env_integer(key, integer | nil) :: integer | nil
      def get_env_float(key, float | nil) :: float | nil

  These functions fetch values from an application's environment or from
  operating system (OS) environment variables. The values will be retrieved
  from OS environment variables when the following expression is assigned to a
  configuration parameter on the application's configuration:

      {:system, "VAR"}

  An optional default value can be returned when the environment variable is
  not set to a specific value by using the following format:

      {:system, "VAR", "default"}

  The `#{inspect __MODULE__}` module is normally used from within the module
  that implements the `Application` behaviour or from one used to access
  configuration values, and has to be defined in the following way:

      defmodule MyConfig do
        use #{inspect __MODULE__}, otp_app: :my_app
        # [...]
      end

  The `otp_app` argument contains the name of the application where the functions
  (added by the macro from the `#{inspect __MODULE__}` module) will look for
  configuration parameters.

  ## Examples

  Given the following application configuration:

      config :my_app,
        db_host: {:system, "DB_HOST", "localhost"},
        db_port: {:system, "DB_PORT", 5432}
        db_user: {:system, "DB_USER"},
        db_password: {:system, "DB_PASSWORD"},
        db_name: "my_database",
        db_retry_interval: {:system, "DB_RETRY_INTERVAL", 0.5}
        db_replication: {:system, "DB_REPLICATION", false}

  And the following environment variables:

      export DB_USER="my_user"
      export DB_PASSWORD="guess_me"

  And assuming that the `MyConfig` module is using the `#{inspect __MODULE__}`
  macro, then the following expressions used to retrieve the values of the
  parameters would be valid:

      "localhost" = MyConfig.get_env(:db_host)
      5432 = MyConfig.get_env_integer(:db_port)
      {:ok, "my_user"} = MyConfig.fetch_env(:db_user)
      "guess_me" = MyConfig.fetch_env!(:db_password)
      "my_database" = MyConfig.get_env(:db_name, "unknown")

  The key can also be a list of atoms. The examples above could be converted to
  the following format using a key that is actually a list:

      config My.Database,
        host: {:system, "DB_HOST", "localhost"},
        port: {:system, "DB_PORT", 5432}
        user: {:system, "DB_USER"},
        password: {:system, "DB_PASSWORD"},
        name: "my_database",
        retry_interval: {:system, "DB_RETRY_INTERVAL", 0.5}
        replication: {:system, "DB_REPLICATION", false}

  To retrieve the values, you'd then use the following code:

      "localhost" = MyConfig.get_env([My.Database, :host])
      5432 = MyConfig.get_env_integer([My.Database, :port])
      {:ok, "my_user"} = MyConfig.fetch_env([My.Database, :user])
      "guess_me" = MyConfig.fetch_env!([My.Database, :password])
      "my_database" = MyConfig.get_env([My.Database, :name], "unknown")

  Most functions from the `#{inspect __MODULE__}` module can also be called
  without using its macro. To do so, just call the functions directly by
  passing the application's name as the first argument. e.g.

      #{inspect __MODULE__}.get_env(:my_app, :db_host)

  This module will come in handy especially when retrieving configuration
  values for applications running within Elixir/Erlang releases, as it simplifies
  the retrieval of values that were not defined when the release was built (i.e. at
  compile-time) from OS environment variables.
  """

  @type app :: Application.app
  @type key :: Application.key | [Application.key]
  @type value :: Application.value
  @type var :: String.t

  @doc false
  defmacro __using__(opts) do
    app = opts[:otp_app] || Application.get_application(__CALLER__.module)
    if app do
      quote do
        def get_env(key, default \\ nil) do
          AppConfig.get_env(unquote(app), key, default)
        end

        def get_env_boolean(key, default \\ nil) do
          AppConfig.get_env_boolean(unquote(app), key, default)
        end

        def get_env_integer(key, default \\ nil) do
          AppConfig.get_env_integer(unquote(app), key, default)
        end

        def get_env_float(key, default \\ nil) do
          AppConfig.get_env_float(unquote(app), key, default)
        end

        def fetch_env(key) do
          AppConfig.fetch_env(unquote(app), key)
        end

        def fetch_env!(key) do
          AppConfig.fetch_env!(unquote(app), key)
        end
      end
    else
      raise ArgumentError, "'otp_app' argument was not present in use of the " <>
        "'#{inspect __MODULE__}' module and could not be deduced from the " <>
        "'#{inspect __CALLER__.module}' caller module"
    end
  end

  @doc """
  Returns a tuple with the value for `key` in an application's environment,
  in a keyword list or in the OS environment. The first argument can either be
  an atom with the name of the application or a keyword list with the different
  configuration values.

  ## Returns

  A tuple with the `:ok` atom as the first element and the value of the
  configuration or OS environment variable if successful. It returns `:error`
  if the configuration parameter does not exist or if the application was not
  loaded.

  ## Example

      {:ok, "VALUE"} = #{inspect __MODULE__}.fetch_env(:my_app, :test_var)

  """
  @spec fetch_env(app | Keyword.t, key) :: {:ok, value} | :error
  def fetch_env(env, key) when is_atom(key) and (is_atom(env) or is_list(env)) do
    with {:ok, value} <- fetch(env, key) do
      get_env_value(value)
    end
  end
  def fetch_env(env, [key]) when is_atom(key) do
    fetch_env(env, key)
  end
  def fetch_env(env, [key | tail]) when is_atom(key) do
    with {:ok, keyword = [{key1, _value} | _tail]} when is_atom(key1) <- fetch(env, key) do
      fetch_env(keyword, tail)
    end
  end

  defp fetch(app, key) when is_atom(app) do
    Application.fetch_env(app, key)
  end
  defp fetch(list, key) when is_list(list) do
    Keyword.fetch(list, key)
  end

  @doc """
  Retrieves the value from and OS environment variable when it receives a tuple
  like the following as argument:

      {:system, "VAR"}

  An optional default value can be returned when the environment variable is
  not set to a specific value by using the following format:

      {:system, "VAR", "default"}

  If any other value is passed, that's what the function will return.

  ## Returns

  A tuple with the `:ok` atom as the first element and the value of the
  OS environment variable or the value that was passed if successful. It
  returns `:error` if the OS environment variable was not set.

  ## Example

      iex> System.put_env("MY_VAR", "MY_VALUE")
      ...> #{inspect __MODULE__}.get_env_value({:system, "MY_VAR"})
      {:ok, "MY_VALUE"}
      iex> #{inspect __MODULE__}.get_env_value({:system, "MY_UNSET_VAR"})
      :error
      iex> #{inspect __MODULE__}.get_env_value({:system, "MY_UNSET_VAR", "DEFAULT"})
      {:ok, "DEFAULT"}
      iex> #{inspect __MODULE__}.get_env_value("VALUE")
      {:ok, "VALUE"}

  """
  @spec get_env_value({:system, var} | {:system, var, String.t} | term)
    :: {:ok, term} | :error
  def get_env_value({:system, var}) do
    case System.get_env(var) do
      nil -> :error
      value -> {:ok, value}
    end
  end
  def get_env_value({:system, var, default}) do
    case System.get_env(var) do
      nil -> {:ok, default}
      value -> {:ok, value}
    end
  end
  def get_env_value(value) do
    {:ok, value}
  end

  @doc """
  Returns the value for `key` in an application's environment, in a keyword list
  or in the OS environment. The first argument can either be an atom with the
  name of the application or a keyword list with the different configuration
  values.

  ## Returns

  The value of the configuration parameter or OS environment variable if
  successful. It raises an `ArgumentError` exception if the configuration
  parameter does not exist or if the application was not loaded.

  ## Example

      "VALUE" = #{inspect __MODULE__}.fetch_env!(:my_app, :test_var)

  """
  @spec fetch_env!(app | Keyword.t, key) :: value | no_return
  def fetch_env!(app, key) do
    case fetch_env(app, key) do
      {:ok, value} ->
        value
      :error ->
        raise ArgumentError,
          "application #{inspect app} is not loaded, " <>
          "or the configuration parameter #{inspect key} is not set"
    end
  end

  @doc """
  Retrieves a value from an application's configuration, form a keyword list or
  from the OS environment. If the value is not present, the `default` value is
  returned.

  The first argument can either be an atom with the name of the application or
  a keyword list with the different configuration values.

  If the application's parameter was assigned an expression like the following
  one:

      {:system, "VAR"}

  An optional default value can be provided by using the following format:

      {:system, "VAR", "default"}

  If neither the application's configuration nor the specified OS environment
  variable exist, then the `default` value will be returned.

  ## Example

      iex> {test_var, expected_value} = System.get_env() |> Enum.take(1) |> List.first()
      ...> Application.put_env(:myapp, :test_var, {:system, test_var})
      ...> ^expected_value = #{inspect __MODULE__}.get_env(:myapp, :test_var)
      ...> :ok
      :ok

      iex> Application.put_env(:myapp, :test_var2, 1)
      ...> 1 = #{inspect __MODULE__}.get_env(:myapp, :test_var2)
      1

      iex> :default = #{inspect __MODULE__}.get_env(:myapp, :missing_var, :default)
      :default
  """
  @spec get_env(app | Keyword.t, key, value | nil) :: value | nil
  def get_env(app, key, default \\ nil) do
    case fetch_env(app, key) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  Same as `get_env/3`, but returns the result as a boolean. If the value
  cannot be found or it cannot converted to a boolean, the `default` value is
  returned instead.

  ## Example

      false = #{inspect __MODULE__}.get_env_boolean(:my_app, :db_replication)

  """
  @spec get_env_boolean(app | Keyword.t, key, boolean | nil) :: boolean | nil
  def get_env_boolean(app, key, default \\ nil) do
    case fetch_env(app, key) do
      {:ok, flag} when is_boolean(flag) ->
        flag
      {:ok, value} when is_binary(value) ->
        value
        |> String.downcase()
        |> case do
          "0"        -> false
          "false"    -> false
          "no"       -> false
          "off"      -> false
          "disabled" -> false
          "1"        -> true
          "true"     -> true
          "yes"      -> true
          "on"       -> true
          "enabled"  -> true
          _          -> default
        end
      :error ->
        default
    end
  end

  @doc """
  Same as `get_env/3`, but returns the result as an integer. If the value
  cannot be converted to an integer, the `default` value is returned instead.

  ## Example

      5432 = #{inspect __MODULE__}.get_env_integer(:my_app, :db_port)

  """
  @spec get_env_integer(app | Keyword.t, key, integer | nil) :: integer | nil
  def get_env_integer(app, key, default \\ nil) do
    case fetch_env(app, key) do
      {:ok, number} when is_integer(number) ->
        number
      {:ok, value} when is_binary(value) ->
        case Integer.parse(value) do
          {number, _} -> number
          :error      -> default
        end
      :error ->
        default
    end
  end

  @doc """
  Same as `get_env/3`, but returns the result as a float. If the value
  cannot be converted to a float, the `default` value is returned instead.

  ## Example

      0.5 = #{inspect __MODULE__}.get_env_float(:my_app, :db_retry_interval)

  """
  @spec get_env_float(app | Keyword.t, key, float | nil) :: float | nil
  def get_env_float(app, key, default \\ nil) do
    case fetch_env(app, key) do
      {:ok, number} when is_float(number) ->
        number
      {:ok, value} when is_binary(value) ->
        case Float.parse(value) do
          {number, _} -> number
          :error -> default
        end
      :error ->
        default
    end
  end
end
