defmodule Postion.FeatureFlags.HttpClient do
  alias Postion.FeatureFlags.Token

  require Logger

  @behaviour Postion.FeatureFlags

  def enabled?(flag, user_id) do
    case Req.post(client(),
           url: "/:flag/evaluate",
           json: %{userId: to_string(user_id)},
           path_params: [flag: flag]
         ) do
      {:ok, %{body: %{"enabled" => enabled}}} ->
        enabled

      _ ->
        Logger.warning("Unexpected response from feature flag system")
        false
    end
  end

  defp client do
    token = Token.get_token()

    Req.new()
    |> OpentelemetryReq.attach()
    |> Req.Request.merge_options(
      base_url: "http://localhost:8080/flags",
      propagate_trace_ctx: true,
      auth: {:bearer, token}
    )
  end
end
