defmodule AppConfig do
  @moduledoc """
  Helper module with a macro that adds the following functions to the module
  where it is called:

      def fetch_env(key) :: {:ok, value} | :error
      def fetch_env!(key) :: value | no_return
      def get_env(key, value | nil) :: value
      def get_env_integer(key, integer | nil) :: integer

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
        db_port: {:system, "DB_PORT", "5432"}
        db_user: {:system, "DB_USER"},
        db_password: {:system, "DB_PASSWORD"},
        db_name: "my_database"

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
  @type key :: Application.key
  @type value :: Application.value

  @doc false
  defmacro __using__(opts) do
    app = opts[:otp_app] || Application.get_application(__CALLER__.module)
    if app do
      quote do
        def get_env(key, value \\ nil) do
          AppConfig.get_env(unquote(app), key, value)
        end

        def get_env_integer(key, value \\ nil) do
          AppConfig.get_env_integer(unquote(app), key, value)
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
  Returns a tuple with the value for `key` in the application's configuration
  or in the OS environment.

  ## Returns

  A tuple with the `:ok` atom as the first element and the value of the
  configuration or OS environment variable if successful. It returns `:error`
  if the configuration parameter does not exist or if the application was not
  loaded.

  ## Example

      {:ok, "VALUE"} = #{inspect __MODULE__}.fetch_env(:my_app, :test_var)

  """
  @spec fetch_env(app, key) :: {:ok, value} | :error
  def fetch_env(app, key) when is_atom(app) and is_atom(key) do
    case :application.get_env(app, key) do
      {:ok, {:system, env_var}} ->
        case System.get_env(env_var) do
          nil -> :error
          val -> {:ok, val}
        end
      {:ok, {:system, env_var, preconfigured_default}} ->
        case System.get_env(env_var) do
          nil -> {:ok, preconfigured_default}
          val -> {:ok, val}
        end
      :undefined ->
        :error
      {:ok, _val} = result ->
        result
    end
  end

  @doc """
  Returns the value for `key` in the application's configuration or in the
  OS environment.

  ## Returns

  The value of the configuration parameter or OS environment variable if
  successful. It raises an `ArgumentError` exception if the configuration
  parameter does not exist or if the application was not loaded.

  ## Example

      "VALUE" = #{inspect __MODULE__}.fetch_env!(:my_app, :test_var)

  """
  @spec fetch_env!(app, key) :: value | no_return
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
  Retrieves a value from an application's configuration or from the OS
  environment. If the value is not present, the `default` value is returned.

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
  @spec get_env(app, key, value | nil) :: value
  def get_env(app, key, default \\ nil) do
    case fetch_env(app, key) do
      {:ok, value} -> value
      :error       -> default
    end
  end

  @doc """
  Same as `get_env/3`, but returns the result as an integer. If the value
  cannot be converted to an integer, the `default` value is returned instead.

  ## Example

      5432 = #{inspect __MODULE__}.get_env_integer(:my_app, :db_port)

  """
  @spec get_env_integer(app, key, integer) :: integer
  def get_env_integer(app, key, default \\ nil) do
    case get_env(app, key, nil) do
      nil ->
        default
      n when is_integer(n) ->
        n
      n ->
        case Integer.parse(n) do
          {i, _} -> i
          :error -> default
        end
    end
  end
end
