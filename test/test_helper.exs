ExUnit.start()
Hammox.defmock(Postion.FeatureFlagsMock, for: Postion.FeatureFlags)
Application.put_env(:postion, Postion.FeatureFlags, Postion.FeatureFlagsMock)
Ecto.Adapters.SQL.Sandbox.mode(Postion.Repo, :manual)
