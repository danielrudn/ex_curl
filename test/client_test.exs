defmodule ExCurl.ClientTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "can send common headers", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["true"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    defmodule HeaderClient do
      use ExCurl.Client, defaults: [headers: %{"test-header" => "true"}, dirty_cpu: true]
    end

    {:ok, %ExCurl.Response{} = resp} = HeaderClient.get("http://localhost:#{bypass.port}/test")
    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can set base_url", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    defmodule BaseURLClient do
      @port bypass.port
      use ExCurl.Client, defaults: [base_url: "http://localhost:#{@port}", dirty_cpu: true]
    end

    {:ok, %ExCurl.Response{} = resp} = BaseURLClient.get("/test")
    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can use a function to set defaults", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["true"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    defmodule FunctionDefaultsClient do
      use ExCurl.Client, defaults: &get_defaults/0

      defp get_defaults, do: [dirty_cpu: true, headers: %{"test-header" => "true"}]
    end

    {:ok, %ExCurl.Response{} = resp} =
      FunctionDefaultsClient.get("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can use an atom to call a function to set defaults", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["true"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    defmodule AtomFunctionDefaultsClient do
      use ExCurl.Client, defaults: :get_defaults

      def get_defaults, do: [dirty_cpu: true, headers: %{"test-header" => "true"}]
    end

    {:ok, %ExCurl.Response{} = resp} =
      AtomFunctionDefaultsClient.get("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can implement handle_response/1 to transform response", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    defmodule HandleResponseClient do
      use ExCurl.Client, defaults: [dirty_cpu: true]

      def handle_response(%ExCurl.Response{status_code: 200, body: "OK"}), do: "HANDLED"
    end

    assert {:ok, "HANDLED"} == HandleResponseClient.get("http://localhost:#{bypass.port}/test")
    assert "HANDLED" == HandleResponseClient.get!("http://localhost:#{bypass.port}/test")
  end
end
