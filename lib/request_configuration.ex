defmodule ExCurl.RequestConfiguration do
  @moduledoc false

  @derive {Jason.Encoder, only: [:headers, :url, :method, :body, :flags]}
  defstruct headers: %{}, url: "", method: "", body: "", flags: %{}

  def build(method, url, opts \\ []) do
    %__MODULE__{
      headers: get_headers(opts) |> convert_to_key_value_map(),
      url: url,
      method: method,
      body: Keyword.get(opts, :body, ""),
      flags: %{
        follow_location: Keyword.get(opts, :follow_location, true),
        ssl_verifyhost: Keyword.get(opts, :ssl_verifyhost, true),
        ssl_verifypeer: Keyword.get(opts, :ssl_verifypeer, true),
        return_metrics: Keyword.get(opts, :return_metrics, false),
        verbose: Keyword.get(opts, :verbose, false)
      }
    }
  end

  defp get_headers(opts) do
    opts
    |> Keyword.get(:headers, %{})
    |> add_header_if_not_exists("user-agent", "ex_curl/0.1.0")
  end

  defp add_header_if_not_exists(headers, key, value) do
    case String.downcase(key) in Enum.map(Map.keys(headers), &String.downcase/1) do
      true -> headers
      false -> Map.put(headers, key, value)
    end
  end

  defp convert_to_key_value_map(headers) do
    Enum.map(headers, fn {key, value} -> %{key: key, value: header_value(value)} end)
  end

  defp header_value(value) when is_boolean(value) or is_number(value), do: "#{value}"
  defp header_value(value) when is_list(value), do: Enum.join(value, " ")
  defp header_value(value) when is_binary(value), do: value
end
