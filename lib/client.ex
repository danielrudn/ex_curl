defmodule ExCurl.Client do
  @moduledoc """
  A helper to create HTTP Clients based on ExCurl that can share common options.

  ## Example HTTP Client

  You can `use ExCurl.Client` on any module to provide HTTP Client functionality and share default options. Below is an example based on the great 
  [Tesla documentation](https://hexdocs.pm/tesla/readme.html):

  ```elixir
  defmodule GitHubClient do
    use ExCurl.Client, defaults: [base_url: "https://api.github.com", headers: %{"Authorization" => "Bearer some-secret-token"}]

    def user_repos(username), do: get("/users/\#{username}/repos")
  end
  ```

  We can then use this client with the shared defaults and custom functions:

  ```elixir
  # A custom GET request using our default base_url and headers
  GitHubClient.get("/users/danielrudn")

  # Our custom function, requiring only a username
  GitHubClient.user_repos("danielrudn")
  ```

  ## Response Handling

  You may define an optional `handle_response/1` callback to transform a response after a successful request.
  A common example would be parsing a JSON string into a map. Below we have the same `GitHub` client as above
  but we also parse the JSON response if possible using the `handle_response/1` callback:

  ```elixir
  defmodule GitHubClient do
    use ExCurl.Client, defaults: [base_url: "https://api.github.com", headers: %{"Authorization" => "Bearer some-secret-token"}]

    def handle_response(%ExCurl.Response{body: body}) do
      case Jason.decode(body) do
        {:ok, decoded_body} -> decoded_body
        _ -> body
      end
    end

    def user_repos(username), do: get("/users/\#{username}/repos")
  end
  ```

  ## Options
  All of the [Shared Options](https://hexdocs.pm/ex_curl/ExCurl.html#module-shared-options) from ExCurl are available. There are also the following additional options:

  * `base_url` - The base URL used for all requests by this client module
  """

  @doc """
  See [Response Handling](#module-response-handling) for usage and examples.
  """
  @callback handle_response(response :: %ExCurl.Response{}) :: any()
  @optional_callbacks handle_response: 1

  defmacro __using__(client_opts \\ []) do
    quote do
      def get!(url, opts \\ []), do: request!("GET", url, opts)
      def post!(url, opts \\ []), do: request!("POST", url, opts)
      def put!(url, opts \\ []), do: request!("PUT", url, opts)
      def patch!(url, opts \\ []), do: request!("PATCH", url, opts)
      def delete!(url, opts \\ []), do: request!("DELETE", url, opts)
      def get(url, opts \\ []), do: request("GET", url, opts)
      def post(url, opts \\ []), do: request("POST", url, opts)
      def put(url, opts \\ []), do: request("PUT", url, opts)
      def patch(url, opts \\ []), do: request("PATCH", url, opts)
      def delete(url, opts \\ []), do: request("DELETE", url, opts)

      def request(method, url, opts \\ []) do
        merged_opts = Keyword.merge(default_opts(), opts)

        with {:ok, %ExCurl.Response{} = resp} <-
               ExCurl.request(method, request_url(url, merged_opts), merged_opts) do
          if function_exported?(__MODULE__, :handle_response, 1) do
            {:ok, apply(__MODULE__, :handle_response, [resp])}
          else
            {:ok, resp}
          end
        end
      end

      def request!(method, url, opts \\ []) do
        merged_opts = Keyword.merge(default_opts(), opts)
        response = ExCurl.request!(method, request_url(url, merged_opts), merged_opts)

        if function_exported?(__MODULE__, :handle_response, 1) do
          apply(__MODULE__, :handle_response, [response])
        else
          response
        end
      end

      defp request_url(url_or_path, opts) do
        case Keyword.get(opts, :base_url, nil) do
          base_url when is_binary(base_url) -> base_url <> url_or_path
          _ -> url_or_path
        end
      end

      defp default_opts do
        case Keyword.get(unquote(client_opts), :defaults, []) do
          opts_list when is_list(opts_list) -> opts_list
          opts_atom when is_atom(opts_atom) -> apply(__MODULE__, opts_atom, [])
          opts_func when is_function(opts_func, 0) -> opts_func.()
        end
      end
    end
  end
end
