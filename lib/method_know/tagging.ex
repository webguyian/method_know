defmodule MethodKnow.Tagging do
  @moduledoc """
  Provides keyphrase extraction (tag generation) using the HuggingFace Inference API.
  """

  @hf_model "ml6team/keyphrase-extraction-distilbert-inspec"
  @hf_api_url "https://router.huggingface.co/hf-inference/models/" <> @hf_model

  @doc """
  Orchestrates async tag extraction for a resource and sends results to the LiveView process.
  Usage: MethodKnow.Tagging.start_tag_extraction(resource, liveview_pid)
  """
  def start_tag_extraction(resource, liveview_pid) do
    Task.start(fn ->
      tags = extract_tags(Map.get(resource, :description) || "")
      send(liveview_pid, {:tags_generated, tags})
    end)
  end

  @doc """
  Extracts tags (keyphrases) from the given text using the HuggingFace Inference API.
  Returns a list of tags or an empty list on error.
  """
  def extract_tags(text) when is_binary(text) do
    token = Application.get_env(:method_know, __MODULE__)[:hf_api_token]

    if is_nil(token) do
      IO.warn("No HuggingFace API token configured!")
      []
    else
      headers = [
        {"Authorization", "Bearer #{token}"},
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ]

      body = %{inputs: text} |> Jason.encode!()
      opts = [headers: headers, body: body]

      req_mod = Application.get_env(:method_know, :req, Req)

      case req_mod.post(@hf_api_url, opts) do
        {:ok, %{status: 200, body: resp_body}} ->
          parse_tags(resp_body)

        {:ok, %{status: status, body: resp_body}} ->
          IO.warn("HuggingFace API error: status #{status}, body: #{inspect(resp_body)}")
          []

        {:error, reason} ->
          IO.warn("HuggingFace API request failed: #{inspect(reason)}")
          []
      end
    end
  end

  defp parse_tags(body) when is_list(body) do
    body
    |> Enum.sort_by(fn
      %{"score" => score} -> -score
      _ -> 0
    end)
    |> Enum.take(3)
    |> Enum.map(fn
      %{"word" => word} -> word
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_tags(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, list} when is_list(list) -> parse_tags(list)
      _ -> []
    end
  end

  defp parse_tags(_), do: []
end
