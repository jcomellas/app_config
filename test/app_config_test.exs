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

  test "value from map" do
    test_val = "12345"
    env = %{dummy1: "ABC", test_var: test_val, dummy2: "DEF"}
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
    # Restore the system environment to avoid affecting other tests.
    :ok = System.delete_env(env_var)
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
    # Restore the system environment to avoid affecting other tests.
    :ok = System.delete_env(env_var)
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

  test "boolean value from system environment" do
    env_var = "TEST_VAR"
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var})
    env = [dummy1: "ABC", dummy2: "DEF", test_var: {:system, env_var}]
    # Test synonyms for false.
    for test_val <- ["0", "false", "off", "no", "disabled"] do
      :ok = System.put_env(env_var, test_val)
      assert false == AppConfig.get_env_boolean(:my_test_app, :test_var)
      assert false == AppConfig.get_env_boolean(env, :test_var)
    end
    # Test synonyms for true.
    for test_val <- ["1", "true", "on", "yes", "enabled"] do
      :ok = System.put_env(env_var, test_val)
      assert true == AppConfig.get_env_boolean(:my_test_app, :test_var)
      assert true == AppConfig.get_env_boolean(env, :test_var)
    end
    # Delete the environment variable.
    :ok = System.delete_env(env_var)
    # Test with undefined env var and default value as a boolean.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, true})
    assert true == AppConfig.get_env_boolean(:my_test_app, :test_var)
    # Test with undefined env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "true"})
    assert true == AppConfig.get_env_boolean(:my_test_app, :test_var)
    # Set the environment variable to a non-boolean value.
    :ok = System.put_env(env_var, "nottrue")
    # Test with invalid env var and default value as a boolean.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, false})
    assert true == AppConfig.get_env_boolean(:my_test_app, :test_var, true)
    # Test with invalid env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "false"})
    assert true == AppConfig.get_env_boolean(:my_test_app, :test_var, true)
    # Restore the system environment to avoid affecting other tests.
    :ok = System.delete_env(env_var)
  end

  test "integer value from system environment" do
    env_var = "TEST_VAR"
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var})
    env = [dummy1: "ABC", dummy2: "DEF", test_var: {:system, env_var}]
    :ok = System.put_env(env_var, "100")
    assert 100 == AppConfig.get_env_integer(:my_test_app, :test_var)
    assert 100 == AppConfig.get_env_integer(env, :test_var)
    # Delete the environment variable.
    :ok = System.delete_env(env_var)
    # Test with undefined env var and default value as an integer.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, 101})
    assert 101 == AppConfig.get_env_integer(:my_test_app, :test_var)
    # Test with undefined env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "102"})
    assert 102 == AppConfig.get_env_integer(:my_test_app, :test_var)
    # Set the environment variable to a non-integer value.
    :ok = System.put_env(env_var, "not103")
    # Test with invalid env var and default value as an integer.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, 103})
    assert 104 == AppConfig.get_env_integer(:my_test_app, :test_var, 104)
    # Test with invalid env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "103"})
    assert 104 == AppConfig.get_env_integer(:my_test_app, :test_var, 104)
    # Restore the system environment to avoid affecting other tests.
    :ok = System.delete_env(env_var)
  end

  test "float value from system environment" do
    env_var = "TEST_VAR"
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var})
    env = [dummy1: "ABC", dummy2: "DEF", test_var: {:system, env_var}]
    :ok = System.put_env(env_var, "100.1")
    assert 100.1 == AppConfig.get_env_float(:my_test_app, :test_var)
    assert 100.1 == AppConfig.get_env_float(env, :test_var)
    # Delete the environment variable.
    :ok = System.delete_env(env_var)
    # Test with undefined env var and default value as a float.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, 100.2})
    assert 100.2 == AppConfig.get_env_float(:my_test_app, :test_var)
    # Test with undefined env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "100.3"})
    assert 100.3 == AppConfig.get_env_float(:my_test_app, :test_var)
    # Set the environment variable to a non-float value.
    :ok = System.put_env(env_var, "not100.4")
    # Test with invalid env var and default value as a float.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, 100.4})
    assert 100.5 == AppConfig.get_env_float(:my_test_app, :test_var, 100.5)
    # Test with invalid env var and default value as a string.
    :ok = Application.put_env(:my_test_app, :test_var, {:system, env_var, "100.4"})
    assert 100.5 == AppConfig.get_env_float(:my_test_app, :test_var, 100.5)
    # Restore the system environment to avoid affecting other tests.
    :ok = System.delete_env(env_var)
  end
end
