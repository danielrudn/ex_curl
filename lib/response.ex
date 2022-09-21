defmodule ExCurl.Response do
  @moduledoc """
  A valid response returned by ExCurl.

  ## Metrics

  When the `metrics_returned` field is set to `true`, the following metrics will be included:

    * `total_time` - corresponds to the [CURLINFO_TOTAL_TIME_T option](https://curl.se/libcurl/c/CURLINFO_TOTAL_TIME_T.html).
    * `namelookup_time` - corresponds to the [CURLINFO_NAMELOOKUP_TIME_T option](https://curl.se/libcurl/c/CURLINFO_NAMELOOKUP_TIME_T.html).
    * `connect_time` - corresponds to the [CURLINFO_CONNECT_TIME_T option](https://curl.se/libcurl/c/CURLINFO_CONNECT_TIME_T.html).
    * `appconnect_time` - corresponds to the [CURLINFO_APPCONNECT_TIME_T option](https://curl.se/libcurl/c/CURLINFO_APPCONNECT_TIME_T.html).
    * `pretransfer_time` - corresponds to the [CURLINFO_PRETRANSFER_TIME_T option](https://curl.se/libcurl/c/CURLINFO_PRETRANSFER_TIME_T.html).
    * `starttransfer_time` - corresponds to the [CURLINFO_STARTTRANSFER_TIME_T option](https://curl.se/libcurl/c/CURLINFO_STARTTRANSFER_TIME_T.html).

  """
  defstruct body: "",
            headers: %{},
            status_code: 200,
            total_time: 0,
            namelookup_time: 0,
            connect_time: 0,
            appconnect_time: 0,
            pretransfer_time: 0,
            starttransfer_time: 0,
            metrics_returned: false

  @type t :: %__MODULE__{
          body: nil | String.t(),
          headers: map(),
          status_code: integer(),
          total_time: float(),
          namelookup_time: float(),
          connect_time: float(),
          appconnect_time: float(),
          pretransfer_time: float(),
          starttransfer_time: float(),
          metrics_returned: bool()
        }

  @doc false
  def from_keyword_list_response(list) do
    response = struct(__MODULE__, list)

    %__MODULE__{
      response
      | headers: header_string_to_map(response.headers)
    }
  end

  defp header_string_to_map(headers) do
    headers
    |> String.split("\r\n")
    |> Stream.filter(&String.contains?(&1, ":"))
    |> Stream.map(&String.split(&1, ": "))
    |> Stream.map(fn [head | rest] -> [head, Enum.join(rest, ": ")] end)
    |> Stream.map(fn [key, value] -> {key, value} end)
    |> Enum.into(%{})
  end
end
