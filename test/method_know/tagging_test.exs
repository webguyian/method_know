defmodule MethodKnow.TaggingTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import Mox

  # Make sure mocks are verified when the test exits
  setup :verify_on_exit!

  setup do
    # Set a token for tests that require it, and clean up after
    on_exit(fn -> Application.delete_env(:method_know, MethodKnow.Tagging) end)
    :ok
  end

  describe "extract_tags/1" do
    test "returns [] if no token configured and warns" do
      Application.delete_env(:method_know, MethodKnow.Tagging)

      assert capture_io(:stderr, fn ->
               assert MethodKnow.Tagging.extract_tags("test") == []
             end) =~ "No HuggingFace API token configured!"
    end

    test "returns tags on 200 response with list body" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:ok,
         %{
           status: 200,
           body: [%{"word" => "elixir", "score" => 0.9}, %{"word" => "phoenix", "score" => 0.8}]
         }}
      end)

      assert MethodKnow.Tagging.extract_tags("elixir phoenix") == ["elixir", "phoenix"]
    end

    test "returns tags on 200 response with JSON body" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:ok, %{status: 200, body: Jason.encode!([%{"word" => "ecto", "score" => 0.7}])}}
      end)

      assert MethodKnow.Tagging.extract_tags("ecto") == ["ecto"]
    end

    test "returns [] and warns on non-200 response" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:ok, %{status: 500, body: "error"}}
      end)

      assert capture_io(:stderr, fn ->
               assert MethodKnow.Tagging.extract_tags("fail") == []
             end) =~ "HuggingFace API error: status 500"
    end

    test "returns [] and warns on request error" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:error, :timeout}
      end)

      assert capture_io(:stderr, fn ->
               assert MethodKnow.Tagging.extract_tags("timeout") == []
             end) =~ "HuggingFace API request failed: :timeout"
    end

    test "returns [] on invalid JSON body" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:ok, %{status: 200, body: "not json"}}
      end)

      assert MethodKnow.Tagging.extract_tags("bad json") == []
    end

    test "returns [] on empty list body" do
      Application.put_env(:method_know, MethodKnow.Tagging, hf_api_token: "token")

      MethodKnow.ReqMock
      |> Mox.expect(:post, fn _url, _opts ->
        {:ok, %{status: 200, body: []}}
      end)

      assert MethodKnow.Tagging.extract_tags("empty") == []
    end
  end
end
