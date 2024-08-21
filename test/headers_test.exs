defmodule ExCurl.HeadersTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "can send headers", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["true"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test",
        headers: %{"test-header" => "true"}
      )

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "sends default User-Agent header", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "user-agent") do
        ["ex_curl/" <> _rest] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    resp = ExCurl.TestClient.get!("http://localhost:#{bypass.port}/test")
    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can override default headers", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "user-agent") do
        ["test-user-agent"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.post("http://localhost:#{bypass.port}/test",
        headers: %{"user-agent" => "test-user-agent"}
      )

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can accept boolean header values", %{bypass: bypass} do
    Bypass.expect(bypass, "PUT", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["true"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.put("http://localhost:#{bypass.port}/test",
        headers: %{"test-header" => true}
      )

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can accept numeric header values", %{bypass: bypass} do
    Bypass.expect(bypass, "PATCH", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["5"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.patch("http://localhost:#{bypass.port}/test",
        headers: %{"test-header" => 5}
      )

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can accept list header values", %{bypass: bypass} do
    Bypass.expect(bypass, "DELETE", "/test", fn conn ->
      case Plug.Conn.get_req_header(conn, "test-header") do
        ["one two 3"] -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing header")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.delete("http://localhost:#{bypass.port}/test",
        headers: %{"test-header" => ["one", "two", 3]}
      )

    assert resp.status_code == 200
    assert resp.body == "OK"
  end
end
