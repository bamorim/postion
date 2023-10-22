defmodule Postion.FeatureFlags.Token do
  @moduledoc """
  A cache for storing the access token for the feature flag service.
  """

  use GenServer

  require OpenTelemetry.Tracer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @type state() :: {String.t(), DateTime.t()}

  def get_token do
    OpenTelemetry.Tracer.with_span "get-extsvc-token" do
      GenServer.call(__MODULE__, :get_token)
    end
  end

  # Callbacks

  @impl true
  def init(_) do
    {:ok, {"", DateTime.from_unix!(0)}}
  end

  @impl true
  def handle_call(:get_token, _from, {token, expires_at}) do
    if expired?(expires_at) do
      {token, expires_at} = refresh_token!()
      {:reply, token, {token, expires_at}}
    else
      {:reply, token, {token, expires_at}}
    end
  end

  defp expired?(expires_at) do
    DateTime.before?(expires_at, DateTime.utc_now())
  end

  defp refresh_token! do
    OpenTelemetry.Tracer.with_span "refresh-extsvc-token" do
      %{"token" => token} =
        Req.post!(client(), url: "/refresh", json: %{refresh_token: "secure_token"}).body

      expires_at = DateTime.add(DateTime.utc_now(), 30, :minute)
      {token, expires_at}
    end
  end

  defp client do
    Req.new()
    |> OpentelemetryReq.attach()
    |> Req.Request.merge_options(
      base_url: "http://localhost:8080/tokens",
      propagate_trace_ctx: true,
      no_path_params: true
    )
  end
end
