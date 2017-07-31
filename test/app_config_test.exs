defmodule MyTestApp do
  use Application
  use AppConfig, otp_app: :my_test_app

  # Dummy start/2 function to avoid compilation warnings
  def start(_start_type, _start_args) do
    {:error, :unimplemented}
  end
end

defmodule AppConfigTest do
  use ExUnit.Case
  doctest AppConfig

  test "value from application environment" do
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

  test "value from keyword list" do
    test_val = "12345"
    env = [dummy1: "ABC", test_var: test_val, dummy2: "DEF"]
    assert {:ok, test_val} == AppConfig.fetch_env(env, :test_var)
    assert :error == AppConfig.fetch_env(env, :unknown_var)
    assert test_val == AppConfig.get_env(env, :test_var)
    assert 12345 == AppConfig.get_env_integer(env, :test_var)
    assert nil == AppConfig.get_env(env, :unknown_var)
    assert test_val == AppConfig.fetch_env!(env, :test_var)
    assert %ArgumentError{} = catch_error(AppConfig.fetch_env!(env, :unknown_var))
  end

  test "value from system environment" do
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

  test "value from system environment through keyword list" do
    env_var = "TEST_VAR"
    test_val = "12345"
    env = [dummy1: "ABC", dummy2: "DEF", test_var: {:system, env_var}]
    :ok = System.put_env(env_var, test_val)
    assert {:ok, test_val} == AppConfig.fetch_env(env, :test_var)
    assert :error == AppConfig.fetch_env(env, :unknown_var)
    assert test_val == AppConfig.get_env(env, :test_var)
    assert 12345 == AppConfig.get_env_integer(env, :test_var)
    assert nil == AppConfig.get_env(env, :unknown_var)
    assert test_val == AppConfig.fetch_env!(env, :test_var)
    assert %ArgumentError{} = catch_error(AppConfig.fetch_env!(env, :unknown_var))
  end

  test "value from system environment with default" do
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

  test "value from system environment through keyword list with default" do
    env_var = "TEST_VAR"
    test_val = "12345"
    env = [test_var: {:system, env_var, test_val}, dummy1: "ABC", dummy2: "DEF"]
    assert {:ok, test_val} == AppConfig.fetch_env(env, :test_var)
    assert :error == AppConfig.fetch_env(env, :unknown_var)
    assert test_val == AppConfig.get_env(env, :test_var)
    assert 12345 == AppConfig.get_env_integer(env, :test_var)
    assert nil == AppConfig.get_env(env, :unknown_var)
    assert test_val == AppConfig.fetch_env!(env, :test_var)
    assert %ArgumentError{} = catch_error(AppConfig.fetch_env!(env, :unknown_var))
  end
end
