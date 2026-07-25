defmodule ExCurl do
  @moduledoc """
  Documentation for `ExCurl`.

  ## Shared options

    * `:headers` - a map of headers to include in the request, defaults to `%{"user-agent" => "ex_curl/0.3.0"}`
    * `:body` - a string to send as the request body, defaults to `""`
    * `:follow_location` - if redirects should be followed, defaults to `true`
    * `:ssl_verifyhost` - if SSL certificates should be verified, defaults to `true`
    * `:ssl_verifypeer` - if SSL certificates should be verified, defaults to `true`
    * `:return_metrics` - if request timing metrics should be included in the returned results, defaults to `false`
    * `:verbose` - if curl should output verbose logs to stdout, useful for debugging. Defaults to `false`
    * `:http_auth_negotiate` - if curl should use HTTP Negotiation (SPNEGO) as defined in [RFC 4559](https://datatracker.ietf.org/doc/html/rfc4559).
      Note: this flag requires curl to be compiled with a suitable GSS-API or SSPI library. Defaults to `false`
    * `:proxy` - proxy to use for transfers. Can be hostname or IP address with optional port number. Supports various proxy types (http, https, socks4, socks5). Defaults to `nil`

  ## Error messages

  Error messages refer to error codes on the [libcurl error codes documentation page](https://curl.se/libcurl/c/libcurl-errors.html).

  For example, when we try to send a request to an invalid url:


        iex> ExCurl.get("https://")
        {:error, "URL_MALFORMAT"}

  The returned error tuple includes the error message `"URL_MALFORMAT"`. This corresponds to the `CURLE_URL_MALFORMAT` (error code 3) error listed
  in the [libcurl error codes documentation](https://curl.se/libcurl/c/libcurl-errors.html).
  """

  alias ExCurl.{CurlErrorCodes, Request, RequestConfiguration, Response}

  @doc """
  Sends a GET request to the given `url`. Similar to `get/2` but raises `ExCurl.CurlError` if the request fails.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  ## Examples
      
      iex> %ExCurl.Response{status_code: status_code} = ExCurl.get!("https://google.com")
      iex> status_code
      200
  """
  def get!(url, opts \\ []), do: request!("GET", url, opts)

  @doc """
  Sends a POST request to the given `url`. Similar to `post/2` but raises `ExCurl.CurlError` if the request fails.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  ## Examples
      
      iex> ExCurl.post!("https://httpbin.org/post", body: "some-value=true")
  """
  def post!(url, opts \\ []), do: request!("POST", url, opts)

  @doc """
  Sends a PUT request to the given `url`. Similar to `put/2` but raises `ExCurl.CurlError` if the request fails.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  ## Examples
      
      iex> ExCurl.put!("https://httpbin.org/put", headers: %{"content-type" => "application/json"}, body: "{}")
  """
  def put!(url, opts \\ []), do: request!("PUT", url, opts)

  @doc """
  Sends a PATCH request to the given `url`. Similar to `patch/2` but raises `ExCurl.CurlError` if the request fails.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  ## Examples
      
      iex> ExCurl.patch!("https://httpbin.org/patch", body: Jason.encode!(%{"some-value" => true}), headers: %{"content-type" => "application/json"})
  """
  def patch!(url, opts \\ []), do: request!("PATCH", url, opts)

  @doc """
  Sends a DELETE request to the given `url`. Similar to `delete/2` but raises `ExCurl.CurlError` if the request fails.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  ## Examples
      
      iex> ExCurl.delete!("https://httpbin.org/delete")
  """
  def delete!(url, opts \\ []), do: request!("DELETE", url, opts)

  @doc """
  Sends a GET request to the given `url`.

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples
     
       iex> {:ok, %ExCurl.Response{status_code: status_code}} = ExCurl.get("https://google.com", follow_location: false)
       iex> status_code
       301
  """
  def get(url, opts \\ []), do: request("GET", url, opts)

  @doc """
  Sends a POST request to the given `url`.

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples
     
       iex> {:ok, %ExCurl.Response{body: body}} = ExCurl.post("https://httpbin.org/post", body: "some-value=true")
       iex> Jason.decode!(body)["form"]
       %{"some-value" => "true"}
  """
  def post(url, opts \\ []), do: request("POST", url, opts)

  @doc """
  Sends a PUT request to the given `url`.

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples


       iex> ExCurl.put("https://httpbin.org/put", body: "some-value=true")

  """
  def put(url, opts \\ []), do: request("PUT", url, opts)

  @doc """
  Sends a PATCH request to the given `url`.

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples


      iex> ExCurl.patch("https://httpbin.org/patch", headers: %{"user-agent" => "custom-user-agent"})
  """
  def patch(url, opts \\ []), do: request("PATCH", url, opts)

  @doc """
  Sends a DELETE request to the given `url`.

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples


      iex> ExCurl.delete("https://httpbin.org/delete", headers: %{"Authorization" => "bearer secret"})
  """
  def delete(url, opts \\ []), do: request("DELETE", url, opts)

  @doc """
  Send a request to the `url` using the provided `method` and options

  Returns either `{:ok, %ExCurl.Response{}}` or `{:error, "CURL_ERROR_MESSAGE"}`.

  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.

  See the ["Error messages"](#module-error-messages) section for details on error messages.

  ## Examples


      iex> ExCurl.request("GET", "https://google.com")
  """
  def request(method, url, opts \\ []) do
    RequestConfiguration.build(method, url, opts)
    |> do_request(opts)
    |> case do
      {:ok, resp} ->
        {:ok, Response.parse(resp)}

      {:error, error_code} ->
        {:error, CurlErrorCodes.get_message(error_code)}
    end
  end

  @doc """
  Sends a request to the given `url` using the provided `method` and options. Similar to `request/3` but raises `ExCurl.CurlError` if the request fails.


  See the ["Shared options"](#module-shared-options) section at the module documentation for available options and their defaults.
  """
  def request!(method, url, opts \\ []) do
    case request(method, url, opts) do
      {:ok, %Response{} = res} ->
        res

      {:error, error_message} when is_binary(error_message) ->
        raise ExCurl.CurlError,
          message: """
          CURL Error: CURLE_#{error_message} (#{CurlErrorCodes.get_code(error_message)})

          For more details, search for 'CURLE_#{error_message}' on https://curl.se/libcurl/c/libcurl-errors.html
          """
    end
  end

  defp do_request(%RequestConfiguration{} = config, opts) do
    case Keyword.get(opts, :dirty_cpu, false) do
      true -> Request.request_dirty_cpu(config)
      _ -> Request.request(config)
    end
  end
end
