defmodule MethodKnow.TaggingTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  describe "extract_tags/1" do
    test "returns [] if no token configured and warns" do
      Application.delete_env(:method_know, MethodKnow.Tagging)

      assert capture_io(:stderr, fn ->
               assert MethodKnow.Tagging.extract_tags("test") == []
             end) =~ "No HuggingFace API token configured!"
    end
  end
end
