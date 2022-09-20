defmodule ExCurl.TestClient do
  @moduledoc """
  There is a race condition when listening for connections
  and making requests to localhost simulataneously. Setting `dirty_cpu` to `true`
  will remove the race condition.
  """
  use ExCurl.Client, defaults: [dirty_cpu: true]
end
