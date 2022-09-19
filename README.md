# ExCurl

Elixir bindings for libcurl using Zig's C interoperability.

## Usage

```elixir
ExCurl.get! "https://httpbin.org/get"
# => %ExCurl.Response{status_code: 200, headers: %{"content-type" => "application/json", body: "{...}"}}

# view request metrics
ExCurl.get! "https://httpbin.org/get", return_metrics: true
# => %ExCurl.Response{total_time: 0.2, namelookup_time: 0.01, appconnect_time: 0.05, ...}}

# submit a form
ExCurl.post "https://httpbin.org/post", body: "text=#{URI.encode_www_form("some value")}"
# => {:ok, %ExCurl.Response{status_code: 200, body: "{...}"}}}
```

General usage examples and documentation can be found on the [ExCurl module documentation page]().

### HTTP Clients and Shared Defaults

```elixir
# create clients and global default options
defmodule CustomClient do
  use ExCurl.Client, defaults: [headers: %{"User-Agent" => "custom-user-agent"}]
end

# all requests using CustomClient will use the custom User-Agent header
CustomClient.get("https://httpbin.org/get")
# => {:ok, %ExCurl.Response{status_code: 200, body: ".."}}

defmodule GitHubClient do
  use ExCurl.Client, defaults: [base_url: "https://api.github.com"]

  def user_repos(username), do: get("/users/#{username}/repos")
end

# we can now call the GitHubClient with the pre-defined HTTP verb functions:
GitHubClient.get("/users/danielrudn/repos")
# => {:ok, %ExCurl.Response{status_code: 200, body: "{....}"}}

# or call our custom defined functions:
GitHubClient.user_repos("danielrudn")
# => {:ok, %ExCurl.Response{status_code: 200, body: "{....}"}}
```

More examples and details on creating clients is available on the [ExCurl.Client module documentation page]().

## Installation

The package can be installed by adding `ex_curl` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_curl, "~> 0.1.0"},
  ]
end
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_curl>.

## Prior art and Acknowledgements

- libcurl
- zigler
- katipo

