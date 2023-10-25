defmodule Postion.FeatureFlags.Token do
  @moduledoc """
  A cache for storing the access token for the feature flag service.
  """

  use GenServer

  require OpenTelemetry.Tracer
  require OpenTelemetry.SemanticConventions.Trace

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @type state() :: {String.t(), DateTime.t()}

  @service_name __MODULE__

  def get_token do
    traced_call(__MODULE__, :get_token, [])
  end

  # TODO: Extract this into some reusable library
  defp traced_call(name, method, args) do
    address = GenServer.whereis(name)

    OpenTelemetry.Tracer.with_span "#{@service_name}/#{method}", %{kind: :client} do
      set_rpc_attributes_for(method, address)

      ctx = OpenTelemetry.Ctx.get_current()
      GenServer.call(address, {method, ctx, args})
    end
  end

  # Callbacks

  @impl true
  def init(_) do
    {:ok, {"", DateTime.from_unix!(0)}}
  end

  @impl true
  def handle_call({method, ctx, args}, from, state) do
    OpenTelemetry.Tracer.with_span ctx, "#{@service_name}/#{method}", %{kind: :server} do
      set_rpc_attributes_for(method, self())

      handle_traced_call({method, args}, from, state)
    end
  end

  def handle_traced_call({:get_token, []}, _from, {token, expires_at}) do
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
    %{"token" => token} =
      Req.post!(client(), url: "/refresh", json: %{refresh_token: "secure_token"}).body

    expires_at = DateTime.add(DateTime.utc_now(), 30, :minute)
    {token, expires_at}
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

  defp set_rpc_attributes_for(method, address) do
    OpenTelemetry.Tracer.set_attributes([
      {OpenTelemetry.SemanticConventions.Trace.rpc_system(), "beam.otp.gen_server"},
      {OpenTelemetry.SemanticConventions.Trace.rpc_method(), to_string(method)},
      {OpenTelemetry.SemanticConventions.Trace.rpc_service(), to_string(@service_name)},
      # TODO: Handle remote pids
      "server.address": inspect(address)
    ])
  end
end
