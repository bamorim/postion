defmodule Postion.FeatureFlags do
  use Knigge, otp_app: :postion, default: Postion.FeatureFlags.HttpClient

  @callback enabled?(flag :: String.t(), user_id :: pos_integer()) :: any()
end
