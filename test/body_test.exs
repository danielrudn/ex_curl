defmodule ExCurl.BodyTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "can send request body", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/test", fn conn ->
      case Plug.Conn.read_body(conn) do
        {:ok, "testing=true", conn} -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing body")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.post("http://localhost:#{bypass.port}/test", body: "testing=true")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "does not send request body for GET requests", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      case Plug.Conn.read_body(conn) do
        {:ok, "testing=true", conn} -> Plug.Conn.send_resp(conn, 200, "OK")
        _ -> Plug.Conn.send_resp(conn, 400, "Missing body")
      end
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test", body: "testing=true")

    assert resp.status_code == 400
    assert resp.body == "Missing body"
  end
end
