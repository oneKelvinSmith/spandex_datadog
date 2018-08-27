defmodule Spandex.Test.DatadogTestApiServer do
  @moduledoc """
  Simply sends the data that would have been sent to datadog to self() as a message
  so that the test can assert on payloads that would have been sent to datadog
  """
  def send_spans(spans, opts \\ []) do
    span_context = Keyword.get(opts, :span_context)
    formatted = Enum.map(spans, &SpandexDatadog.ApiServer.format(&1, span_context))

    send(self(), {:sent_datadog_spans, formatted})
  end
end
