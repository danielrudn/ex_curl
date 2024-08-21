defmodule ExCurl.ResponseMetrics do
  @moduledoc """
  Request timing metrics.

  ## Available Fields

  The following metrics are returned when the `return_metrics` option is set to `true`:

    * `total_time` - corresponds to the [CURLINFO_TOTAL_TIME_T option](https://curl.se/libcurl/c/CURLINFO_TOTAL_TIME_T.html).
    * `namelookup_time` - corresponds to the [CURLINFO_NAMELOOKUP_TIME_T option](https://curl.se/libcurl/c/CURLINFO_NAMELOOKUP_TIME_T.html).
    * `connect_time` - corresponds to the [CURLINFO_CONNECT_TIME_T option](https://curl.se/libcurl/c/CURLINFO_CONNECT_TIME_T.html).
    * `appconnect_time` - corresponds to the [CURLINFO_APPCONNECT_TIME_T option](https://curl.se/libcurl/c/CURLINFO_APPCONNECT_TIME_T.html).
    * `pretransfer_time` - corresponds to the [CURLINFO_PRETRANSFER_TIME_T option](https://curl.se/libcurl/c/CURLINFO_PRETRANSFER_TIME_T.html).
    * `starttransfer_time` - corresponds to the [CURLINFO_STARTTRANSFER_TIME_T option](https://curl.se/libcurl/c/CURLINFO_STARTTRANSFER_TIME_T.html).

  """
  defstruct total_time: 0,
            namelookup_time: 0,
            connect_time: 0,
            appconnect_time: 0,
            pretransfer_time: 0,
            starttransfer_time: 0

  @type t :: %__MODULE__{
          total_time: float(),
          namelookup_time: float(),
          connect_time: float(),
          appconnect_time: float(),
          pretransfer_time: float(),
          starttransfer_time: float()
        }
end
