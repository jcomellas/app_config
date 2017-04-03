defmodule MyTestApp do
  use Application
  use AppConfig, app: :my_test_app

  # Dummy start/2 function to avoid compilation warnings
  def start(_start_type, _start_args) do
    {:error, :unimplemented}
  end
end

defmodule AppConfigTest do
  use ExUnit.Case
  doctest AppConfig

  test "application environment" do
    test_val = "12345"
    :ok = Application.put_env(:my_test_app, :test_var, test_val)
    assert {:ok, test_val} == MyTestApp.fetch_env(:test_var)
    assert :error == MyTestApp.fetch_env(:unknown_var)
    assert test_val == MyTestApp.get_env(:test_var)
    assert 12345 == MyTestApp.get_env_integer(:test_var)
    assert nil == MyTestApp.get_env(:unknown_var)
    assert test_val == MyTestApp.fetch_env!(:test_var)
    assert %ArgumentError{} = catch_error(MyTestApp.fetch_env!(:unknown_var))
  end

  test "system environment" do
    env_var = "TEST_VAR"
    test_val = "12345"
    :ok = System.put_env(env_var, test_val)
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var})
    assert {:ok, test_val} == MyTestApp.fetch_env(:test_var)
    assert :error == MyTestApp.fetch_env(:unknown_var)
    assert test_val == MyTestApp.get_env(:test_var)
    assert 12345 == MyTestApp.get_env_integer(:test_var)
    assert nil == MyTestApp.get_env(:unknown_var)
    assert test_val == MyTestApp.fetch_env!(:test_var)
    assert %ArgumentError{} = catch_error(MyTestApp.fetch_env!(:unknown_var))
  end

  test "system environment with default value" do
    env_var = "TEST_VAR"
    test_val = "12345"
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, test_val})
    assert {:ok, test_val} == MyTestApp.fetch_env(:test_var)
    assert :error == MyTestApp.fetch_env(:unknown_var)
    assert test_val == MyTestApp.get_env(:test_var)
    assert 12345 == MyTestApp.get_env_integer(:test_var)
    assert nil == MyTestApp.get_env(:unknown_var)
    assert test_val == MyTestApp.fetch_env!(:test_var)
    assert %ArgumentError{} = catch_error(MyTestApp.fetch_env!(:unknown_var))
  end
end
