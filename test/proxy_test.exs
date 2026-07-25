defmodule ExCurl.ProxyTest do
  use ExUnit.Case, async: true

  test "can use proxy option" do
    bypass = Bypass.open()
    proxy_url = "localhost:#{bypass.port}"

    Bypass.expect_once(bypass, "GET", "/get", fn conn ->
      assert conn.host == "httpbin.org"
      Plug.Conn.send_resp(conn, 200, "OK from proxy")
    end)

    {:ok, resp} = ExCurl.TestClient.get("http://httpbin.org/get", proxy: proxy_url)

    assert resp.status_code == 200
    assert resp.body == "OK from proxy"
  end

  test "fails when proxy is not running or reachable" do
    assert {:error, "COULDNT_RESOLVE_PROXY"} =
             ExCurl.TestClient.get("https://httpbin.org/get", proxy: "nonexistent-host")
  end
end
