defmodule Spandex.Test.Datadog.AdapterTest do
  use ExUnit.Case, async: true
  alias Spandex.Test.TracedModule
  alias SpandexDatadog.Test.Util

  test "a complete trace sends spans" do
    TracedModule.trace_one_thing()

    spans = Util.sent_spans()
    Enum.each(spans, fn span ->
      assert span.service == :spandex_test
      assert span.meta.env == "test"
    end)
  end

  test "a trace can specify additional attributes" do
    TracedModule.trace_with_special_name()

    assert(Util.find_span("special_name").service == :special_service)
  end

  test "a span can specify additional attributes" do
    TracedModule.trace_with_special_name()

    assert(Util.find_span("special_name_span").service == :special_span_service)
  end

  test "a complete trace sends a top level span" do
    TracedModule.trace_one_thing()
    span = Util.find_span("trace_one_thing/0")
    refute is_nil(span)
    assert span.service == :spandex_test
    assert span.meta.env == "test"
  end

  test "a complete trace sends the internal spans as well" do
    TracedModule.trace_one_thing()

    assert(Util.find_span("do_one_thing/0") != nil)
  end

  test "the parent_id for a child span is correct" do
    TracedModule.trace_one_thing()

    assert(Util.find_span("trace_one_thing/0").span_id == Util.find_span("do_one_thing/0").parent_id)
  end

  test "a span is correctly notated as an error if an excepton occurs" do
    Util.can_fail(fn -> TracedModule.trace_one_error() end)

    assert(Util.find_span("trace_one_error/0").error == 1)
  end

  test "spans all the way up are correctly notated as an error" do
    Util.can_fail(fn -> TracedModule.error_two_deep() end)

    assert(Util.find_span("error_two_deep/0").error == 1)
    assert(Util.find_span("error_one_deep/0").error == 1)
  end

  test "successul sibling spans are not marked as failures when sibling fails" do
    Util.can_fail(fn -> TracedModule.two_fail_one_succeeds() end)

    assert(Util.find_span("error_one_deep/0", 0).error == 1)
    assert(Util.find_span("do_one_thing/0").error == 0)
    assert(Util.find_span("error_one_deep/0", 1).error == 1)
  end
end
