defmodule Postion.JaegerPropagator do
  @moduledoc "Propagator for uber-trace-id header"

  import Bitwise
  require Record

  @behaviour :otel_propagator_text_map

  @header_key "uber-trace-id"

  Record.defrecord(
    :span_ctx,
    Record.extract(:span_ctx, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
  )

  @impl true
  def fields(_opts), do: [@header_key]

  @impl true
  def inject(ctx, carrier, carrier_set, _opts) do
    curr_span_ctx = OpenTelemetry.Tracer.current_span_ctx(ctx)

    if OpenTelemetry.Span.is_valid(curr_span_ctx) do
      trace_id = OpenTelemetry.Span.hex_trace_id(curr_span_ctx)
      span_id = OpenTelemetry.Span.hex_span_id(curr_span_ctx)
      traced = span_ctx(curr_span_ctx, :trace_flags) &&& 1
      flags = if traced, do: "1", else: "0"
      carrier_set.(@header_key, "#{trace_id}:#{span_id}:0:#{flags}", carrier)
    else
      carrier
    end
  end

  @impl true
  def extract(_, _, _, _, _) do
    # Not implemented
    :undefined
  end
end
