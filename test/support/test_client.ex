defmodule ExCurl.TestClient do
  @moduledoc """
  Tests sometimes hang when trying to make a request with ExCurl
  unless we use dirty_cpu: true. There is a race condition when listening for connections
  and making requests to lcoalhost simulataneously.
  """
  use ExCurl.Client, defaults: [dirty_cpu: true]
end
