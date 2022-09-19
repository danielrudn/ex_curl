defmodule ExCurlTest do
  use ExUnit.Case, async: true
  doctest ExCurl

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "can send a GET request", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can send a POST request", %{bypass: bypass} do
    Bypass.expect(bypass, "POST", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.post("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can send a PATCH request", %{bypass: bypass} do
    Bypass.expect(bypass, "PATCH", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.patch("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "can receive headers as a map", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("ex-curl-test", "true")
      |> Plug.Conn.send_resp(200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
    assert resp.headers["ex-curl-test"] == "true"
  end

  test "includes timing metrics when option is set", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test", return_metrics: true)

    assert resp.metrics_returned
    assert resp.total_time != 0
    assert resp.namelookup_time != 0
    assert resp.connect_time != 0
    # appconnect is 0 when not using SSL
    assert resp.appconnect_time == 0
    assert resp.pretransfer_time != 0
    assert resp.starttransfer_time != 0
  end

  test "follows redirects by default", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("Location", "/test2")
      |> Plug.Conn.send_resp(301, "REDIRECT")
    end)

    Bypass.expect(bypass, "GET", "/test2", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "does not follow redirects when option is disabled", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      conn
      |> Plug.Conn.put_resp_header("Location", "/test2")
      |> Plug.Conn.send_resp(301, "REDIRECT")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("http://localhost:#{bypass.port}/test", follow_location: false)

    assert resp.status_code == 301
    assert resp.body == "REDIRECT"
  end

  test "error on malformatted url" do
    assert {:error, "URL_MALFORMAT"} == ExCurl.TestClient.get("http://\n\n.com")
  end

  test "error on unsupported protocol" do
    assert {:error, "UNSUPPORTED_PROTOCOL"} == ExCurl.TestClient.get("grpc://openstatus.co")
  end

  test "error on expired SSL cert" do
    assert {:error, "PEER_FAILED_VERIFICATION"} ==
             ExCurl.TestClient.get("https://expired.badssl.com")
  end

  test "can disable ssl peer validation" do
    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("https://expired.badssl.com", ssl_verifypeer: false)

    assert resp.status_code == 200
  end

  test "error on wrong SSL host" do
    {:error, "PEER_FAILED_VERIFICATION"} =
      ExCurl.TestClient.get("https://wrong.host.badssl.com", ssl_verifypeer: false)
  end

  test "can disable ssl host validation" do
    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.get("https://wrong.host.badssl.com", ssl_verifyhost: false)

    assert resp.status_code == 200
  end

  test "request/3 returns {:ok, %ExCurl.Response{}} on success", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    {:ok, %ExCurl.Response{} = resp} =
      ExCurl.TestClient.request("GET", "http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "request/3 returns {:error, message} om error" do
    assert {:error, "URL_MALFORMAT"} == ExCurl.TestClient.request("GET", "https://")
  end

  test "request!/3 returns %ExCurl.Response{} on success", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/test", fn conn ->
      Plug.Conn.send_resp(conn, 200, "OK")
    end)

    %ExCurl.Response{} =
      resp = ExCurl.TestClient.request!("GET", "http://localhost:#{bypass.port}/test")

    assert resp.status_code == 200
    assert resp.body == "OK"
  end

  test "request!/3 raises one error" do
    assert_raise ExCurl.CurlError, ~r/CURLE_URL_MALFORMAT/, fn ->
      ExCurl.TestClient.request!("GET", "https://")
    end
  end
end
